<# 

Storing episodes within podcast info to simplify call:

$f = .\test\invoke_brave_download.ps1 -Podcast $podcasts[#] -Episode 0

& $configuration[1].vlc "$f" --rate 1.5 --play-and-exit

#>


[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ ![string]::IsNullOrEmpty($_.title) -and ![string]::IsNullOrEmpty($_.author) })]
    [pscustomobject] $Podcast,
    [Parameter(Mandatory, Position = 1)]
    [Int16] $Episode
)
begin {
    . $PSScriptRoot\..\src\utilities.ps1
    $brave = 'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe'
    $config = Get-Content -Path (join-path $PSScriptRoot '..' 'config.json') -ErrorAction Stop | ConvertFrom-Json -AsHashtable
    if ([string]::IsNullOrEmpty($config.tls)) {
        throw "Unable to process tag information using TagLibSharp because 'tls' path is empty within 'config.json'"
        exit 1
    }
    <#

    .SYNOPSIS

    Update the provided file tags based on the provided episode and podcast.

    .NOTES

    https://github.com/mono/taglib-sharp

    A setfield property should exist but not found as a member for the audio tags.

    Other problems encountered:

        if ($null -eq $tags.Tag.URL) { $tags.Tag += @{'URL' = $episode.enclosure.url} }
            InvalidOperation: Method invocation failed because [TagLib.NonContainer.Tag] does not contain a method named 'op_Addition'.

        $tags.Tag.Tags += @ {'URL'=$episode.enclosure.url}
            InvalidOperation: 'Tags' is a ReadOnly property.

        $tags.Tag.Tags.'URL'=$episode.enclosure.url         
            InvalidOperation: The property 'URL' cannot be found on this object. Verify that the property exists and can be set.
    
    .PARAMETER File

    Must have the extension 'mp3' or taglibsharp fails creation.

    #>
    function update_file_tags {
        param (
            [Parameter(Mandatory, Position = 0)]
            [pscustomobject] $Podcast,
            [Parameter(Mandatory, Position = 1)]
            [Int16] $Episode,
            [Parameter(Mandatory, Position = 2)]
            [ValidateScript({ (Test-Path -Path $_.FullName -PathType Leaf) -and (($_ | Split-Path -Extension) -eq '.mp3') })]
            [System.IO.FileInfo] $File
        )
        begin {
            $published = get-date -date $Podcast.episodes[$Episode].pubDate
            $year = $published.Year
            $track = get-date -date $published -Format "yyMMdd"
            [void] [Reflection.Assembly]::LoadFrom($config.tls)
            $tags = [TagLib.File]::Create( $File )
        }
        process {
            # track number set to published date year month day
            $tags.Tag.Track = $track
            # Author is not always published within episode but podcast author will.
            if ([string]::IsNullOrEmpty($Podcast.episodes[$Episode].author)) {
                $tags.Tag.Artists = $Podcast.author
            }
            else {
                $tags.Tag.Artists = $Podcast.episodes[$Episode].author
            }
            # comment tag set to episode description or encoding.
            if ([string]::IsNullOrEmpty($tags.Tag.Description)) {
                if (![string]::IsNullOrEmpty($Podcast.episodes[$Episode].description)) {
                    $tags.Tag.Comment = [System.Web.HttpUtility]::HtmlDecode($Podcast.episodes[$Episode].description)
                }
                else {
                    $tags.Tag.Comment = [System.Web.HttpUtility]::HtmlDecode($Podcast.episodes[$Episode].encoded)
                }
            }
            # title of the episode not the podcast
            if ([string]::IsNullOrEmpty($tags.Tag.Title)) {
                $tags.Tag.Title = $Podcast.episodes[$Episode].title
            }
            # episode URL saved in publisher tag
            if ([string]::IsNullOrEmpty($tags.Tag.Publisher)) {
                $tags.Tag.Publisher = $Podcast.episodes[$Episode].enclosure.url
            }
            # album set to podcast title not episode title
            if ([string]::IsNullOrEmpty($tags.Tag.Album)) {
                $tags.Tag.Album = $Podcast.title
            }
            # set to year of published date year
            if ([string]::IsNullOrEmpty($tags.Tag.Year) -or ($tags.Tag.Year -ne $year)) {
                $tags.Tag.Year = $year
            }
            # save
            $tags.Save()
        }
        end {
            # return path to tagged file
            $File
        }
    }
}
process {
    $directory = Join-Path $config.local $(get_valid_system_chars $Podcast.title) -ErrorAction Stop
    $destination = Join-Path $directory "$(get_valid_system_chars $Podcast.episodes[$Episode].title).mp3" -ErrorAction Stop

    # If file already exists locally just store it - no need to re-download
    if (!(Test-Path -Path $destination -PathType Leaf)) {
        # Store browserurl if downloading
        if ([string]::IsNullOrEmpty($Podcast.episodes[$Episode].browserurl)) {
            <#
    
            .SYNOPSIS
    
            Get browser url (tab title) and pipe it back in for use ~ browser strips ads for some podcasts!
    
            .NOTES
    
            Does not remove embedded audio ads. It only stops ad injection from potential redirects.
    
            https://peter.sh/experiments/chromium-command-line-switches/
            --disable-audio-output (disables sound)
            --autoplay-policy=user-gesture-required (disables autoplay BUT has been unreliable - instead disabling autoplay through specific site settings has worked)
                
            #>
            Start-Process -FilePath $brave -ArgumentList "--autoplay-policy=user-gesture-required --new-tab $($Podcast.episodes[$Episode].enclosure.url)";
            # browser tab url is time dependent!
            $urlloading = 'https://Untitled' # observed during load, may change
            $urlformatted = ""
            while ([string]::IsNullOrEmpty($urlformatted) -or $urlformatted -eq $urlloading) {
                Start-Sleep -Seconds 1
                $browserps = Get-Process -Name "*brave*" | Where-Object { $_.MainWindowHandle -gt 0 }
                $browsertab = $browserps | select-Object -Property MainWindowTitle
                $urlformatted = "https://$($browsertab.MainWindowTitle)" -replace ' - Brave', ''
            }
            Write-Debug "Using '$urlformatted' for episode ..."
            $Podcast.episodes[$Episode].Add('browserurl', $urlformatted)
        }
        $time = Get-Date -Format "yyMMddHHmmssfff"
        $download = join-path ([System.IO.Path]::GetTempPath()) "tmp_pwsh_podcast_$($time).mp3"
        Set-Content -Path $download -Value "" | Out-Null
        if (![string]::IsNullOrEmpty($Podcast.episodes[$Episode].browserurl)) {
            Invoke-WebRequest -Uri $Podcast.episodes[$Episode].browserurl -OutFile $download
        }
        else {
            Invoke-WebRequest -Uri $Podcast.episodes[$Episode].enclosure.uri -OutFile $download
        }
        # format with TLS and move
        $tagged = update_file_tags -Podcast $Podcast -Episode $Episode -File $download -ErrorAction Stop
        if (Test-Path -Path $destination -PathType Leaf) {
            Remove-Item -Path $destination -Force | Out-Null
        }
        Move-Item -Path $tagged -Destination $destination | Out-Null
    }
}
end {
    $destination
}
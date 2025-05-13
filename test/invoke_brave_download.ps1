<# 

.SYNOPSIS

Download and update tags for episode provided.

#>


[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ 
            if ([string]::IsNullOrEmpty($_.author)) {
                throw [System.Management.Automation.PropertyNotFoundException] "Author is missing."
            }
            if ([string]::IsNullOrEmpty($_.date)) {
                throw [System.Management.Automation.PropertyNotFoundException] "Episode publication date is missing."
            }
            if ([string]::IsNullOrEmpty($_.description)) {
                throw [System.Management.Automation.PropertyNotFoundException] "Episode description is missing."
            }
            if ([string]::IsNullOrEmpty($_.podcast)) {
                throw [System.Management.Automation.PropertyNotFoundException] "Podcast title is missing."
            }
            if ([string]::IsNullOrEmpty($_.title)) {
                throw [System.Management.Automation.PropertyNotFoundException] "Episode title is missing."
            } 
            if ([string]::IsNullOrEmpty($_.url)) {
                throw [System.Management.Automation.PropertyNotFoundException] "Episode url is missing."
            } 
            $true
        })]
    [pscustomobject] $Episode
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

    Update the provided file tags based on the provided episode details.

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
            [pscustomobject] $Episode,
            [Parameter(Mandatory, Position = 1)]
            [ValidateScript({ (Test-Path -Path $_.FullName -PathType Leaf) -and (($_ | Split-Path -Extension) -eq '.mp3') })]
            [System.IO.FileInfo] $File
        )
        begin {
            $published = get-date -date $Episode.date
            $year = $published.Year
            $track = get-date -date $published -Format "yyMMdd"
            [void] [Reflection.Assembly]::LoadFrom($config.tls)
            $tags = [TagLib.File]::Create( $File )
        }
        process {
            $tags.Tag.Album = $Episode.podcast
            
            $tags.Tag.Artists = $Episode.author
            
            $tags.Tag.Comment = $Episode.description
            
            $tags.Tag.Publisher = $Episode.url
            
            $tags.Tag.Title = $Episode.title
            
            $tags.Tag.Track = $track
            
            $tags.Tag.Year = $year
            
            $tags.Save()
        }
        end {
            # return path to tagged file
            $File
        }
    }
}
process {
    $directory = Join-Path $config.local $(get_valid_system_chars $Episode.podcast) -ErrorAction Stop
    $destination = Join-Path $directory "$(get_valid_system_chars $Episode.title).mp3" -ErrorAction Stop

    # If file already exists locally just store it - no need to re-download
    if (!(Test-Path -Path $destination -PathType Leaf)) {
        # Store browserurl if downloading
        if ([string]::IsNullOrEmpty($Episode.browserurl)) {
            <#
    
            .SYNOPSIS
    
            Get browser url (tab title) and pipe it back in for use ~ browser strips ads for some podcasts!
    
            .NOTES
    
            Does not remove embedded audio ads. It only stops ad injection from potential redirects.
    
            https://peter.sh/experiments/chromium-command-line-switches/
            --disable-audio-output (disables sound)
            --autoplay-policy=user-gesture-required (disables autoplay BUT has been unreliable - instead disabling autoplay through specific site settings has worked)
                
            #>
            Start-Process -FilePath $brave -ArgumentList "--autoplay-policy=user-gesture-required --new-tab $($Episode.url)";
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
            $Episode | Add-Member -MemberType NoteProperty -Name 'browserurl' -value $urlformatted
        }
        $time = Get-Date -Format "yyMMddHHmmssfff"
        $download = join-path ([System.IO.Path]::GetTempPath()) "tmp_pwsh_podcast_$($time).mp3"
        Set-Content -Path $download -Value "" | Out-Null
        if (![string]::IsNullOrEmpty($Episode.browserurl)) {
            Invoke-WebRequest -Uri $Episode.browserurl -OutFile $download
        }
        else {
            Invoke-WebRequest -Uri $Episode.url -OutFile $download
        }
        # format with TLS and move
        $tagged = update_file_tags -Episode $Episode -File $download -ErrorAction Stop
        if (Test-Path -Path $destination -PathType Leaf) {
            Remove-Item -Path $destination -Force | Out-Null
        }
        Move-Item -Path $tagged -Destination $destination | Out-Null
    }
}
end {
    $destination
}
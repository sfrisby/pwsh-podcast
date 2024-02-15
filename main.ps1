$settings_file = 'conf.json'
$settings = $(get-content -Path $settings_file -Raw | ConvertFrom-Json)

. .\utils.ps1

function Get-PodcastEpisodes {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$URI
    )
    $table = @()
    $feed = Invoke-WebRequest -Uri $URI
    $xml = [XML] $feed.Content
    if ($null -ne $xml.rss.channel.author && $null -ne $xml.rss.channel.item) {
        try {
            # TODO resolve '#text' as a key for many items (via ConvertFrom-XML); duplicate key for identical entries as well.
            $xml.rss.channel.item | ForEach-Object { # order preserved
                $table += $($_ | ConvertFrom-XML)
            }
        }
        catch {
            Write-Host $_.ScriptStackTrace
            throw "Failed to convert from XML."
        }
    }
    else {
        Throw "Unexpected XML format."
    }
    $table
}

function SanitizeString() {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$ToSanitize
    )
    [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object { 
        $tmp = $ToSanitize.replace("$_", "")
        if ($tmp.Length -lt $ToSanitize.Length) {
            Write-Host "Invalid character '${_}' found; removing ..."
            $ToSanitize = $tmp
        }
    }
    $ToSanitize
}

function Get-PodcastEpisode {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$URI,
        [ValidateScript({ 
                $(Test-Path -Path $_ -PathType Leaf -IsValid) -and 
                $($_.Name -notmatch [System.IO.Path]::GetInvalidFileNameChars()) 
            })]
        [string]$Path = [System.IO.Path]::Combine(
            [System.IO.Path]::GetTempPath(), 
            [System.IO.Path]::GetTempFileName())
    )
    Invoke-WebRequest -Uri $URI -OutFile $Path
}

function Format-Episodes {
    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [array] $Episodes
    )
    # Duplicates coming from XML conversion, silly XML object nonsense.
    # Attempting to elliminate title duplicates to prevent padding issues.
    $Episodes | ForEach-Object {
        if ($_.title.Count -eq 1 -and $_.title.Keys -notcontains '#text') {
            # Desired and expected - just continue
        }
        elseif ($_.title.Keys -contains '#text' -and $_.title.Keys.Count -gt 1) {
            $tmp = $_.title[0].'#text'
            $_.title = $tmp
        }
        elseif ($_.title.Keys -contains '#text') {
            $tmp = $_.title.'#text'
            $_.title = $tmp
        }
        elseif ($_.title.Count -ne 1 -and $_.title.GetType() -ne [string]) {
            throw "Unexpected episode title Key was found."
        }
    }
    $Episodes
}

# Wrtining console output for episodes, specifically: index | episode-title | publication date
function Write-Host-Episodes() {
    param(
        # Array containing hashtables of episode entries.
        [Parameter(Mandatory = $true)]
        [array] $Episodes,
        # Additional spacing for episode information.
        [int] $episodeExtraPadding = 3,
        # Provide the number of episodes to list;. Default is 10. Providing 0 will show all episodes.
        [int] $episodesListedAmount = 10
    )
    if ($episodesListedAmount -eq 0) {
        $episodesListedAmount = $Episodes.Count
    }
    $eTitlePadding = $($($Episodes.title | Select-Object -First $episodesListedAmount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $episodeExtraPadding
    $ePubDatePadding = $($($Episodes.pubDate | Select-Object -First $episodesListedAmount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $episodeExtraPadding
    $indexPadding = $Episodes.Count.ToString().Length
    $Episodes | Select-Object -First $episodesListedAmount | ForEach-Object {
        $($Episodes.indexof($_)).tostring().padleft($indexPadding) + 
        " | " + $($_.title).padleft($eTitlePadding) +
        " | " + $($_.pubDate.Values).padleft($ePubDatePadding)
    }
}


$feeds = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable)
displayPodcastsFeeds -Podcasts $feeds

$choice = Read-Host "Select # (above) of the podcast to listen to"
$podcast = $feeds[[int]$choice]
$podcastEpisodesTitle = SanitizeString -ToSanitize $podcast.title
$podcastEpisodesFile = "$podcastEpisodesTitle.json"

$episodesLocal = @()
$episodesLatest = @()
$jsonDepth = 10

if ( !( Test-Path -Path "$podcastEpisodesFile" -PathType Leaf ) ) {
    Write-Host "Selected '$($podcast.title)'. Performing first time episode gathering ..."
    $(Format-Episodes -Episodes $(Get-PodcastEpisodes -URI $podcast.url)) | ConvertTo-Json -depth $jsonDepth | Out-File -FilePath $podcastEpisodesFile
    $episodesLocal = [array]$(Get-Content -Path $podcastEpisodesFile | ConvertFrom-Json -AsHashtable)
}
else {
    $episodesLocal = [array]$(Get-Content -Path $podcastEpisodesFile | ConvertFrom-Json -AsHashtable)
    $sWriteTimeDifference = $(Get-Date) - ($(Get-ChildItem -Path $podcastEpisodesFile | Select-Object -Property LastWriteTime).LastWriteTime)
    # if ( $sWriteTimeDifference.Seconds -gt 2 ) {
    if ( $sWriteTimeDifference.Days -gt 1 ) {
        Write-Host "Episodes for '$podcastEpisodesTitle' were last updated: [days:hours:minutes:seconds]"
        Write-Host "$($sWriteTimeDifference.Days) days, "
        write-host "$($sWriteTimeDifference.Hours) hours, "
        write-host "$($sWriteTimeDifference.Minutes) minutes, "
        write-host "$($sWriteTimeDifference.Seconds) seconds"
        write-host "Checking for new '$($podcast.title)' episodes ..."
        $episodesLatest = Format-Episodes -Episodes ($(Get-PodcastEpisodes -URI $podcast.url))
        # $(Format-Episodes -Episodes $(Get-PodcastEpisodes -URI $podcast.url)) 
    }
}

if ( $episodesLatest.Count -gt $episodesLocal.Count ) {
    # Save latest episodes as the new baseline; display newest episodes; error if none were found.
    $episodesLatest | ConvertTo-Json -depth $jsonDepth | Out-File -FilePath $podcastEpisodesFile 
    $newest = @()
    foreach ($e in $episodesLatest) {
        if ( $episodesLocal.title -notcontains $e.title ) {
            $newest += @($e)
        }
    }
    if ( !($newest.Count -eq 0) ) {
        write-host-episodes -episodes $newest
    }
    else {
        throw "New episodes were expected but none were found."
    }
}
else {
    # Display the episodes.
    write-host-episodes -episodes $episodesLocal
}

$choice = Read-Host -prompt "Select episode by number"
try {
    $episode = $episodes[[int]::Parse($choice)]
    Write-Host "Episode selected was: '$($episode.title)'."
}
catch [System.FormatException] {
    throw "A number was not provided. Unable to proceede."
}

$title = SanitizeString -ToSanitize $episode.title
$file = join-path (Get-location) "${title}.mp3"
$url = $episode.enclosure.url
Get-PodcastEpisode -URI $url -Path $file


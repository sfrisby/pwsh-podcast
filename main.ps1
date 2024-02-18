$settings_file = 'conf.json'
$settings = $(get-content -Path $settings_file -Raw | ConvertFrom-Json)

. .\utils.ps1

function Get-Episodes {
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
function Approve-String() {
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

function Update-Episodes() {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Podcast
    )
    $episodesLocal = @()
    $episodesLatest = @()
    $jsonDepth = 10
    $podcastEpisodesTitle = Approve-String -ToSanitize $Podcast.title
    $podcastEpisodesFile = "$podcastEpisodesTitle.json"
    if ( !( Test-Path -Path "$podcastEpisodesFile" -PathType Leaf ) ) {
        Write-Host "Selected '$($Podcast.title)'. Performing first time episode gathering ..."
        $(Format-Episodes -Episodes $(Get-Episodes -URI $Podcast.url)) | ConvertTo-Json -depth $jsonDepth | Out-File -FilePath $podcastEpisodesFile
        $episodesLocal = [array]$(Get-Content -Path $podcastEpisodesFile | ConvertFrom-Json -AsHashtable)
    }
    else {
        $episodesLocal = [array]$(Get-Content -Path $podcastEpisodesFile | ConvertFrom-Json -AsHashtable)
        $writeTimeDiff = $(Get-Date) - ($(Get-ChildItem -Path $podcastEpisodesFile | Select-Object -Property LastWriteTime).LastWriteTime)
        # if ( $writeTimeDiff.Seconds -gt 2 ) {
        if ( $writeTimeDiff.Days -gt 1 ) {
            $timeDiff = "[$($writeTimeDiff.Days):$($writeTimeDiff.Hours):$($writeTimeDiff.Minutes):$($writeTimeDiff.Seconds)]"
            Write-Host "Episodes for '$podcastEpisodesTitle' were last updated: $timeDiff [days:hours:minutes:seconds]"
            write-host "Checking for new '$($Podcast.title)' episodes ..."
            $episodesLatest = Format-Episodes -Episodes ($(Get-Episodes -URI $Podcast.url))
        }
    }
    # Display episodes. Save latest episodes as the new baseline. Display newest episodes.
    if ( $episodesLatest.Count -gt $episodesLocal.Count ) {
        $episodesLatest | ConvertTo-Json -depth $jsonDepth | Out-File -FilePath $podcastEpisodesFile 
        $newest = @()
        foreach ($e in $episodesLatest) {
            if ( $episodesLocal.title -notcontains $e.title ) {
                $newest += @($e)
            }
        }
        if ( !($newest.Count -eq 0) ) {
            return $newest
        }
        else {
            throw "New episodes were expected but none were found."
        }
        return $episodesLatest
    }
    else {
        return $episodesLocal
    }
}

# Writing console output for episodes, specifically: index | episode-title | publication date
function Write-Episodes() {
    param(
        # Array containing hashtables of episode entries.
        [Parameter(Mandatory = $true)]
        [array] $Episodes,
        # Additional spacing for episode information.
        [int] $Padding = 3,
        # Provide the amount of episodes to list;. Default is 10. Providing 0 will show all episodes.
        [int] $Amount = 10
    )
    if ($Amount -eq 0) {
        $Amount = $Episodes.Count
    }
    $eTitlePadding = $($($Episodes.title | Select-Object -First $Amount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $Padding
    $ePubDatePadding = $($($Episodes.pubDate | Select-Object -First $Amount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $Padding
    $indexPadding = $Episodes.Count.ToString().Length
    # foreach ($e in ($Episodes | Select-Object -First $Amount)) {
    #     $($Episodes.indexof($e)).tostring().padleft($indexPadding) + 
    #     " | " + $($e.title).padleft($eTitlePadding) +
    #     " | " + $($e.pubDate.Values).padleft($ePubDatePadding) | Out-Host
    # }
    $Episodes | Select-Object -First $Amount | ForEach-Object {
        $($Episodes.indexof($_)).tostring().padleft($indexPadding) + 
        " | " + $($_.title).padleft($eTitlePadding) +
        " | " + $($_.pubDate.Values).padleft($ePubDatePadding) | Out-Host
    }
}
function Find-Episode() {
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

# Display podcasts from feed file and let user choose.
$feeds = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable)
displayPodcastsFeeds -Podcasts $feeds
$choice = Read-Host "Select # (above) of the podcast to listen to"
$podcast = $feeds[[int]$choice]

# Display the episodes and let user choose.
$episodes = Update-Episodes -Podcast $podcast
Write-Episodes -Episodes $episodes
$choice = Read-Host -prompt "Select episode by # (above)"
$episode = @()
try {
    $episode = $episodes[[int]::Parse($choice)]
    Write-Host "Episode selected was: '$($episode.title)'."
}
catch [System.FormatException] {
    throw "A number was not provided. Unable to proceede."
}

# Download the episode if found.
$title = Approve-String -ToSanitize $episode.title
$file = join-path (Get-location) "${title}.mp3"
$url = $episode.enclosure.url
Find-Episode -URI $url -Path $file


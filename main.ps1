<#
.SYNOPSIS
CLI for podcasts.
.PARAMETER $ToStream
Stream using VLC when true.
.PARAMETER 
#>

param(
    [parameter(Mandatory = $false)]
    [bool] $ToStream = $false,
    [parameter(Mandatory = $false)]
    [Single] $Rate = 1.5
)

. '.\include.ps1'

# Display podcasts from feed file and let user choose.
$feeds = [array]$(Get-Content -Path $script:FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable)
displayPodcastsFeeds -Podcasts $feeds
$choice = Read-Host "Select # (above) of the podcast to listen to"
$podcast = $feeds[[int]$choice]

# Display the episodes and let user choose.
$e = $script:episodes."$($podcast.title)"

$check = CompareEpisodes -Podcast $podcast -Episodes $e
if ($check -ne 0) {
    $e = $check
}

Write-HostEpisodesList -Episodes $e
$choice = Read-Host -prompt "Select episode by # (above)"
$selected = @()
try {
    $selected = $e[[int]::Parse($choice)]
    Write-Host "Episode selected was: '$($selected.title)'."
}
catch [System.FormatException] {
    throw "A number was not provided. Unable to proceede."
}

# Streaming does not always work. Unable to identify VLC error. For now the default is download then stream.
# TODO allow options: --qt-start-minimized --play-and-exit
if ($ToStream) {
    & "C:\Program Files\VideoLAN\VLC\vlc.exe" --play-and-exit --rate=$Rate $($selected.enclosure.url)
}
else {
    # Download the episode if not already found.
    $title = Approve-String -ToSanitize $selected.title
    $file = join-path (Get-location) "${title}.mp3"
    if ( !(Test-Path -PathType Leaf -Path $file) ) {
        $url = $selected.enclosure.url
        Invoke-EpisodeDownload -URI $url -Path $file
    }
    # Updating Tag Information
    .\test\UpdateTags\UpdateTags.ps1 $selected $file
    # Now play in VLC
    & "C:\Program Files\VideoLAN\VLC\vlc.exe" --play-and-exit --rate=$Rate $file
}

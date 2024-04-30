. "$PSScriptRoot\private\setup.ps1"

<#
.SYNOPSIS
Getter functions for various path information.
#>
function Get-VlcPath {
    $VLC_PATH
}
function Get-IconPath {
    $ICON_PATH
}
function Get-DownloadsFolderPath {
    $DOWNLOADS_FOLDER
}
function Get-ResourceFolderPath {
    $RESOURCE_FOLDER
}
function Get-EpisodeFolderPath {
    $EPISODES_FOLDER
}
function Get-ThumbnailFolderPath {
    $THUMBNAIL_FOLDER
}
function Get-RssFilePath {
    $PODCAST_RSS_FILE
}
function Get-EpisodesFilePath {
    $EPISODES_FILE
}

. "$PSScriptRoot\private\utility.ps1"
. "$PSScriptRoot\public\PwShPodcasts.ps1"

Export-ModuleMember -Function Get-VlcPath, Get-IconPath, Get-DownloadsFolderPath, Get-ResourceFolderPath, Get-EpisodeFolderPath, Get-ThumbnailFolderPath, `
    Get-RssFilePath, Get-EpisodesFilePath, `
    Format-PodcastsTasks, `
    Get-Podcasts, Add-Podcast, Remove-Podcast, Search-Podcasts, Show-Podcasts, `
    Get-EpisodeDownloadFileName, Get-PodcastThumbnailFileName, `
    Compare-Episodes, Get-EpisodesFromFile, Get-EpisodesWithinDate, Get-EpisodesLocal, Get-EpisodesOnline, Save-Episodes, `
    Invoke-Download, Invoke-VlcStream, Invoke-Vlc, `
    Approve-String

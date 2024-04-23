. "$PSScriptRoot\private\setup.ps1"

<#
.SYNOPSIS
Getter for podcast RSS file path.
#>
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

. "$PSScriptRoot\private\utility.ps1"
. "$PSScriptRoot\public\PwShPodcasts.ps1"

Export-ModuleMember -Function Get-DownloadsFolderPath, Get-ResourceFolderPath, Get-EpisodeFolderPath, Get-ThumbnailFolderPath, Get-RssFilePath, `
    Get-NewAndAllSetForEpisodes, `
    Get-Podcasts, Add-Podcast, Remove-Podcast, Select-Podcast, Select-Episode, Show-Podcasts, Get-EpisodesLocal, Get-EpisodesOnline, Save-Episodes, `
    Invoke-VlcStream

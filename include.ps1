<#
.SYNOPSIS
Aggregation of all setup information.
.DESCRIPTION
Relies on 'Config.ini' for proper setup, thus, setup script should be performed at least once prior to execution.

Removes ALL jobs prior to performing paralleled episode gathering for all podcasts.
.NOTES
Change with caution!

https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/wait-job?view=powershell-7.4#notes

By default, Wait-Job returns, or ends the wait, when jobs are in one of the following states:
    Completed
    Failed
    Stopped
    Suspended
    Disconnected

To direct Wait-Job to continue to wait for Suspended and Disconnected jobs, use the Force parameter.
#>

Add-Type -assembly System.Windows.Forms

. ".\test\CompareEpisodes\CompareEpisodes.ps1"
. ".\test\ConvertFrom-PodcastWebRequestContent\ConvertFrom-PodcastWebRequestContent.ps1"
. ".\test\Get-EpisodeFileContent\Get-EpisodeFileContent.ps1"
. ".\test\Get-EpisodesLatest\Get-EpisodesLatest.ps1"
. ".\test\Invoke-PodcastFeed\Invoke-PodcastFeed.ps1"
. '.\utils.ps1'

$CONFIG_FILE_NAME = "config.ini"
$CONFIG_FILE_PATH = ".\$CONFIG_FILE_NAME"
$CONFIG_ISNT_PRESENT = -not (Test-Path -Path $CONFIG_FILE_PATH -PathType Leaf)
if ( $CONFIG_ISNT_PRESENT ) {
    throw "Mising configuration file. Execute the setup script and try again."
}
$setup = Get-Content -Path $CONFIG_FILE_PATH -Raw | ConvertFrom-StringData
$script:FEEDS_FILE = $setup.file_feeds
$script:SEARCH_FILE = $setup.file_search
$script:EPISODE_PREFIX = $setup.prefix_episode_list

$script:episodes = @()
$script:podcasts = @()
$script:podcasts = [array]$(Get-Content -Path $script:FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable);
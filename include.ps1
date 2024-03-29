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
$script:podcasts = [array]$(Get-Content -Path $script:FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable);

# REMOVING ALL JOBS!
Get-Job | Remove-Job

$jobs = @()
foreach ($podcast in $script:podcasts) {
    $initBlock = {
        . ".\test\ConvertFrom-PodcastWebRequestContent\ConvertFrom-PodcastWebRequestContent.ps1"
        . ".\test\Invoke-PodcastFeed\Invoke-PodcastFeed.ps1"
    }
    $execBlock = {
        param (
            [parameter(Mandatory = $true)]
            [string] $URI
        )
        return $(ConvertFrom-PodcastWebRequestContent -Request $(Invoke-PodcastFeed -URI $URI))
    }
    $jobs += $( Start-ThreadJob -InitializationScript $initBlock -ScriptBlock $execBlock -ArgumentList $Podcast.url -Name $podcast.title )
}

# Report progress on jobs. The text size of the activity and status affect drawn percentage. May require massaging if changed.
$activity = "Loading Podcasts "
$jobsTotalCount = $jobs.count
$jobsRunningCount = $(Get-Job | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted'}).Count
$PSStyle.Progress.Style = "$($PSStyle.Background.Blue)"
$PSStyle.Progress.MaxWidth = 40
$PSStyle.Progress.View = 'Minimal'
while ($jobsRunningCount -gt 0) {
    $jobsCompletedCount = $(Get-Job | Where-Object { $_.State -eq 'Completed'}).Count
    $p = [string]::Format("{0:N2}", (1 - $(($jobsTotalCount - $jobsCompletedCount) / $jobsTotalCount)) * 100)
    Write-Progress -Activity $activity -Status "Gathered $p %" -PercentComplete $p
    Start-Sleep -Milliseconds 250
    $jobsRunningCount = $(Get-Job | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted'}).Count
}
Write-Progress -Activity $activity -Completed

foreach ($job in $jobs) {
    $items = @()
    $name = $job.Name
    $items = @( $job | Receive-Job )
    $script:episodes += @( @{ "$name" = $items } )
}

Get-Job | Where-Object { $_.State -eq 'Completed' } | Remove-Job # Removing all 'Completed' jobs.
if ($( Get-Job ).count -gt 0) {
    throw "Not all episode gathering jobs completed as expected!"
}
elseif ($null -eq $script:episodes.Keys -or $script:episodes.Keys.Count -eq 0) {
    throw "Episode keys are missing!"
}

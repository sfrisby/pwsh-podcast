<#
.SYNOPSIS
Return the first amount (default is three) of episodes from all provided podcasts.
#>
function Get-EpisodesLatest {
    param(
        [Parameter(Mandatory=$true)]
        $Podcasts,
        [Parameter(Mandatory=$false)]
        $Amount = 3,
        [Parameter(Mandatory=$false)]
        [System.Windows.Forms.ProgressBar]$Progress
    )
    $episodes = @()
    foreach ($podcast in $Podcasts) {
        $tmp = Update-Episodes -Podcast $podcast | Select-Object -First $Amount
        $episodes += $tmp
        $Progress.PerformStep()
    }
    $episodes
}
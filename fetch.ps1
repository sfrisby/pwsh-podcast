. '.\include.ps1'

$imgJob = @()
$jobs = @()
foreach ($podcast in $script:podcasts) {
    # Episode gathering.
    $initBlock = {
        . ".\test\ConvertFrom-PodcastWebRequestContent\ConvertFrom-PodcastWebRequestContent.ps1"
        . ".\test\Invoke-PodcastFeed\Invoke-PodcastFeed.ps1"
    }
    $execBlock = {
        param (
            [parameter(Mandatory = $true)]
            [ValidateScript({ $null -ne $_ })]
            [string] $URI
        )
        $i = Invoke-PodcastFeed -URI $URI

        $c = ConvertFrom-PodcastWebRequestContent -Request $i

        $c
    }
    $t = $podcast.title
    $u = $podcast.url
    $jobs += $( Start-ThreadJob -InitializationScript $initBlock -Name $t -ScriptBlock $execBlock -ArgumentList $u )
    
    # Thumbnail gathering.
    $imgPath = ".\resource\thumb_$(Approve-String -ToSanitize $podcast.title).jpg"
    if ( -not (Test-Path -Path $imgPath -PathType Leaf)) {
        $imgInit = {
            . ".\utils.ps1"
        }
        $imgBlock = {
            param(
                [parameter(Mandatory = $true)]
                [string] $path,
                [parameter(Mandatory = $true)]
                [string] $url
            )
            $tmp = New-TemporaryFile
            Invoke-Download -URI $url -Path $tmp.FullName
            # Resize the thumbnail, max 250. The save call does not override existing files.
            try {
                $scale = 250
                $thumbnail = [System.Drawing.Image]::FromFile($tmp.FullName)
                if ($thumbnail.Width -gt $scale -or $thumbnail.Height -gt $scale) {
                    $resize = New-Object System.Drawing.Bitmap($scale, $scale)
                    $graphics = [System.Drawing.Graphics]::FromImage($resize)
                    $graphics.DrawImage($thumbnail, 0, 0, $scale, $scale)
                    $resize.Save($path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                    $thumbnail.Dispose()
                    $graphics.Dispose()
                    $resize.Dispose()
                }
            }
            finally {
                if ($thumbnail) { $thumbnail.Dispose() }
                if ($graphics) { $thumbnail.Dispose() }
                if ($resize) { $thumbnail.Dispose() }
            }
        }
        $imgJob += $( Start-ThreadJob -InitializationScript $imgInit -ScriptBlock $imgBlock -ArgumentList @($imgPath, $podcast.image) -Name "image_$($podcast.title)" )
    }
}

# Progress styling
$PSStyle.Progress.Style = "$($PSStyle.Background.Blue)"
$PSStyle.Progress.MaxWidth = 40
$PSStyle.Progress.View = 'Minimal'

<#
Report progress on jobs. 
.NOTES
The text size of the activity and status affect displayed percentage. May require massaging if changed.
#> 
# ---
$activity    = "Loading podcasts "
$jobsTotalCount = $jobs.count
$jobsRunningCount = $($jobs | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count
$jobId = 1
# ---
$imgActivity = "Processing images "
$imgJobsTotalCount = $imgJob.count
$imgJobsRunningCount = $($imgJob | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count
$imgJobId = 2
# ---
while ($jobsRunningCount -gt 0 -or $imgJobsRunningCount -gt 0) {
    $jobsCompletedCount = $($jobs | Where-Object { $_.State -eq 'Completed' }).Count
    $imgJobsCompletedCount = $($imgJob | Where-Object { $_.State -eq 'Completed' }).Count
    $p = [string]::Format("{0:N2}", (1 - $(($jobsTotalCount - $jobsCompletedCount) / $jobsTotalCount)) * 100)
    if (0 -eq $imgJobsTotalCount) {
        $imgP = 100
    } else {
        $imgP = [string]::Format("{0:N2}", (1 - $(($imgJobsTotalCount - $imgJobsCompletedCount) / $imgJobsTotalCount)) * 100)
    }
    Write-Progress -Id $jobId -Activity $activity -Status "Gathered $p %" -PercentComplete $p
    Write-Progress -id $imgJobId -Activity $imgActivity -Status "Gathered $imgP %" -PercentComplete $imgP
    Start-Sleep -Milliseconds 250
    $jobsRunningCount = $($jobs | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count
    $imgJobsRunningCount = $($imgJob | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count
}
Write-Progress -Id $jobId -Activity $activity -Completed
Write-Progress -Id $imgJobId -Activity $imgActivity -Completed

# Cleanup podcast episode jobs after saving data.
foreach ($job in $jobs) {
    $items = @()
    $name = $job.Name
    $items = @( $job | Receive-Job )
    $script:episodes += @( @{ "$name" = $items } )
    $job | Remove-Job
}

# Cleanup podcast thumbnail jobs.
$imgJob | Remove-Job

if ($null -eq $script:episodes.Keys -or $script:episodes.Keys.Count -eq 0) {
    throw "Episode keys are missing!"
}
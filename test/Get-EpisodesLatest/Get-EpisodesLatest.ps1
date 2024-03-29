<#
.SYNOPSIS
Return the first amount (default is three) of episodes from all provided podcasts.
.NOTES
$jobCount = 5 # Set the number of jobs you want to complete before continuing
$jobs = @() # Initialize an empty array to store the jobs

for ($i=0; $i -lt 10; $i++) { # Run the loop 10 times
    $job = Start-Job -ScriptBlock {
        # Your code here
    }
    $jobs += $job

    # Check if the number of completed jobs equals or exceeds the jobCount
    if (($jobs | Where-Object { $_.State -eq 'Completed' }).Count -ge $jobCount) {
        break # Exit the loop
    }
}

# Wait for all jobs to complete
$jobs | Wait-Job

---

$job1 = Start-Job -ScriptBlock { 1..100 | ForEach-Object { "Job1: $_" } }
$job2 = Start-Job -ScriptBlock { 101..200 | ForEach-Object { "Job2: $_" } }

Wait-Job $job1, $job2

Receive-Job $job1
Receive-Job $job2

# TODO run this once at the beginning of the application in the background.

#>
function Get-EpisodesLatest {
    param(
        [Parameter(Mandatory = $true)]
        $Podcasts,
        [Parameter(Mandatory = $false)]
        $Amount = 3,
        [Parameter(Mandatory = $false)]
        [System.Windows.Forms.ProgressBar]$Progress
    )
    $episodes = @()
    $jobs = @()
    foreach ($podcast in $Podcasts) {
        $job = Start-Job -InitializationScript {
            . '.\include.ps1' # .\utils.ps1
        } -ScriptBlock {
            param(
                $Podcast,
                $Count
            )

            # Update-Episodes -Podcast $Podcast | Select-Object -First $Count

            




        } -ArgumentList $podcast, $Amount
        $jobs += $job
        $Progress.PerformStep()
    }

    $jobs | Wait-Job # Perform all jobs before continuing.
    
    # TODO $jobs magically inserted at the front of $episodes even though they are cleared ...
    foreach ($job in $jobs) {
        $found = $($job | Receive-Job)
        foreach ($item in $found) {
            $episodes += $item
        }
        $job | Remove-Job # Removing child job
    }
    
    $jobs = @() # Clear jobs

    return $episodes
}
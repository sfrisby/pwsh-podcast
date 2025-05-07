<#

.SYNOPSIS

Obtain episodes for each podcast in parallel.

.NOTES

In order to have utilities.ps1 within job scope the location is passed as an argument to job.

"By default, the jobs use the current working directory of the caller that started the job."
- https://learn.microsoft.com/en-us/powershell/module/threadjob/start-threadjob

Number of cores may be determined by:

> $cores = Get-CimInstance Win32_Processor | Select-Object -ExpandProperty NumberOfCores

4 jobs per core should be plenty of CPU.

> $throttle = 4 * $cores

.OUTPUTS

Episode hashtables for each podcast provided within an array [object[]].

If a single podcast is provided then a [hashtable] is returned.

#>
[CmdletBinding()]
param (
    [parameter(Mandatory, Position = 0)]
    [ValidateScript({ $_.count -gt 0 -and $null -ne ($_[0] | Get-Member -MemberType Properties) -and $null -ne ($_[$_.count - 1] | Get-Member -MemberType Properties) })]
    [object[]] $Podcasts
)
begin {
    $j = @()
}   
process {
    $f = 0
    $u = Join-Path $PSScriptRoot "utilities.ps1"
    $b = { param($u, $p) 
        . $u
        invoke_podcast_episodes $p
    }
    $Podcasts | ForEach-Object {
        # alternative option would be to create 'foreach-object -parallel' and invoke directly within, but doesn't pass data
        # $j += ( Start-ThreadJob -ScriptBlock $b -ArgumentList ($u, $_) -Name "Request episodes for '$($_.title)' podcast" )
        $j += ( Start-Job -ScriptBlock $b -ArgumentList ($u, $_) -Name "Request episodes for '$($_.title)' podcast" ) # this was faster than threadjob!?
    }
}
end {
    # display progress
    while (($j | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count -gt 0) {
        Start-Sleep -Milliseconds 250
        $c = $($j | Where-Object { $_.State -eq 'Completed' } ).Count
        $f = $($j | Where-Object { $_.State -eq 'Failed' } ).Count
        $g = $($c + $f)
        $s = $g / $($j.count)
        $p = [string]::Format("{0:N2}", ($s * 100))
        Write-Progress -Id 0 -Activity "Episodes" -Status "Pulled $g of $($j.count)" -PercentComplete $p
    }
    Write-Progress -Id 0 -Completed

    <#
        Job state failure would be major powershell oddity as errors are caught and contained within output episode data.
    #>
    if ($f -gt 0) {
        Write-Warning "At leaste one job state returned 'Failure'"
        Write-Warning "Investigate the jobs by using 'get-job'."
        Write-Warning "It is highly recommended to restart powershell and or the system."
    }

    # receive
    $jobs = @( $j | Receive-Job )
    # return
    $jobs
}

<#

.SYNOPSIS

Obtain episodes for each podcast in parallel.

.OUTPUTS

'pulled' is the date of execution.
'episodes' is web response. <- Fastest, 1.7 seconds

#>
[CmdletBinding()]
param (
    [parameter(Mandatory, Position = 0)]
    [ValidateScript({ $_.count -gt 0 -and $null -ne ($_[0] | Get-Member -MemberType Properties) -and $null -ne ($_[$_.count - 1] | Get-Member -MemberType Properties) })]
    [object[]] $Podcasts
)
begin {
    . $PSScriptRoot\utilities
}
process {
    $Podcasts | ForEach-Object -Parallel {
        $_ | Add-Member -MemberType NoteProperty -Name "pulled" -Value $(Get-Date)
        $_ | Add-Member -MemberType NoteProperty -Name "episodes" -Value $(Invoke-WebRequest -Uri $_.url -Method Get -ContentType "application/json")
    }
}
end {
    $Podcasts
}

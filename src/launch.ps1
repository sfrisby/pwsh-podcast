# Starting new shell instance that runs setup.ps1 and returns its output into a new variable, 'configuration'.
# utilities.ps1 is not sourced and the constants defined in setup.ps1 are gone!
# dot sourcing setup.ps1 within the new instance brings all methods and constants into scope from both setup and utilities but is redundant.
# This provides enough setup to then add new podcast and save them manually then reload to set up its container, thumbnail, etc.
<#

.EXAMPLE

. .\src\utilities.ps1

$configuration[0].count # 24
$q = invoke_podcasts "the foreign report" # provides single result
$configuration[0] += $q.podcasts[0]
$configuration[0].count # 25
$configuration[0] | convertto-json -depth 6 | out-file .\src\podcasts

\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
run setup.ps1, i.e. '$configuration = .\src\setup.ps1' OR re-run launch.ps1
///////////////////////////////////////////////////////////////////////////

. .\src\utilities.ps1
$configuration[0].count # 25
$configuration[0][24]
$e = invoke_podcast_episodes ($configuration[0][24] | ConvertTo-Json | ConvertFrom-Json -AsHashtable)

#>
Start-Process pwsh -WorkingDirectory $(Join-Path $PSScriptRoot ".." ".") -ArgumentList "-NoExit", "-Command `"New-Variable -Name configuration (.\src\setup.ps1)`""
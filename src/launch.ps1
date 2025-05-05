# Starting new shell instance that runs setup.ps1 and returns its output into a new variable, 'configuration'.
# utilities.ps1 is not sourced and the constants defined in setup.ps1 are gone!
# dot sourcing setup.ps1 within the new instance brings all methods and constants into scope from both setup and utilities but is redundant.
# This provides enough setup to then add new podcast and save them manually then reload to set up its container, thumbnail, etc.
<#

.EXAMPLE

providing a script block allows setup!

get episodes based on the podcast title (case insensitive):
    > invoke_podcast_episodes ($configuration[0] | where-object {$_.title -imatch <TITLE>} )

#>
$cmd = {
    $Host.UI.RawUI.WindowTitle = 'pwsh podcasts';
    New-Variable -Name configuration (.\src\setup.ps1);
    .\test\show_podcasts.ps1 $configuration[0];
    . .\src\utilities.ps1;
}
Start-Process pwsh -WorkingDirectory $(Join-Path $PSScriptRoot ".." ".") -WindowStyle Maximized -ArgumentList "-NoExit", "-Command `"$($cmd)`"";
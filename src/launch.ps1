<#

.OUTPUTS

Start specific powershell shell.

.NOTES

Providing a script block allows setup!

The working directory is set to the root folder which is where the command block uses relative paths from.

#>
$cmd = {
    $Host.UI.RawUI.WindowTitle = 'pwsh podcasts';
    New-Variable -Name configuration (.\src\setup.ps1);
    New-Variable -Name stopwatch ([Diagnostics.Stopwatch]::StartNew())
    New-Variable -Name podcasts (.\src\invoke_then_format_podcasts_episodes.ps1 $configuration[0]);
    $stopwatch.Stop()
    . .\src\utilities.ps1;
    .\test\show_podcasts.ps1 $podcasts   
}
Start-Process pwsh -WorkingDirectory $(Join-Path $PSScriptRoot ".." ".") -WindowStyle Normal -ArgumentList "-NoExit", "-Command `"$($cmd)`"";
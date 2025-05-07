<#

.OUTPUTS

No major difference between time using start-process or not. still just slow ~ 20s for 25 podcasts

$c = <path>\podcasts\src\setup.ps1
$sw = ([Diagnostics.Stopwatch]::startnew()); $pulled = .\workspace\podcasts\src\episodes.ps1 $c[0]; $sw.stop();

.EXAMPLE

providing a script block allows setup!

get episodes based on the podcast title (case insensitive):
    > invoke_podcast_episodes ($configuration[0] | where-object {$_.title -imatch <TITLE>} )

.NOTES

The working directory is set to the root folder.

#>
$cmd = {
    $Host.UI.RawUI.WindowTitle = 'pwsh podcasts';
    New-Variable -Name configuration (.\src\setup.ps1);

    New-Variable -Name stopwatch ([Diagnostics.Stopwatch]::StartNew())
    New-Variable -Name pulled (.\src\episodes.ps1 $configuration[0]);
    $stopwatch.Stop()

    # .\test\show_podcasts.ps1 $configuration[0];
    New-Variable -Name latest (.\src\first_most_recent_for_all.ps1 $pulled);

    . .\src\utilities.ps1;
}
# Start-Process pwsh -WorkingDirectory $(Join-Path $PSScriptRoot ".." ".") -WindowStyle Maximized -ArgumentList "-NoExit", "-Command `"$($cmd)`"";
Start-Process pwsh -WorkingDirectory $(Join-Path $PSScriptRoot ".." ".") -WindowStyle Normal -ArgumentList "-NoExit", "-Command `"$($cmd)`"";
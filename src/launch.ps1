<#

.OUTPUTS

Start specific powershell shell.

.NOTES

Providing a script block allows setup!

The working directory is set to the root folder which is where the command block uses relative paths from.

.EXAMPLE

Sorting latest episodes and displaying their index:

    $script:latestindex = 0; $latest = $podcasts | Select-Object -Property @{n = "index"; e = { $script:latestindex++ }}, @{n = "date"; e = { [datetime] $_.date }}, title, podcast | Sort-Object -Property date -Descending | select -First <AMOUNT>

    $latest

Selecting an episode from the latest episodes:

    $episode = $podcasts | Where-Object { $_.title -eq $latest[<LATESTINDEX>].title }

Downloading the file via brave link:

    $file = .\test\invoke_brave_download.ps1 $episode

Playing (then exit) the file via VLC at 1.5 times the normal playback speed:

    & $configuration[1].vlc $file --rate 1.5 --play-and-exit

#>
$cmd = {
    $Host.UI.RawUI.WindowTitle = 'TEST pwsh podcasts';
    New-Variable -Name configuration (.\src\setup.ps1);
    New-Variable -Name stopwatch ([Diagnostics.Stopwatch]::StartNew())
    New-Variable -Name podcasts (.\src\invoke_then_format_podcasts_episodes.ps1 $configuration[0]);
    $stopwatch.Stop()
    . .\src\utilities.ps1;
    # .\test\show_podcasts.ps1 $podcasts
}
Start-Process pwsh -WorkingDirectory $(Join-Path $PSScriptRoot ".." ".") -WindowStyle Normal -ArgumentList "-NoExit", "-Command `"$($cmd)`"";
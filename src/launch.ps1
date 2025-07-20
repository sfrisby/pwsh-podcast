<#

.OUTPUTS

Start specific powershell shell.

.NOTES

Providing a script block allows setup!

The working directory is set to the root folder which is where the command block uses relative paths from.

.EXAMPLE

Sorting latest episodes and displaying their index:

    $script:latestindex = 0; $latest = $podcasts | Select-Object -Property @{n = "index"; e = { (($script:latestindex++)) }}, @{n = "date"; e = { [datetime] $_.date }}, title, podcast | Sort-Object -Property date -Descending | select -First <AMOUNT>

    $latest

Selecting an episode from the latest episodes:

    $episode = $podcasts | Where-Object { $_.title -eq $latest[<LATESTINDEX>].title }

Downloading the file via brave link:

    $file = .\test\invoke_brave_download.ps1 $episode

Playing (then exit) the file via VLC at 1.5 times the normal playback speed:

    & $configuration[1].vlc $file --rate 1.5 --play-and-exit

#>
[CmdletBinding()]
param()

Write-Debug "script root - $PSScriptRoot"

$wd = $(Split-Path -Parent $PSScriptRoot)

Write-Debug "working directory - $wd"

$cmd = Join-Path $PSScriptRoot "commandblock.ps1"

Write-Debug "command block - $cmd"

Start-Process pwsh -WorkingDirectory $wd -WindowStyle Normal -ArgumentList "-NoExit", "-File", $cmd

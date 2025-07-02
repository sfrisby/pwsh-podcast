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
$cmd = {

    $Host.UI.RawUI.WindowTitle = 'TEST pwsh podcasts';
    New-Variable -Name configuration (.\src\setup.ps1);
    New-Variable -Name stopwatch ([Diagnostics.Stopwatch]::StartNew())
    New-Variable -Name podcasts (.\src\invoke_then_format_podcasts_episodes.ps1 $configuration[0]);
    $stopwatch.Stop()
    . .\src\utilities.ps1;
    # .\test\show_podcasts.ps1 $podcasts

    function Show-Recent-Episodes {
        param (
            [parameter(Position = 0)]
            [int] $Count = 10
        )
        $script:index = 0;
        $podcasts | Select-Object -Property @{n = 'index'; e = { ($script:index++) } }, @{n = 'date'; e = { [datetime] $_.date } }, title, podcast | Sort-Object -Property date -Descending | Select-Object -First $Count
    }

    function Start-Episode-Stream {
        param (
            [parameter(Mandatory, Position = 0)]
            [int] $Episode,
            [parameter(Position = 1)]
            [Single] $Rate = 1.5
        )
        & $configuration[1].vlc $podcasts[$Episode].url --rate $Rate --play-and-exit
    }

    function Start-Episode-File {
        param (
            [parameter(Mandatory, Position = 0)]
            [string] $File,
            [parameter(Position = 1)]
            [Single] $Rate = 1.5
        )
        & $configuration[1].vlc $File --rate $Rate --play-and-exit
    }

    function Start-Episode-Download {
        param (
            [parameter(Mandatory, Position = 0)]
            [int] $Episode
        )
        .\test\invoke_brave_download.ps1 $podcasts[$Episode]
    }
}

Start-Process pwsh -WorkingDirectory $(Join-Path $PSScriptRoot ".." ".") -WindowStyle Normal -ArgumentList "-NoExit", "-Command `"$($cmd)`"";

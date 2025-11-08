[CmdletBinding()]
param()

$Host.UI.RawUI.WindowTitle = 'TEST pwsh podcasts'

New-Variable -Name stopwatch ([Diagnostics.Stopwatch]::StartNew())

New-Variable -Name configuration (.\src\setup.ps1)

New-Variable -Name podcasts (.\src\invoke_then_format_podcasts_episodes.ps1 $configuration[0])

$stopwatch.Stop()

Write-Debug "parsed $($podcasts.count) episodes for $($configuration[0].count) podcasts within $stopwatch"

function request_episodes {
    return (.\src\invoke_then_format_podcasts_episodes.ps1 $configuration[0])
}

function show_recent_episodes {
    param (
        [parameter(Position = 0)]
        [int] $Count = 10,
        [parameter(Position = 1)]
        [string] $Podcast = ""
    )
    $script:index = 0;
    $script:recent = "";
    if ([string]::IsNullOrEmpty($Podcast)) {
        $recent = $podcasts | Select-Object -Property @{n = 'index'; e = { ($script:index++) } }, @{n = 'date'; e = { [datetime] $_.date } }, title, podcast
    }
    else {
        $recent = $podcasts | Where-Object -Property podcast -IMatch "$Podcast" | Select-Object -Property @{n = 'index'; e = { [array]::IndexOf($podcasts, $_) } }, @{n = 'date'; e = { [datetime] $_.date } }, title, podcast
    }
    $recent | Sort-Object -Property date -Descending | Select-Object -First $Count
}

function open_episode {
    param (
        [parameter(Mandatory, Position = 0)]
        [string] $Episode,
        [parameter(Position = 1)]
        [Single] $Rate = 1.5
    )
    if (Test-Path -Path $Episode -PathType Leaf) {
        Write-Debug "Episode appears to be a podcast file: $Episode"
        open_episode_file -File $Episode -Rate $Rate
    } else {
        Write-Debug "Episode appears to be a index for podcast: $Episode"
        open_episode_stream -Episode $Episode -Rate $Rate
    }
}

function open_episode_stream {
    param (
        [parameter(Mandatory, Position = 0)]
        [int] $Episode,
        [parameter(Position = 1)]
        [Single] $Rate = 1.5
    )
    & $configuration[1].vlc $podcasts[$Episode].url --rate $Rate --play-and-exit
}

function open_episode_file {
    param (
        [parameter(Mandatory, Position = 0)]
        [string] $File,
        [parameter(Position = 1)]
        [Single] $Rate = 1.5
    )
    & $configuration[1].vlc $File --rate $Rate --play-and-exit
}

function get_episode {
    param (
        [parameter(Mandatory, Position = 0)]
        [int] $Episode
    )
    .\test\invoke_brave_download.ps1 $podcasts[$Episode]
}

function show_podcasts {
    $configuration[0] | select-Object -Property @{n = 'index'; e = { [array]::IndexOf($configuration[0], $_) } }, title, author, url
}

if ($podcasts.count -gt 0) {
    Write-Host "Gathering most recent episodes ..." -ForegroundColor Green
    show_recent_episodes
}
else {
    if ($($configuration[0].count) -gt 0) {
        Write-Host "No episodes found! Searched through $($configuration[0].count) podcast(s)." -ForegroundColor Red
        show_podcasts
    }
}

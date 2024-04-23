<#
.SYNOPSIS
Write a CLI centered message.
#>
function Write-HostWelcome {
    param(
        # Parameter help description.
        [Parameter(Mandatory = $true)]
        [string] $Message,
        # Delimiter to encase around message.
        [ValidateScript( { $_.length -eq 1 } )]
        [string] $delimiter = ' '
    )
    $ruler = $delimiter * [Console]::BufferWidth
    $split = ($ruler.Length - $Message.Length) / 2
    $spacer = $delimiter * $split
    $title = $($spacer + $Message + $spacer)
    if ($title.length -gt [Console]::BufferWidth) {
        $title = $title[0..([Console]::BufferWidth - 1)] | join-string
    }
    Write-Host $ruler
    Write-Host $title
    Write-Host $ruler
}

<#
.SYNOPSIS
Calculating console padding for all episodes as found in the array of hashtables for simple indexing.
#>
function Write-HostCLIEpisodes {
    param (
        [Parameter(Mandatory = $true)]
        [array] $Episodes
    )
    $extraPadding = 3
    $podcastPadding = $($($($Episodes) | ForEach-Object { $_.Keys[0].length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $titlePadding = $($($($Episodes) | ForEach-Object { $_.$($_.Keys[0]).title.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $durationPadding = $($($($Episodes) | ForEach-Object { $_.$($_.Keys[0]).duration.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $datePadding = $($($($Episodes) | ForEach-Object { $_.$($_.Keys[0]).pubDate.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $padIndex = $Episodes.Count.ToString().Length
    $origBgColor = $host.UI.RawUI.ForegroundColor
    $r = "  "
    $rw = "_" * $($r.Length)
    $color = 0
    foreach ($e in $Episodes) {
        if ($color % 2) {
            $host.UI.RawUI.ForegroundColor = 'DarkBlue'
            ([string]$($Episodes.IndexOf($e))).padleft($padIndex) +
            " " + ([string]$($e.Keys[0])).padleft($podcastPadding).Replace($r, $rw) +
            " " + ([string]$($e.$($e.Keys[0]).title)).PadLeft($titlePadding).Replace($r, $rw) +
            " " + ([string]$($e.$($e.Keys[0]).duration)).PadLeft($durationPadding).Replace($r, $rw) +
            " " + ([string]$($e.$($e.Keys[0]).pubDate)).PadLeft($datePadding).Replace($r, $rw)
        }
        else {
            $host.UI.RawUI.ForegroundColor = $origBgColor
                ([string]$($Episodes.IndexOf($e))).padleft($padIndex) +
            " " + ([string]$($e.Keys[0])).padleft($podcastPadding).Replace($r, $rw) +
            " " + ([string]$($e.$($e.Keys[0]).title)).PadLeft($titlePadding).Replace($r, $rw) +
            " " + ([string]$($e.$($e.Keys[0]).duration)).PadLeft($durationPadding).Replace($r, $rw) +
            " " + ([string]$($e.$($e.Keys[0]).pubDate)).PadLeft($datePadding).Replace($r, $rw)
        }
        $color = $color + 1
    }
    $host.UI.RawUI.ForegroundColor = $origBgColor
}

function Get-FileLastWriteTime {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [String] $File
    )
    $(Get-ChildItem -Path $File | Select-Object -Property LastWriteTime).LastWriteTime
}

function Write-EpisodesFile {
    param(
        [Parameter(Mandatory = $true)]
        [array] $Episodes,
        [Parameter(Mandatory = $true)]
        [String] $File,
        [Parameter(Mandatory = $false)]
        [int] $Depth = 10
    )
    $Episodes | ConvertTo-Json -depth $Depth | Out-File -Force -FilePath $File
}

<#
.SYNOPSIS
    Generate or update a podcast episode file.
.DESCRIPTION
    A JSON file is used to create and store episode lists. 

    Check if a file already exists. If there are differences, than update the file.
.NOTES
    Episodes are automatically updated if the last write time for the file has been
    longer than 12 hours.
.EXAMPLE
    Update-Episodes -Podcast $podcast
    Generates or updates an episode list for the given $podcast.
#>

# Writing console output for episodes, specifically: index | episode-title | publication date
<#
.SYNOPSIS
CLI method to display episodes for selection.
.PARAMETER Amount
The number of episodes to display. Default is 10. Providing 0 will list all episodes.
#>
function Write-HostEpisodesList {
    param(
        # Array containing hashtables of episode entries.
        [Parameter(Mandatory = $true)]
        [array] $Episodes,
        # Additional spacing for episode information.
        [int] $Padding = 3,
        # Provide the amount of episodes to list;. Default is 10. Providing 0 will show all episodes.
        [int] $Amount = 10
    )
    if ($Amount -eq 0) {
        $Amount = $Episodes.Count
    }
    $padTitle = $($($Episodes.title | Select-Object -First $Amount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $Padding
    $padDate = $($($Episodes.pubDate | Select-Object -First $Amount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $Padding
    $padIndex = $Episodes.Count.ToString().Length
    $padDuration = $($($Episodes.duration | Select-Object -First $Amount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $Padding
    $Episodes | Select-Object -First $Amount | ForEach-Object {
        $($Episodes.indexof($_)).tostring().padleft($padIndex) + 
        " | " + $($_.title).padleft($padTitle) +
        " | " + $($_.duration ? $_.duration : "n/a").padleft($padDuration) +
        " | " + $($_.pubDate).padleft($padDate) | Out-Host
    }
}

function Invoke-Download {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$URI,
        [ValidateScript({ 
                $(Test-Path -Path $_ -PathType Leaf -IsValid) -and 
                $($_.Name -notmatch [System.IO.Path]::GetInvalidFileNameChars()) 
            })]
        [string]$Path = [System.IO.Path]::Combine(
            [System.IO.Path]::GetTempPath(), 
            [System.IO.Path]::GetTempFileName())
    )
    Invoke-WebRequest -Uri $URI -OutFile $Path
}

# https://stackoverflow.com/questions/25895428/how-to-play-mp3-with-powershell-simple
# https://wiki.videolan.org/VLC_command-line_help/

function PlayMediaWithVlc {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string] $Media,
        [string] $VLC = 'C:\Program Files\VideoLAN\VLC\vlc.exe',
        [double] $rate = 1.5,
        $mini = '--qt-start-minimized',
        $ignore = '--qt-notification=0'
    )
    & $VLC $mini --play-and-exit $ignore --rate=$rate $file
}

# Play a single file
$file = Get-ChildItem -Filter "*.mp3"
if ($null -ne $file.Name -and $file.Name.Count -gt 1) {
    $listedAmount = 5
    $extraPadding = 1
    $indexPadding = $file.Count.ToString().Length + $extraPadding
    $namePadding = $($($file.name | Select-Object -First $listedAmount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $extraPadding
    $file | Select-Object -First $listedAmount | ForEach-Object { # Creating console output: index  episode-title
        if ($file.indexof($_) % 2) {
            $($($file.indexof($_)).tostring() + "     ").padleft($indexPadding) + 
            $($_.Name).padleft($namePadding)
        } else {
            $($($file.indexof($_)).tostring() + " --- ").padleft($indexPadding) + 
            $($_.Name).padleft($namePadding)
        }
    }
    $choice = Read-Host -Prompt "Multiple files found. Specify which file to play (by #): "
    $file = $file[$choice]
    write-host "$choice selects $file."
} elseif ($file.Length -eq 0) {
    throw [System.IO.FileNotFoundException] "No files were found."
}

PlayMediaWithVlc -Media $file
write-host "Attempting to play: $($file.Name)"

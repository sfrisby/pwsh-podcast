<#

.SYNOPSIS

Show the latest episodes pulled from all podcasts.

.NOTES

Podcasts title will be centered and followed by their index within the provided array.

Podcasts title will be preceeded by an empty row and followed by a ruler. Episodes will
then be displayed with their index, publication date (two digits for year, two digits for
month, two digits for day), and lastly followed by the episode title.

Episode titles may be truncated if they are longer then the shells character columns.

.PARAMETER Pulled

Array containing hashtable elements of podcasts with their episodes. Keys to contain
'podcast' for the podcast information and 'episodes' for its episodes.

.PARAMETER First

Default is 3.

.EXAMPLE

todo - script out the steps:
.\src\first_most_recent_for_all.ps1 $pulled -first 10
$p = <PODCAST INDEX>; $e = <EPISODE INDEX>;
$f = .\test\invoke_brave_download.ps1 -Podcast $pulled[$p].podcast -Episode $pulled[$p].episodes[$e]
& $configuration[1].vlc "$f" --rate 1.5 --play-and-exit

#>
[CmdletBinding()]
param (
    [parameter(Mandatory, Position = 0)]
    [ValidateScript({ $null -ne $_.podcast -and $null -ne $_.episodes })]
    [object[]] $Pulled,
    [parameter(Position = 1)]
    [Int16] $First = 3
)
begin {}   
process {
    $cc = $Host.UI.RawUI.WindowSize.Width
    $padding = 3
    $script:pindex = 0
    $Pulled | ForEach-Object {
        $script:eindex = 0
        $t = [Int16](($cc - $script:pindex.ToString.length - $_.podcast.title.length - $padding) * 0.5)
        (" " * $cc) # empty row
        (" " * $t) + "$($_.podcast.title) - $script:pindex";
        ("=" * $cc) # ruler row
        $_.episodes | Select-Object -First $First | ForEach-Object {
            $d = $(([datetime]$_.pubDate).ToString("yyMMdd"))
            $r = $cc - $d.length - $script:eindex.ToString.length - $padding
            "$script:eindex $d $($_.title[0..$r] | Join-String)"
            $script:eindex++;
        }
        $script:pindex++;
    }
}
end {}

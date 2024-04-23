<#
.SYNOPSIS
Add a new podcast to the RSS file.
.DESCRIPTION
Search results are based on the $Name provided.
#>
function Add-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -ne "" })]
        [String] $Name
    )    
    $search = Search-Podcasts -Name $Name
    $podcast = Select-Podcast -Podcasts $search.data
    $local = @(Get-Podcasts) # Ensure an collection of hashtables is obtained.
    if ($null -eq $local -or $local.Count -eq 0) {
        Save-Podcasts -Podcasts @( $podcast )
    }
    elseif ($local[0] -eq 'No feeds found.') {
        Save-Podcasts -Podcasts @( $podcast )
    }
    elseif ($local.title -contains $podcast.title) {
        Write-Host "$($podcast.title) already exists."
    }
    else {
        if ($local.GetType().BaseType -ne [array]) {
            throw "Adding podcast failed due to type mismatch."
        }
        $local += @( $podcast )
        Save-Podcasts -Podcasts $local
    }
}

<#
.SYNOPSIS
Read information from provided $File and return it.
.DESCRIPTION
Default $File is the path provided by module member Get-RssFilePath.
.NOTES
It is possible for $File content to be $null!
Even though ensuring an array of hashtable elements occurs here it should also be wrapped where called to ensure type, i.e. @(Get-Podcasts).
#>
function Get-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $File = $(Get-RssFilePath)
    )
    $tmp = [array]$(Get-Content -Path $File -Raw | ConvertFrom-Json -AsHashtable)
    if ($null -eq $tmp) {
        $tmp = 'No feeds found.'
    }
    elseif ($tmp.gettype() -eq [System.Management.Automation.OrderedHashtable]) {
        $force = @( $tmp )
        $tmp = $force
    }
    @($tmp)
}

<#
.SYNOPSIS
Return an approved episode file string path for a file name.
#>
function Get-PodcastEpisodesFileName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Name
    )
    join-path $(Get-EpisodeFolderPath) $( Approve-String $($Name + ".json") )
}

<#
.SYNOPSIS
Return episodes contained within the provided file.
.NOTES
Best to encapsulate where called, i.e. @(Get-EpisodesLocal -File {})
#>
function Get-EpisodesLocal {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf -and $_ -like "*.json" })]
        [string] $File
    )
    [array]$(Get-Content -Path $file -Raw | ConvertFrom-Json -AsHashtable)
}

<#
.SYNOPSIS
Return episodes from the provided podcast.
.NOTES
Best to encapsulate where called, i.e. @(Get-EpisodesOnline -Podcast {})
#>
function Get-EpisodesOnline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $null -ne $_.url })]
        [hashtable] $Podcast
    )
    [array]$(ConvertFrom-PodcastWebRequestContent -Request $(Invoke-PodcastFeed -URI $Podcast.url))
}

<#
.SYNOPSIS
Play the provided episode via VLC stream.
#>
function Invoke-VlcStream {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript({ $null -ne $_.enclosure.url })]
        [hashtable] $Episode,
        [Parameter()]
        [ValidateScript({ $null -ne $_ -and $_.length -gt 0 })]
        [string] $VLC = "C:\Program Files\VideoLAN\VLC\vlc.exe",
        [Parameter()]
        [ValidateRange(0,3)]
        [float] $Rate = 1.5
    )
    & $VLC --play-and-exit --rate=$Rate $($Episode.enclosure.url)
}

<#
.SYNOPSIS
Linearly filter podcasts by the provided $Name.
.DESCRIPTION
Changes are only saved when they exist.
#>
function Remove-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.Length -gt 0 })]
        [string]
        $Name
    )
    $rss = @(Get-Podcasts)
    $keep = @()
    foreach ($podcast in $rss) {
        if ($podcast.title -ne $Name) {
            $keep += @($podcast)
        }
    }
    if ($($keep.title | join-string).Length -ne $($rss.title | join-string).Length) {
        Save-Podcasts -Podcasts $keep
    }
    else {
        Write-Host "$Name was not found. No podcasts were removed."
    }
}

<#
.SYNOPSIS
Save all episodes provided at $file.
.DESCRIPTION
Overwrites $file.
.NOTES
Parenthesis is necessary for validate script.
#>
function Save-Episodes {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript({ $null -ne $_.title })]
        [array] $Episodes,
        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string] $File
    )
    $Episodes | ConvertTo-Json | Out-File -FilePath $File -Force
}

<#
.SYNOPSIS
Save $Podcasts in the provided $File.
.DESCRIPTION
The default $File path is provided by the module member Get-RssFilePath.
.NOTES
The parenthesis are necessary for allowing empty collection.
#>
function Save-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array] $Podcasts,
        [Parameter(Mandatory = $false)]
        [string] $File = $(Get-RssFilePath)
    )
    $Podcasts | ConvertTo-Json | Out-File -FilePath $File
}

<#
.SYNOPSIS
Obtain podcast search results for the provided $Name.
.NOTES
See Invoke-CastosPodcastSearch for type details.
#>
function Search-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $null -ne $_ -and $_.Length -gt 0 })]
        [String] $Name
    )
    $search = Invoke-CastosPodcastSearch -Podcast $Name
    if ($search.data -eq 'No feeds found.') {
        throw $search.data
    }
    $search
}

<#
.SYNOPSIS
Select an episode from the provided podcast.
#>
function Select-Episode {
    [CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [hashtable] $Podcast = $( Select-Podcast -Podcasts @(Get-Podcasts) ),
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet('Today', 'Week', 'Month', 'Year', 'All')]
        [string] $Published = "Week"
    )
    $episode = @{}
    $episodes = @()
    $file = Get-PodcastEpisodesFileName -Name $Podcast.title
    if (Test-Path -Path $file -PathType Leaf) {
        $episodes = @(Get-EpisodesLocal -File $file)
    }
    else {
        $episodes = @(Get-EpisodesOnline -Podcast $Podcast)
    }

    if ($episodes.gettype().BaseType -eq [array] -and $episodes.Count -eq 0) {
        throw "No episodes found for $($Podcast.title)."
    }
    Show-Episodes -Episodes $episodes -Published $Published
    $choice = Read-Host "Select episode by number (above)"
    try {
        $episode = $Episodes[[int]::Parse($choice)]
    }
    catch {
        throw "'$choice' failed to identify any episode."
    }
    $episode
}

<#
.SYNOPSIS
Selects the identified podcast from the provided podcasts.
.DESCRIPTION
When only one podcast is provided it is returned without show & selection.
.NOTES
Read-Host puts colon, i.e. ':', at the end.
#>
function Select-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $Podcasts
    )
    if ($Podcasts.Length -eq 1 -or $Podcasts.Count -eq 1) {
        return $Podcasts[0]
    }
    Show-Podcasts -Podcasts $Podcasts
    $choice = Read-Host "Select podcast by number (above)"
    $podcast = @{}
    try {
        $podcast = $Podcasts[[int]::Parse($choice)]
    }
    catch {
        throw "'$choice' failed to identify any podcast."
    }
    $podcast
}

<#
.SYNOPSIS
Display episodes to the console.
.PARAMETER Published
Determines which episodes based on date published to be listed.
Today lists those within the last day ~ 24 hours.
Week lists those within the last week ~ 7x24 ~ 168 hours.
Month lists those within the last month ~ 168x4 ~ 672 hours.
Year lists those within the last year ~ 672x12 ~ 8064 hours.
All lists all episodes.
.NOTES
foreach-object does not behave the same way when using break as foreach.
#>
function Show-Episodes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ 
                if ( $null -eq $_ -or $_.Count -eq 0 ) { throw 'No episodes found.' }
                $true # Must provide or will never return a result of $true.
            })]
        [array] $Episodes,
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet('Today', 'Week', 'Month', 'Year', 'All')]
        [string] $Published = "Week",
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Int16] $Pad = 3
    )

    $hours = 0
    switch ($Published) {
        'Today' { $hours = 24 }
        'Week' { $hours = 168 }
        'Month' { $hours = 672 }
        'Year' { $hours = 8064 }
        Default { $hours = 0 }
    }

    $filtered = @()
    if ( -not $hours ) {
        $filtered = $Episodes
    }
    else {
        foreach ($e in $Episodes) {
            if ( ($(Get-Date) - (Get-Date $e.pubDate).ToUniversalTime()).TotalHours -le $hours ) {
                $filtered += @( $e )
            }
            else {
                break
            }
        }
    }

    if ($filtered.Count -eq 0) {
        throw "No episodes found within the last $hours hours."
    }

    $index_pad = $filtered.Count.ToString().Length
    $title_pad = $($($($filtered) | ForEach-Object { $_.title.length }) | Measure-Object -Maximum).Maximum + $Pad
    $pub_pad = $($($($filtered) | ForEach-Object { $_.pubDate.length }) | Measure-Object -Maximum).Maximum + $Pad
    # Alternating foreground color and underscore for visual cue.
    $original = $host.UI.RawUI.ForegroundColor
    $s = "  "
    $u = "__"
    $filtered | ForEach-Object {
        if ( $filtered.indexof($_) % 2) {
            $host.UI.RawUI.ForegroundColor = 'DarkGray'
            write-host $($([string]$filtered.indexof($_)).PadLeft($index_pad).Replace($s, $u) +
                " " + $([string]$_.title).PadLeft($title_pad).Replace($s, $u) +
                " " + $([string]$_.pubDate).PadLeft($pub_pad).Replace($s, $u))
        }
        else {
            $host.UI.RawUI.ForegroundColor = $original
            write-host $($([string]$filtered.indexof($_)).PadLeft($index_pad) +
                " " + $([string]$_.title).PadLeft($title_pad) +
                " " + $([string]$_.pubDate).PadLeft($pub_pad))
        }
    }
    $host.UI.RawUI.ForegroundColor = $original
}

<#
.SYNOPSIS
Display podcast information to the console.
#>
function Show-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [ValidateScript({ 
                if ( $_ -eq 'No feeds found.' -or $_.Count -eq 0 -or $_[0] -eq 'No feeds found.') { throw 'No feeds found.' }
                $true # Must provide or will never return a result of $true.
            })]
        [array] $Podcasts = @(Get-Podcasts),
        [Parameter(Mandatory = $false)]
        [Int16] $Pad = 3
    )
    $index_pad = $podcasts.Count.ToString().Length
    $authr_pad = $($($($podcasts) | ForEach-Object { $_.author.length }) | Measure-Object -Maximum).Maximum + $Pad
    $title_pad = $($($($podcasts) | ForEach-Object { $_.title.length }) | Measure-Object -Maximum).Maximum + $Pad
    $url_pad = $($($($podcasts) | ForEach-Object { $_.url.length }) | Measure-Object -Maximum).Maximum + $Pad

    # Alternating foreground color and underscore for visual cue.
    $original = $host.UI.RawUI.ForegroundColor
    $s = "  "
    $u = "__"
    $podcasts | ForEach-Object {
        if ( $podcasts.indexof($_) % 2) {
            $host.UI.RawUI.ForegroundColor = 'DarkGray'
            write-host $($([string]$podcasts.indexof($_)).PadLeft($index_pad).Replace($s, $u) +
                " " + $([string]$_.title).PadLeft($title_pad).Replace($s, $u) +
                " " + $([string]$_.author).PadLeft($authr_pad).Replace($s, $u) +
                " " + $([string]$_.url).PadLeft($url_pad).Replace($s, $u))
        }
        else {
            $host.UI.RawUI.ForegroundColor = $original
            write-host $($([string]$podcasts.indexof($_)).PadLeft($index_pad) +
                " " + $([string]$_.title).PadLeft($title_pad) +
                " " + $([string]$_.author).PadLeft($authr_pad) +
                " " + $([string]$_.url).PadLeft($url_pad))
        }
    }
    $host.UI.RawUI.ForegroundColor = $original
}

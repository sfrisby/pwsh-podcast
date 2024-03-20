
. ".\test\ConvertFrom-PodcastWebRequestContent\ConvertFrom-PodcastWebRequestContent.ps1"

function Write-Host-Welcome {
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
.DESCRIPTION
Retrived via Chrome developer tools.
#>
function Invoke-CastosPodcastSearch {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$Podcast
    )
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
    $session.Cookies.Add((New-Object System.Net.Cookie("tlf_58", "1", "/", "castos.com")))
    $session.Cookies.Add((New-Object System.Net.Cookie("tve_leads_unique", "1", "/", "castos.com")))
    $session.Cookies.Add((New-Object System.Net.Cookie("tl_21131_21132_58", "a%3A1%3A%7Bs%3A6%3A%22log_id%22%3BN%3B%7D", "/", "castos.com")))
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://castos.com/wp-admin/admin-ajax.php" `
        -Method "POST" `
        -WebSession $session `
        -Headers @{
        "authority"          = "castos.com"
        "method"             = "POST"
        "path"               = "/wp-admin/admin-ajax.php"
        "scheme"             = "https"
        "accept"             = "*/*"
        "accept-encoding"    = "gzip, deflate, br"
        "accept-language"    = "en-US,en;q=0.7"
        "cache-control"      = "no-cache"
        "origin"             = "https://castos.com"
        "pragma"             = "no-cache"
        "referer"            = "https://castos.com/tools/find-podcast-rss-feed/"
        "sec-ch-ua"          = "`"Not A(Brand`";v=`"99`", `"Brave`";v=`"121`", `"Chromium`";v=`"121`""
        "sec-ch-ua-mobile"   = "?0"
        "sec-ch-ua-platform" = "`"Windows`""
        "sec-fetch-dest"     = "empty"
        "sec-fetch-mode"     = "cors"
        "sec-fetch-site"     = "same-origin"
        "sec-gpc"            = "1"
    } `
        -ContentType "multipart/form-data; boundary=----WebKitFormBoundaryEvNAMJxBVu6aUrB3" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes("------WebKitFormBoundaryEvNAMJxBVu6aUrB3$([char]13)$([char]10)Content-Disposition: form-data; name=`"search`"$([char]13)$([char]10)$([char]13)$([char]10)$($Podcast)$([char]13)$([char]10)------WebKitFormBoundaryEvNAMJxBVu6aUrB3$([char]13)$([char]10)Content-Disposition: form-data; name=`"action`"$([char]13)$([char]10)$([char]13)$([char]10)feed_url_lookup_search$([char]13)$([char]10)------WebKitFormBoundaryEvNAMJxBVu6aUrB3--$([char]13)$([char]10)"))
    
    $results = ""
    if ( $response.StatusCode -ne 200 ) {
        Throw "Response code was: $($response.StatusCode) | $($response.StatusDescription)."
    }
    $results = $($response.Content | ConvertFrom-json).data
    $results
}

<#
.DESCRIPTION
Calculating console padding to display for the podcasts found.
#>
function displayPodcastsFeeds {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $($null -ne $_) -and $($_.count -ne 0) })]
        [array] $Podcasts
    )
    $extraPadding = 3
    $titlePadding = $($($($Podcasts) | ForEach-Object { $_.title.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $authorPadding = $($($($Podcasts) | ForEach-Object { $_.author.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $urlPadding = $($($($Podcasts) | ForEach-Object { $_.url.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $indexPadding = $Podcasts.Count.ToString().Length
    $origBgColor = $host.UI.RawUI.ForegroundColor
    $r = "  "
    $rw = "_" * $($r.Length)
    $Podcasts | ForEach-Object {
        if ( $Podcasts.indexof($_) % 2) {
            # Alternating for visual cue.
            $host.UI.RawUI.ForegroundColor = 'DarkGreen'
            $([string]$Podcasts.indexof($_)).padleft($indexPadding) +
            " " + $([string]$_.title).PadLeft($titlePadding) +
            " " + $([string]$_.author).PadLeft($authorPadding) +
            " " + $([string]$_.url).PadLeft($urlPadding)
        }
        else {
            $host.UI.RawUI.ForegroundColor = $origBgColor
            $([string]$Podcasts.indexof($_)).padleft($indexPadding) +
            " " + $([string]$_.title).PadLeft($titlePadding).Replace($r, $rw) +
            " " + $([string]$_.author).PadLeft($authorPadding).Replace($r, $rw) +
            " " + $([string]$_.url).PadLeft($urlPadding).Replace($r, $rw)
        }
    }
    $host.UI.RawUI.ForegroundColor = $origBgColor
}

function Approve-String {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$ToSanitize
    )
    [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object { 
        $tmp = $ToSanitize.replace("$_", "")
        if ($tmp.Length -lt $ToSanitize.Length) {
            Write-Host "Invalid character '${_}' found; removing ..."
            $ToSanitize = $tmp
        }
    }
    $ToSanitize
}

function Get-Podcast-Episode-List {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [String] $File
    )
    [array] $(Get-Content -Path $File | ConvertFrom-Json -AsHashtable)
}

function Get-Last-Write-Time {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [String] $File
    )
    $(Get-ChildItem -Path $File | Select-Object -Property LastWriteTime).LastWriteTime
}

function Write-Episodes-To-Json {
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
    TODO: instead of writing entire file, only update the changes.
.NOTES
    Episodes are automatically updated if the last write time for the file has been
    longer than 12 hours.
.EXAMPLE
    Update-Episodes -Podcast $podcast
    Generates or updates an episode list for the given $podcast.

    Update-Episodes -Podcast $podcast -Force
    Forces search for episodes and updated for the given $podcast even if the last write
    time was less than 12 hours.
#>
function Update-Episodes {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Podcast,
        [Parameter]
        [switch] $Force
    )
    $episodesLocal = @()
    $episodesLatest = @()
    $hoursToCheckAgain = 12
    $podcastTitle = Approve-String -ToSanitize $Podcast.title
    $episodesFile = $setup.prefix_episode_list + "$podcastTitle.json"
    if ( Test-Path -Path "$episodesFile" -PathType Leaf ) {
        $episodesLocal = Get-Podcast-Episode-List -File $episodesFile
        if ("null" -eq $episodesLocal) {
            throw "File provided contained 'null'. Delete '$episodesFile' and try again."
        }
        $lastWriteTimeDifference = $(Get-Date) - $(Get-Last-Write-Time -File $episodesFile)
        $hoursSinceLastWritten = $lastWriteTimeDifference.Hours
        if ( $hoursSinceLastWritten -ge $hoursToCheckAgain -or $Force ) {
            write-host "Checking '$($Podcast.title)' for new episodes ..."
            # TODO: update only those different to save time.
            $episodesLatest = ConvertFrom-PodcastWebRequestContent -Request $(Get-Podcast-Feed -URI $Podcast.url)
            if ( $episodesLatest[0].title -ne $episodesLocal[0].title ) {
                Write-Episodes-To-Json $episodesLatest -File $episodesFile
                return $episodesLatest
            }
        }
    }
    else {
        # Episode file doesn't exist so create it.
        Write-Host "Selected '$($Podcast.title)'. Performing first time episode gathering ..."
        #
        # TODO: FAILS (ERROR POPS UP) IF REQUEST IS 'FORBIDDEN'
        # 
        Write-Episodes-To-Json -Episodes $(ConvertFrom-PodcastWebRequestContent -Request $(Get-Podcast-Feed -URI $Podcast.url)) -File $episodesFile
    }
    $(Get-Podcast-Episode-List -File $episodesFile)
}

function Get-Podcast-Feed {
    param(
        [Parameter(Mandatory = $true)]
        [string] $URI,
        [Parameter] 
        [switch] $Force
    )
    <#
    
    # catch [System.Net.Http.HttpRequestException] {
    # TODO: would be best to Convert System.Net.Http.HttpResponseMessage (via exception) to Microsoft.PowerShell.Commands.WebResponseObject (for XML)
    #       but unable to find a viable solution to do so.
    # $request = @{ 'Content' = $($_.Exception.Response.Content | ConvertTo-Html) | Join-String }
    
    #>
    $(Invoke-WebRequest -Uri $URI -Method Get -ContentType "application/json")
}

# Writing console output for episodes, specifically: index | episode-title | publication date
function Write-Episodes {
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
    $eTitlePadding = $($($Episodes.title | Select-Object -First $Amount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $Padding
    $ePubDatePadding = $($($Episodes.pubDate | Select-Object -First $Amount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $Padding
    $indexPadding = $Episodes.Count.ToString().Length
    $Episodes | Select-Object -First $Amount | ForEach-Object {
        $($Episodes.indexof($_)).tostring().padleft($indexPadding) + 
        " | " + $($_.title).padleft($eTitlePadding) +
        " | " + $($_.pubDate.Values).padleft($ePubDatePadding) | Out-Host
    }
}

<# TODO: This just downloads a file at the specified URI - better to rename as it is unclear anything is written #>
function Get-Episode {
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

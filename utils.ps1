function Write-Host-Welcome() {
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
https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1

convert any simple XML document into an ordered hashtable. 
#>
function ConvertFrom-XML {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [System.Xml.XmlNode]$node,
        #we are working through the nodes

        [string]$Prefix = '',
        #do we indicate an attribute with a prefix?

        $ShowDocElement = $false #Do we show the document element? 
    )
	
    process {
        #if option set, we skip the Document element
        if ($node.DocumentElement -and !($ShowDocElement))
        { $node = $node.DocumentElement }
        $oHash = [ordered] @{ } # start with an ordered hashtable.
        #The order of elements is always significant regardless of what they are
        write-verbose "calling with $($node.LocalName)"
        if ($null -ne $node.Attributes) {
            #if there are elements
            # record all the attributes first in the ordered hash
            $node.Attributes | ForEach-Object {
                $oHash.$($Prefix + $_.FirstChild.parentNode.LocalName) = $_.FirstChild.value
            }
        }
        # check to see if there is a pseudo-array. (more than one
        # child-node with the same name that must be handled as an array)
        $node.ChildNodes | #we just group the names and create an empty array for each
        Group-Object -Property LocalName | where-object { $_.count -gt 1 } | Select-Object Name |
        ForEach-Object {
            write-verbose "pseudo-Array $($_.Name)"
            $oHash.($_.Name) = @() <# create an empty array for each one#>
        };
        foreach ($child in $node.ChildNodes) {
            #now we look at each node in turn.
            write-verbose "processing the '$($child.LocalName)'"
            $childName = $child.LocalName
            if ($child -is [system.xml.xmltext]) {
                # if it is simple XML text 
                write-verbose "simple xml $childname";
                $oHash.$childname += $child.InnerText
            }
            # if it has a #text child we may need to cope with attributes
            elseif ($child.FirstChild.Name -eq '#text' -and $child.ChildNodes.Count -eq 1) {
                write-verbose "text";
                if ($null -ne $child.Attributes) {
                    # an attribute; we need to record the text with the #text label and preserve all the attributes
                    $aHash = [ordered]@{ };
                    $child.Attributes | ForEach-Object {
                        $aHash.$($_.FirstChild.parentNode.LocalName) = $_.FirstChild.value
                    }
                    #now we add the text with an explicit name
                    $aHash.'#text' += $child.'#text'
                    $oHash.$childname += $aHash
                }
                else {
                    #phew, just a simple text attribute. 
                    $oHash.$childname += $child.FirstChild.InnerText
                }
            }
            elseif ($null -ne $child.'#cdata-section') {
                # if it is a data section, a block of text that isnt parsed by the parser,
                # but is otherwise recognized as markup
                write-verbose "cdata section";
                $oHash.$childname = $child.'#cdata-section'
            }
            elseif ($child.ChildNodes.Count -gt 1 -and ($child | Get-Member -MemberType Property).Count -eq 1) {
                $oHash.$childname = @()
                foreach ($grandchild in $child.ChildNodes) {
                    $oHash.$childname += (ConvertFrom-XML $grandchild)
                }
            }
            else {
                # create an array as a value  to the hashtable element
                $oHash.$childname += (ConvertFrom-XML $child)
            }
        }
        $oHash
    }
}

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

# Calculating padding to display for the podcasts found.
function displayPodcastsFeeds() {
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

function Get-All-Podcast-Episodes-XML() {
    param (
        [Parameter(Mandatory = $true)]
        [string] $URI
    )
    [XML] (Invoke-WebRequest -Uri $URI).Content
}

function Convert-XML-To-HashList() {
    param (
        [Parameter(Mandatory = $true)]
        [XML] $Xml
    )
    $table = @()
    try {
        $Xml.rss.channel.item | ForEach-Object { # order preserved
            #  ConvertFrom-XML leaves '#text' keys; duplicates also found.
            #  Formating to eliminate '#text' keys and or duplicates.
            $tmp = Format-Episode -Episode $($_ | ConvertFrom-XML)
            $table += $($tmp)
        }
    }
    catch {
        throw "Failed to convert XML to List. $($_.ErrorDetails), $($_.ScriptStackTrace)."
    }
    $table
}
function Approve-String() {
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

function Format-Episode() {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Episode
    )
    if ($Episode.title.Count -eq 1 -and $Episode.title.Keys -notcontains '#text') {
    }
    elseif ($Episode.title.Keys -contains '#text' -and $Episode.title.Keys.Count -gt 1) {
        $tmp = $Episode.title[0].'#text'
        $Episode.title = $tmp
    }
    elseif ($Episode.title.Keys -contains '#text') {
        $tmp = $Episode.title.'#text'
        $Episode.title = $tmp
    }
    elseif ($Episode.title.Count -ne 1 -and $Episode.title.GetType() -ne [string]) {
        throw "Unexpected episode title Key was found."
    }
    $Episode
}

function Get-Podcast-Episode-List() {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [String] $File
    )
    [array] $(Get-Content -Path $File | ConvertFrom-Json -AsHashtable)
}

function Get-Last-Write-Time() {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [String] $File
    )
    $(Get-ChildItem -Path $File | Select-Object -Property LastWriteTime).LastWriteTime
}

function Write-Episodes-To-Json() {
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
function Update-Episodes() {
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
    $episodesFile = "$podcastTitle.json"
    # Check if episodes file exists.
    if ( ( Test-Path -Path "$episodesFile" -PathType Leaf ) ) {
        $episodesLocal = Get-Podcast-Episode-List -File $episodesFile
        if ("null" -eq $episodesLocal) {
            throw "File provided contained 'null'. Delete '$episodesFile' and try again."
        }
        # Check if last updated greater than last checked.
        $lastWriteTimeDifference = $(Get-Date) - $(Get-Last-Write-Time -File $episodesFile)
        $hoursSinceLastWritten = $lastWriteTimeDifference.Hours
        if ( $hoursSinceLastWritten -ge $hoursToCheckAgain -or $Force ) {
            write-host "Checking '$($Podcast.title)' for new episodes ..."
            $episodesLatest = Convert-XML-To-HashList -Xml $(Get-All-Podcast-Episodes-XML -URI $Podcast.url)
            if ( $episodesLatest[0].title -ne $episodesLocal[0].title ) {
                # Save the latest episodes as the new baseline.
                Write-Episodes-To-Json $episodesLatest -File $episodesFile
                return $episodesLatest
            }
        }
    }
    else {
        Write-Host "Selected '$($Podcast.title)'. Performing first time episode gathering ..."
        Write-Episodes-To-Json -Episodes $(Convert-XML-To-HashList -Xml $(Get-All-Podcast-Episodes-XML -URI $Podcast.url)) -File $episodesFile
    }
    $(Get-Podcast-Episode-List -File $episodesFile)
}

# Writing console output for episodes, specifically: index | episode-title | publication date
function Write-Episodes() {
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
function Find-Episode() {
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
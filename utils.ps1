function Write-Host-Welcome() {
    param(
        # Parameter help description.
        [Parameter(Mandatory = $true)]
        [string] $Message,
        # Delimiter to encase around message.
        [ValidateScript( {$_.length -eq 1} )]
        [string] $delimiter = ' '
    )
    $ruler = $delimiter*[Console]::BufferWidth
    $split = ($ruler.Length - $Message.Length)/2
    $spacer = $delimiter*$split
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
    $rw = "_"*$($r.Length)
    $Podcasts | ForEach-Object {
        if ( $Podcasts.indexof($_) % 2) { # Alternating for visual cue.
            $host.UI.RawUI.ForegroundColor = 'DarkGreen'
            $([string]$Podcasts.indexof($_)).padleft($indexPadding) +
            " " + $([string]$_.title).PadLeft($titlePadding) +
            " " + $([string]$_.author).PadLeft($authorPadding) +
            " " + $([string]$_.url).PadLeft($urlPadding)
        }
        else {
            $host.UI.RawUI.ForegroundColor = $origBgColor
            $([string]$Podcasts.indexof($_)).padleft($indexPadding) +
            " " + $([string]$_.title).PadLeft($titlePadding).Replace($r,$rw) +
            " " + $([string]$_.author).PadLeft($authorPadding).Replace($r,$rw) +
            " " + $([string]$_.url).PadLeft($urlPadding).Replace($r,$rw)
        }
    }
    $host.UI.RawUI.ForegroundColor = $origBgColor
}
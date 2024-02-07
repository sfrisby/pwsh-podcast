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

function Get-PodcastEpisodes {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$URI
    )
    $table = @()
    $feed = Invoke-WebRequest -Uri $URI
    $xml = [XML] $feed.Content
    if ($null -ne $xml.rss.channel.author && $null -ne $xml.rss.channel.item) {
        try {
            # TODO resolve '#text' as a key for many items (via ConvertFrom-XML); duplicate key for identical entries as well.
            $xml.rss.channel.item | ForEach-Object { # order preserved
                $table += $($_ | ConvertFrom-XML)
            }
        }
        catch {
            Write-Host $_.ScriptStackTrace
            throw "Failed to convert from XML."
        }
    }
    else {
        Throw "Unexpected XML format."
    }
    $table
}

function Get-PodcastEpisode {
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

function SanitizeString() {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$ToSanitize,
        $Invalid = $([System.IO.Path]::GetInvalidFileNameChars() -join '')
    )
    $ToSanitize.ToCharArray() | ForEach-Object {
        if ($Invalid -match $_) {
            $ToSanitize = $ToSanitize.replace("$_", "")
            write-host "Sanitized '$_' from podcast title."
        }
    }
    $ToSanitize
}

$Podcasts = @( 
    "npr politics",
    "pbs newshour",
    "stuff you should know",
    "madigan's pubcast",
    "last podcast on the left",
    "open to debate",
    "science vs"
)
$Podcasts | ForEach-Object {
    $([string]$Podcasts.indexof($_) + " - " + $_)
}

$search = ""
$choice = Read-Host "Provide a number or search for a podcast"
try {
    $search = $Podcasts[[int]::Parse($choice)]
}
catch [System.FormatException] {
    $search = $choice
}
catch [System.Exception] {
    throw $_
}
Write-Host "Searching for '$search' podcasts ..."
$results = Invoke-CastosPodcastSearch -Podcast $search
if ($results.Count -eq 0) {
    throw [System.RankException] "No podcasts were found using the term '$search'."
}
elseif ($results.Count -eq 1) {
    write-host "Only one podcast was found:"
    $results[0]
}
else {
    # Calculating necessary padding to display the podcasts found.
    $extraPadding = 2
    $titlePadding = $($($($results.title) | ForEach-Object { $_.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $urlPadding = $($($($results.url) | ForEach-Object { $_.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $indexPadding = $results.Count.ToString().Length
    $results | ForEach-Object { # Creating console output: index  title  url
        $($results.indexof($_)).tostring().padleft($indexPadding) + 
        " " + $($_.title).padleft($titlePadding) + 
        " " + $($_.url).PadLeft($urlPadding) 
    }
}


# Obtain desired podcast or return results if there is only 1 result.
$podcast = ""
if ($results.Count -eq 1) {
    Write-Host "Gathering '$($results[0].title)' episodes ..."
    $podcast = $results[0]
}
else {
    $choice = read-host -prompt "Select podcast by number: "
    try {
        $podcast = $results[[int]::Parse($choice)]
    }
    catch {
        throw $_
    }
    Write-Host "Selected '$($podcast.title)'. Gathering episodes ..."
}
$episodes = Get-PodcastEpisodes -URI $podcast.url


# Duplicates coming from XML conversion, silly XML object nonsense.
# Attempting to elliminate title duplicates to prevent padding issues.
if ($episodes.title.Count -gt 1) {
    $episodes | ForEach-Object {
        if ($_.title.Keys -contains '#text') {
            $tmp = $_.title[0].'#text'
            $_.title = $tmp
        }
        elseif ($_.title.Count -eq 1 -and $_.title.GetType() -eq [string]) {
            # just ignore since there is only 1?
        }
        else {
            throw "Unexpected Key for episode title was found."
        }
    }
}

# Calculating necessary padding to display the episodes found.
$episodesListedAmount = 8
$episodeTitlePadding = $($($episodes.title | Select-Object -First $episodesListedAmount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum
$indexPadding = $episodes.Count.ToString().Length
$episodes | Select-Object -First $episodesListedAmount | ForEach-Object { # Creating console output: index  episode-title
    $($episodes.indexof($_)).tostring().padleft($indexPadding) + 
    " " + $($_.title).padleft($episodeTitlePadding)
}


$episode = ""
$choice = Read-Host -prompt "Select episode by number: "
try {
    $episode = $episodes[[int]::Parse($choice)]
    Write-Host "Episode selected was: '$($episode.title)'."
}
catch {
    Write-Host "Unknown exception has occurred."
    throw $_
}


$title = SanitizeString -ToSanitize $episode.title
$file = join-path (Get-location) "${title}.mp3"
$url = $episode.enclosure.url
Get-PodcastEpisode -URI $url -Path $file


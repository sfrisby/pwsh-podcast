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

. .\Invoke-CastosPodcastSearch.ps1

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

function SanitizeString() {
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

# Go straight to episodes when selecting a feed.
$settings = $(get-content -Path .\settings.json -Raw | ConvertFrom-Json)
$PODCASTS = @{}
$settings.podcast_feeds.psobject.properties | ForEach-Object {
    $PODCASTS[$_.Name] = $_.Value
} 

$PODCASTS.Keys | ForEach-Object {
    $([string]$($PODCASTS.Keys).indexof($_) + " - " + $_)
}

$isReadyForEpisodes = $false
$isReadyForPodcastSearch = $false

$search = ""
$results = ""
$podcast = @{
    'title' = "" 
    'url'   = ""
}
$choice = Read-Host "Provide a podcast number (above) to list its episodes or 's' for search mode"
try {
    $index = [int]::Parse($choice)
    $search = $index
    $isReadyForEpisodes = $true
}
catch [System.FormatException] {
    if ($choice -eq "s") {
        $isReadyForPodcastSearch = $true
        $choice = Read-Host "Enter the name of the podcast to search for"
    }
    $search = $choice
    Write-Host "Searching for '$search' podcasts ..."
    $results = Invoke-CastosPodcastSearch -Podcast $search
}

if ($results.Count -eq 0 -and $isReadyForPodcastSearch -and !$isReadyForEpisodes) {
    throw [System.RankException] "No podcasts were found using the term '$search'."
}
elseif ($results.Count -eq 1 -and $isReadyForPodcastSearch -and !$isReadyForEpisodes) {
    write-host "Only one podcast was found"
    $results[0]
    $podcast.title = $results[0].title
    $podcast.url = $results[0].url
}
elseif ($isReadyForPodcastSearch -and !$isReadyForEpisodes ) {
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
    try {
        $choice = read-host -prompt "Select podcast by number (above)"
        $index = [int]::Parse($choice)
        $podcast = $results[$index]
    }
    catch [System.FormatException] {
        throw "A number was not provided. Unable to proceede."
    }
}

# Only execute if a search was not performed.
if ($isReadyForEpisodes -and !$isReadyForPodcastSearch) {
    $podcast.title = $($PODCASTS.Keys)[$search]
    $podcast.url = $($PODCASTS.Values)[$search]
}

Write-Host "Selected '$($podcast.title)'. Gathering episodes ..."
$episodes = Get-PodcastEpisodes -URI $podcast.url

# Duplicates coming from XML conversion, silly XML object nonsense.
# Attempting to elliminate title duplicates to prevent padding issues.
$episodes | ForEach-Object {
    if ($_.title.Count -eq 1 -and $_.title.Keys -notcontains '#text') {
        # Desired and expected - just continue
    }
    elseif ($_.title.Keys -contains '#text' -and $_.title.Keys.Count -gt 1) {
        $tmp = $_.title[0].'#text'
        $_.title = $tmp
    }
    elseif ($_.title.Keys -contains '#text') {
        $tmp = $_.title.'#text'
        $_.title = $tmp
    }
    elseif ($_.title.Count -ne 1 -and $_.title.GetType() -ne [string]) {
        throw "Unexpected episode title Key was found."
    }
}


# Calculating necessary padding to display the episodes found.
# TODO needs option to list all episodes
$episodeExtraPadding = 3
$episodesListedAmount = 8
$episodeTitlePadding = $($($episodes.title | Select-Object -First $episodesListedAmount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum
$episodePubDatePadding = $($($episodes.pubDate | Select-Object -First $episodesListedAmount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum + $episodeExtraPadding
$indexPadding = $episodes.Count.ToString().Length
$episodes | Select-Object -First $episodesListedAmount | ForEach-Object { # Creating console output: index  episode-title  date
    $($episodes.indexof($_)).tostring().padleft($indexPadding) + 
    " | " + $($_.title).padleft($episodeTitlePadding) +
    " | " + $($_.pubDate.Values).padleft($episodePubDatePadding)
}
$choice = Read-Host -prompt "Select episode by number"
try {
    $episode = $episodes[[int]::Parse($choice)]
    Write-Host "Episode selected was: '$($episode.title)'."
}
catch [System.FormatException] {
    throw "A number was not provided. Unable to proceede."
}

$title = SanitizeString -ToSanitize $episode.title
$file = join-path (Get-location) "${title}.mp3"
$url = $episode.enclosure.url
Get-PodcastEpisode -URI $url -Path $file


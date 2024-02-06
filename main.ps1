. .\ConvertFrom-XML.ps1 # Required for ConvertFrom-XML function.

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

function Get-PodcastEpisodesByUri {
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

function DownloadPodcastByURI {
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

$Podcasts = @{
    npr_politics     = "npr politics"
    pbs_newshour     = "pbs newshour"
    stuff_u_s_know   = "stuff you should know"
    madigans_pubcast = "madigan's pubcast"
    last_p_o_t_l     = "last podcast on the left"
    open_to_debate   = "open to debate"
}
# TODO take user input ~ $search = Read-Host "Search for podcast by name: "
#$search = $Podcasts.pbs_newshour
$search = $Podcasts.npr_politics
$found = Invoke-CastosPodcastSearch -Podcast $search


# Calculating necessary padding to display the podcasts found.
$extraPadding = 2
$titlePadding = $($($($found.title) | ForEach-Object { $_.length }) | Measure-Object -Maximum).Maximum + $extraPadding
$urlPadding = $($($($found.url) | ForEach-Object { $_.length }) | Measure-Object -Maximum).Maximum + $extraPadding
$indexPadding = $found.Count.ToString().Length
$found | ForEach-Object { # Creating console output: index  title  url
    $($found.indexof($_)).tostring().padleft($indexPadding) + 
    " " + $($_.title).padleft($titlePadding) + 
    " " + $($_.url).PadLeft($urlPadding) 
}


# TODO take user input ~ $podcast = read-host -prompt "Select podcast by number: "
$podcast = $found[0]
Write-Host "Selected '$($podcast.title)'. Gathering episodes ..."
$episodes = Get-PodcastEpisodesByUri -URI $podcast.url


# Duplicates in the title bork the padding
if ($episodes.title.Count -gt 1) {
    $episodes | ForEach-Object {
        if ($_.title.Keys -contains '#text') {
            $tmp = $_.title[0].'#text'
            $_.title = $tmp
        } else {
            throw "Unexpected Key for episode title was found."
        }
    }
}

# Calculating necessary padding to display the episodes found.
$episodesListedAmount = 5
$episodeTitlePadding = $($($episodes.title | Select-Object -First $episodesListedAmount) | ForEach-Object { $_.length } | Measure-Object -Maximum).Maximum
$indexPadding = $episodes.Count.ToString().Length
$episodes | Select-Object -First $episodesListedAmount | ForEach-Object { # Creating console output: index  episode-title
    $($episodes.indexof($_)).tostring().padleft($indexPadding) + 
    " " + $($_.title).padleft($episodeTitlePadding)
}


# TODO take user input ~ episode = Read-Host -prompt "Select episode by number: "
$episode = $episodes[0]
Write-Host "Episode selected was: '$($episode.title)'."
$title = SanitizeString -ToSanitize $episode.title
$file = join-path (Get-location) "${title}.mp3"
$url = $episode.enclosure.url
DownloadPodcastByURI -URI $url -Path $file


<#
.SYNOPSIS
Ensure the string provided may be used as a file name.
#>
function Approve-String {
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ ($null -ne $_) -and ($_.length -gt 0) })]
        [string]$ToSanitize
    )
    [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object { 
        $tmp = $ToSanitize.replace("$_", "")
        if ($tmp.Length -lt $ToSanitize.Length) {
            Write-Verbose "Stripping '${_}' from $ToSanitize"
            $ToSanitize = $tmp
        }
    }
    $ToSanitize
}

<#
.SYNOPSIS
Return a collection of episodes from the provided WebResponseObject.
.DESCRIPTION
Using content response data, convert it from XML to a hashtable.
.NOTES
Overwrites any duplicate keys to the latest identified value. 
Inspired from https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1
#>
function ConvertFrom-PodcastWebRequestContent {
    param
    (
        [Parameter(Mandatory)]
        [ValidateScript({ $null -ne $_ })]
        [Microsoft.PowerShell.Commands.WebResponseObject] $Request
    )
    $episodes = @()
    $C = [XML] $Request.Content
    $C.rss.channel.item | ForEach-Object {
        $tmp = @{}
        $_.ChildNodes | ForEach-Object {
            # Check ChildNodes Existance; Overwrites duplicate keys!
            if ($_.ChildNodes.Count) {
                $tmp[$_.LocalName] = $_.InnerText
            }
            # Checks Attributes Existance; Overwrites duplicate keys!
            if ($_.Attributes.Count) { 
                $att = @{}
                $_.Attributes | ForEach-Object {
                    $att[$_.LocalName] = $_.'#text'
                }
                $tmp[$_.LocalName] = $att
            }
        }
        $episodes += @($tmp)
    }
    $episodes
}

<#
.SYNOPSIS
Query Castos podcast search for the provided string.
.NOTES
Retrieved via browser developer tools.

Output contains 'success' and 'data' fields. Podcasts are contained in 'data' which is an array of PSCustomObjects [as of 240423].
When no feeds are found then 'data' will be 'No feeds found.'
#>
function Invoke-CastosPodcastSearch {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
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
    
    if ( $response.StatusCode -ne 200 ) {
        throw "Response code was: $($response.StatusCode) | $($response.StatusDescription)."
    }

    if ( $null -eq $response.Content ) {
        throw "Response did not contain any content."
    }

    return $response.Content | ConvertFrom-Json
}

<#
.SYNOPSIS 
Perform a web request for the provided URI.

.NOTES
Attempted 'catch [System.Net.Http.HttpRequestException] {' but was unreliable.

Would be best to Convert System.Net.Http.HttpResponseMessage (via exception) to 
Microsoft.PowerShell.Commands.WebResponseObject (for XML) but unable to find a 
viable solution. If necessary, wrap method call within custom try-catch block.

When a feed is being updated it may be unresponsive causing failures.
I have yet to find a reliable solution for overcoming these rare instances.
#>
function Invoke-PodcastFeed {
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ ($null -ne $_) -and ( $_.length -gt 0 ) })]
        [string] $URI
    )
    Invoke-WebRequest -Uri $URI -Method Get -ContentType "application/json"
}

<#
.SYNOPSIS
Download URL to specified or generated temporary path.
.DESCRIPTION
When no path is provided the download file will go to a temporary file.

The file path is returned.
#>
function Invoke-Download {
    param (
        [Parameter(Mandatory)]
        [string] $URI,
        [Parameter()]
        [ValidateScript({ (Test-Path -Path $_ -PathType Leaf -IsValid) -and ($_.Name -notmatch [System.IO.Path]::GetInvalidFileNameChars()) })]
        [string] $File = [System.IO.Path]::GetTempFileName()
    ) 
    Invoke-WebRequest -Uri $URI -OutFile $File
    $File
}

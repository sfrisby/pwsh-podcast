<#
    
    .SYNOPSIS

    Obtain podcast search results for the provided podcast title.

    .PARAMETER Title

    Name of the podcast to search for via web request.

    .NOTES

    '\u2019' is replaced with a single quote in response content prior to JSON conversion to prevent fat quotes, i.e. '’', from appearing.

    .EXAMPLE

    . '<PATH>\search_podcasts.ps1' -Title "npr"

    .OUTPUTS

    A hashtable containing: 'query' for the term provided, 'response' for the web request info, and 'data' for podcast content.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
    [string]
    $Title
)
begin {
    function Invoke-PodcastSearch {
        param (
            [Parameter()]
            [string]$Boundary = "----WebKitFormBoundary$(Get-Date -Format yyyyMMddHHmmssfff)",
            [Parameter()]
            [string]$Linebreak = "$([char]13)$([char]10)"
        )
        $wrs = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $wrs.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
        Invoke-WebRequest -UseBasicParsing -Uri "https://castos.com/wp-admin/admin-ajax.php" `
            -Method "POST" `
            -WebSession $wrs `
            -Headers @{
            "authority"       = "castos.com"
            "method"          = "POST"
            "path"            = "/wp-admin/admin-ajax.php"
            "scheme"          = "https"
            "accept"          = "*/*"
            "accept-encoding" = "gzip, deflate, br, zstd"
            "accept-language" = "en-US,en;q=0.7"
            "cache-control"   = "no-cache"
            "origin"          = "https://castos.com"
            "pragma"          = "no-cache"
            "referer"         = "https://castos.com/tools/find-podcast-rss-feed/"
            "sec-fetch-mode"  = "same-origin"
            "sec-fetch-site"  = "same-origin"
            "sec-gpc"         = "0"
        } `
            -ContentType "multipart/form-data; boundary=$Boundary" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes("--$Boundary$($Linebreak)Content-Disposition: form-data; name=`"search`"$($Linebreak)$($Linebreak)$Title$($Linebreak)--$Boundary$($Linebreak)Content-Disposition: form-data; name=`"action`"$($Linebreak)$($Linebreak)feed_url_lookup_search$($Linebreak)--$Boundary--$($Linebreak)"))
    }
}
process {
    $response = Invoke-PodcastSearch
    $data = ($response.Content -replace "\\u2019", "`'"  | ConvertFrom-Json).data
}
end {
    return @{ query = $Title; response = $response; data = $data; }
}
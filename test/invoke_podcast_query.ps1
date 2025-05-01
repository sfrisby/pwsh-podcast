<#

.SYNOPSIS

Podcast web request via https://castos.com/.

.NOTES

Concept obtained from Chrome DevTools script generator from https://castos.com/tools/find-podcast-rss-feed/.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
    [string] $Query,
    [Parameter()]
    [string]$Boundary = "----WebKitFormBoundary$(Get-Date -Format yyyyMMddHHmmssfff)",
    [Parameter()]
    [string]$Linebreak = "$([char]13)$([char]10)"
)
begin {
    $wrs = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $wrs.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
}
process {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "https://castos.com/wp-admin/admin-ajax.php" `
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
        -Body ([System.Text.Encoding]::UTF8.GetBytes("--$Boundary$($Linebreak)Content-Disposition: form-data; name=`"search`"$($Linebreak)$($Linebreak)$Query$($Linebreak)--$Boundary$($Linebreak)Content-Disposition: form-data; name=`"action`"$($Linebreak)$($Linebreak)feed_url_lookup_search$($Linebreak)--$Boundary--$($Linebreak)"))
}
end {
    return $r
}
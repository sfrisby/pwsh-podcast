function confirm_leaf {
    param (
        [parameter(Mandatory, Position = 0)]
        [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
        [string] $f
    )
    Test-Path -Path $f -PathType Leaf
}
function confirm_container {
    param (
        [parameter(Mandatory, Position = 0)]
        [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
        [string] $c
    )
    Test-Path -Path $c -PathType Container
}
<#
    
.SYNOPSIS

Create provided directory container IFF does not exist.

#>
function save_container {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ ![string]::IsNullOrEmpty($_) -and (Test-Path -Path $_ -IsValid) })]
        [string] $c
    )
    if (!(confirm_container $c)) {
        New-Item -Path $c -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
}
<#

.SYNOPSIS

Strip invalid system characters from provided string.

.NOTES

Replaces spaces with single underscore and multiple underscores with single underscore.

#>
function get_valid_system_chars {
    param (
        [parameter(Mandatory, Position = 0)]
        [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
        [string] $Text
    )
    $s = $Text
    [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object {
        $s = $s.replace("$($_)", ' ')
    }
    $s = $s.replace('$', ' ').replace('@', ' ').replace('-', ' ')
    $s = $s -replace '\s+', '_' -replace '_+', '_'
    $s
}
<#

.SYNOPSIS

Return web response (episodes) from the provided podcast.

.PARAMETER Podcast

Podcast of interest; expecting 'url' member.

.NOTES

The response may be converted to XML simply by type casting: [xml] $r.

#>
function invoke_podcast_url {
    param (
        [Parameter(Mandatory, Position = 0 )]
        [ValidateScript({ $null -ne $_ -and ![string]::IsNullOrEmpty($_.url) -and [uri]::IsWellFormedUriString($_.url, 'Absolute') })]
        [pscustomobject]
        $Podcast
    )
    $r = Invoke-WebRequest -Uri $Podcast.url -Method Get -ContentType "application/json"
    $r
}
<#

.SYNOPSIS

Format web response content from podcast feed.

.PARAMETER Response

Output from invoke_podcast_url.

.OUTPUTS

Content with the following replaced:
    - '&rsquo' is replaced with a single quote prior to XML conversion to prevent fat quote '’' insertion.
    - '&#8211;' is replaced with a hyphen.

#>
function format_podcast_url {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ ![string]::IsNullOrEmpty($_.Content ) })]
        [Microsoft.PowerShell.Commands.WebResponseObject] $Response
    )
    $c = $Response.Content -replace '&rsquo;', "'" -replace '&#8211;', "-"
    $c
}
<#

.SYNOPSIS

Parse episodes from web response content.

.PARAMETER Content

The episodes content from the web request; type cast to [xml].

.DESCRIPTION

If a localname for the child node is found then a search for its innertext 
is performed. If no innertext then attributes are searched for. If no 
attributes or innertext are found then the localname child node is ignored.

Innertext is formatted to prevent appearance of unwanted characters.

Duplicate localname members  will be overwritten by the last provided.

Inspired from https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1

.OUTPUTS

Array of hashtables for each podcast episode (if any).

#>
function format_podcast_content {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
        [string] $Content
    )
    begin {
        function format {
            param( 
                [Parameter(Mandatory, Position = 0)] 
                [ValidateScript({ $null -ne $_ })]
                [string] $Text
            )
            $tmp = $Text -replace "’", "'"
            $tmp = [System.Web.HttpUtility]::HtmlDecode($tmp)
            return $tmp
        }
    }
    process {
        $episodes = @()
    ([xml] $Content).rss.channel.item | ForEach-Object {
            $item = @{}
            $_.get_childnodes() | ForEach-Object {
                if (![string]::IsNullOrEmpty($_.get_localname())) {
                    if (![string]::IsNullOrEmpty($_.get_innertext())) {
                        $item[$_.get_localname()] = $(format $($_.get_innertext()))
                    }
                    elseif ($_.get_attributes().count -gt 0) {
                        $a = @{}
                        $_.get_attributes() | ForEach-Object {
                            $a[$_.get_localname()] = $(format $($_.get_innertext()))
                        }
                        $item[$_.get_localname()] = $a
                    }
                }
            }
            $episodes += @($item)
        }
    }
    end {
        return $episodes
    }
}
<#

.SYNOPSIS

Obtain podcast episodes.

.PARAMETER Podcast

Podcast (containing all properties) object. 

The 'url' property (URL/URI) is used for the RSS feed.

.EXAMPLE

Saving episodes as JSON:
    > $e = .\get_episodes -Podcast $podcast.data[#]
    > $e.episodes | ConvertTo-Json -depth 6 | Out-File -Path <PATH>

Reading the data back into memory:
    > Get-Content -Path <PATH> | ConvertFrom-Json -depth 6
Remember that type will be [pscustomobject]!

As of v7.3, using -asHashTable returns type OrderedHashtable:
[System.Management.Automation.OrderedHashtable] 
(https://github.com/MicrosoftDocs/PowerShell-Docs/issues/9039)

.OUTPUTS

A hashtable with the keys 'episodes' for the episodes of the provided podcast, 
'response' for the web request info, 'content' containing the formatted web 
response content, and 'podcast' which was the provided podcast.

#>
function invoke_podcast_episodes {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ $null -ne $_ -and $_.keys -contains 'author' -contains 'description' -contains 'image' -contains 'title' -contains 'url' })]
        [hashtable] $Podcast
    )
    begin {
        $r = invoke_podcast_url $Podcast
        $c = format_podcast_url $r
        $e = format_podcast_content $c
    }
    process {
        $o = @{ episodes = $e; response = $r; content = $c; podcast = $Podcast }
    }
    end {
        return $o
    }
}
<#

.SYNOPSIS

Podcast web request via https://castos.com/.

.NOTES

Concept obtained from Chrome DevTools script generator from https://castos.com/tools/find-podcast-rss-feed/.

#>
function invoke_podcast_query {
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
}
<#
    
.SYNOPSIS

Format podcast response for simpler indexing.

.PARAMETER Response

Output from invoke_podcast_query.

.DESCRIPTION

The following are formatted:
    - '\u2019' is replaced with a single quote prior to JSON conversion to prevent fat quote '’' insertion.

.OUTPUTS

Multiple podcasts stored within object[] array while elements are single podcast [pscustomobject].

If only one podcast is found then type will be [pscustomobject]

Convert element to ordered hashtable:
<ELEMENT> | convertto-json | convertfrom-json -ashashtable

#>
function format_podcast_query {
    param (
        [Parameter(Mandatory, Position = 0)]
        [Microsoft.PowerShell.Commands.WebResponseObject] $Response
    )
    $c = $Response.Content -replace '\u2019', "'"
    $p = ($c | ConvertFrom-Json -Depth 6).data
    $p
}
<#

.SYNOPSIS

Web request to search for related podcast(s) information for the provided query.

.OUTPUTS

A hashtable containing the keys 'query' for the term provided, 'response' for the web request info, and 'podcasts' for podcast content.

Podcast members contain 'title', 'url', 'description', 'author', and 'image'.

.PARAMETER Query

Search term for the podcast(s).

.EXAMPLE

invoke_podcasts <QUERY>

#>
function invoke_podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string] $Query
    )
    $r = invoke_podcast_query $Query
    $p = format_podcast_query $r
    $o = @{ query = $Query; response = $r; podcasts = $p; }
    $o
}
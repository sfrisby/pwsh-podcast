<#

.SYNOPSIS

Provides podcast(s) information for the provided query.

.OUTPUTS

A hashtable containing the keys 'query' for the term provided, 'response' for the web request info, and 'podcasts' for podcast content.

Podcasts members contain 'title', 'url', 'description', 'author', and 'image'.

.PARAMETER Query

Search term for the podcast(s).

.EXAMPLE

.\test\get_podcasts_hashtable.ps1 <QUERY>

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string] $Query
)
begin {
    $r = .\test\invoke_podcast_query.ps1 $Query
    $p = .\test\format_podcast_query.ps1 $r
}
process {
    $o = @{ query = $Query; response = $r; podcasts = $p; }
}
end {
    return $o
}
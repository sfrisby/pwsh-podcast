<#

.SYNOPSIS

Return web response (episodes (if any)) from the provided podcast.

.PARAMETER Podcast

Podcast of interest; expecting 'url' member.

.EXAMPLE

$q = .\test\get_podcasts_hashtable.ps1 <QUERY>
.\test\invoke_podcast_url.ps1 $q.podcasts[#]
                                          \
                                           `- shown using: .\test\show_podcasts.ps1 $q.podcasts

.NOTES

The response may be converted to XML simply by type casting: [xml] $r.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $null -ne $_ -and ![string]::IsNullOrEmpty($_.url) -and [uri]::IsWellFormedUriString($_.url, 'Absolute') })]
    [pscustomobject]
    $Podcast
)
begin { }
process {
    $r = Invoke-WebRequest -Uri $Podcast.url -Method Get -ContentType "application/json"
}
end { 
    return $r
}

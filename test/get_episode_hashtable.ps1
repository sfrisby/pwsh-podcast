<#

.SYNOPSIS

Provides podcast(s) information for the provided query.

.PARAMETER Podcast

Podcast of interest for its episodes.

.EXAMPLE

.\test\get_episode_hashtable.ps1 <PODCAST>

.OUTPUTS

A hashtable with the keys 'episodes' for the episodes of the provided podcast, 'response' for the web request info, and 'content' containing the formatted web response content.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ $null -ne $_ -and $_ -match 'author' -and $_ -match 'description' -and $_ -match 'image' -and $_ -match 'title' -and $_ -match 'url' })]
    [pscustomobject] $Podcast
)
begin {
    $r = .\test\invoke_podcast_url.ps1 $Podcast
    $c = .\test\format_podcast_url.ps1 $r
    $e = .\test\format_podcast_content.ps1 $c
}
process {
    $o = @{ episodes = $e; response = $r; content = $c }
}
end {
    return $o
}
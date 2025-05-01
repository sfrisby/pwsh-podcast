<#

.SYNOPSIS

Format web response for podcast feed.

.PARAMETER Response

Output from invoke_podcast_url.

.OUTPUTS

Content with the following replaced:
    - '&rsquo' is replaced with a single quote prior to XML conversion to prevent fat quote '’' insertion.
    - '&#8211;' is replaced with a hyphen.

.EXAMPLE

.\test\format_podcast_url.ps1 <RESPONSE>

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [Microsoft.PowerShell.Commands.WebResponseObject] $Response
)
begin {}
process {
    $c = $Response.Content -replace "\&rsquo\;", "`'" -replace "\&#8211\;", "-"
}
end {
    return $c
}
<#
    
.SYNOPSIS

Format podcast response for simpler indexing.

.PARAMETER Response

Output from invoke_podcast_query.

.DESCRIPTION

The following are formatted:
    - '\u2019' is replaced with a single quote prior to JSON conversion to prevent fat quote '’' insertion.

.EXAMPLE

.\test\format_podcast_query.ps1 $(.\test\invoke_podcast_query.ps1 <QUERY>)

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [Microsoft.PowerShell.Commands.WebResponseObject] $Response
)
begin {}
process {
    $p = ($Response.Content -replace "\\u2019", "`'"  | ConvertFrom-Json).data
}
end {
    return $p
}
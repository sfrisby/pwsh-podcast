<#

    .SYNOPSIS

    Show compact results from podcast query.

    .PARAMETER Podcasts

    Output from format_podcast_query.

    .EXAMPLE

    $r = .\test\invoke_podcast_query <QUERY>
    $p = .\test\format_podcast_query $r
    .\test\show_podcasts.ps1 -Podcasts $p

    .EXAMPLE

    $h = .\test\get_podcasts_hashtables <QUERY>
    .\test\show_podcasts.ps1 -Podcasts $h.podcasts

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $null -ne $_ -and $_.count -gt 0 })]
    [object[]]
    $Podcasts
)
begin {}
process {
    $script:index = 0; 
    $Podcasts | select-Object -Property @{n = "#"; e = { ($script:index++) } }, author, title
}
end {}
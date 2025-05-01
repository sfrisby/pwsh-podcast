<#

    .SYNOPSIS

    Show compact results from podcast query or array.

    .PARAMETER Podcasts

    Output from format_podcast_query or podcasts file.

    .EXAMPLE

    $r = .\test\invoke_podcast_query <QUERY>
    $p = .\test\format_podcast_query $r
    .\test\show_podcasts.ps1 -Podcasts $p

    .EXAMPLE

    $q = .\test\get_podcasts_hashtables <QUERY>
    .\test\show_podcasts.ps1 -Podcasts $q.podcasts

    .EXAMPLE
    $p = get-content -path .\src\podcasts
    .\test\show_podcasts.ps1 -Podcasts $p

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $null -ne $_ -and $_.count -gt 0 -and ![string]::IsNullOrEmpty($_.author) -and ![string]::IsNullOrEmpty($_.title) })]
    [object[]]
    $Podcasts
)
begin {}
process {
    $script:index = 0; 
    $Podcasts | select-Object -Property @{n = "#"; e = { ($script:index++) } }, author, title
}
end {}
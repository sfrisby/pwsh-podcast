<#

.SYNOPSIS

Show compact episode information.

.EXAMPLE

$eps = .\test\invoke_rss -RSS $pod.url
.\test\show_episodes.ps1 -XML $([xml] $eps.Content)

$e = $([xml] $e.Content).rss.channel.item[#]

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ ![string]::IsNullOrEmpty($_.pubDate) -and ![string]::IsNullOrEmpty($_.title) })]
    [object[]] $Episodes,
    [Parameter()]
    [Int16] $First = 5
)
begin { }
process {
    $script:index = 0; 
    $Episodes | select-Object -Property `
    @{n = "item"; e = { ($script:index++) } }, `
    @{n = "date"; e = { ([datetime]$_.pubDate) } }, `
        title `
        -First $First
}
end { }

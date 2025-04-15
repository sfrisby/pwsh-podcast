[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $_.count -gt 0 -and ![string]::IsNullOrEmpty($_.title) })]
    [pscustomobject]
    $Podcast
)
begin {
    $config = Get-Content -Path (join-path $PSScriptRoot '..' 'config.json') | ConvertFrom-Json
}
process {
    $directory = Join-Path $config.podcasts $Podcast.title
    if (!(Test-Path -Path $directory -PathType Container)) {
        New-Item -ItemType Container -Path $directory -Force
    }
}
end {
    return $directory
}

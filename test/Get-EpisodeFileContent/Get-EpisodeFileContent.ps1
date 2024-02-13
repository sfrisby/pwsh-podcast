
<#
.SYNOPSIS
Read JSON file into memory as an array of OrderedHashtable elements.

.NOTES
The file is expected to have the '.json' extension.
#>
function Get-EpisodeFileContent {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [ValidateScript({$_ -like "*.json"})]
        [string] $File
    )
    [array]$(Get-Content -Path $File -Raw | ConvertFrom-Json -AsHashtable);
}
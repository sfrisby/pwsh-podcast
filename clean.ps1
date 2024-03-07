<#
.SYNOPSIS
Delete unwanted files through confirmation.

.EXAMPLE
.\clean.ps1 -MP3

.EXAMPLE
.\clean.ps1 -JSON Episodes
Removes episode JSON file lists.

.\clean.ps1 -JSON All
Removes all JSON files. Will likely have to rerun setup hence a confirmation is required.
#>

param(
    [Parameter(Mandatory = $false)] # Specify to delete all MP3 files.
    [switch] $MP3,
    [Parameter(Mandatory = $false)] # Specify to delete all JSON files.
    [ValidateSet("All", "Episodes")]
    [string] $JSON
)

. '.\include.ps1'

if ($MP3) {
    $(Get-ChildItem -Filter "*.mp3") | ForEach-Object {
        Remove-Item -Force $_
    }
}

switch ($JSON) {
    "All" {  
        $(Get-ChildItem -Filter "*.json") | ForEach-Object {
            Remove-Item $_ -Confirm
        }
    }
    "Episodes" {
        $(Get-ChildItem -Filter "$EPISODE_PREFIX*.json" ) | ForEach-Object {
            Remove-Item $_ -Confirm
        }
    }
    Default {}
}

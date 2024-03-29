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
    [Parameter(Mandatory = $false)] # Specify to delete all or just the episode JSON files.
    [ValidateSet("All", "Episodes")]
    [string] $JSON,
    [Parameter(Mandatory = $false)] # Specify to delete all Thumbnail resource files.
    [switch] $Thumbnails
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
        $(Get-ChildItem -Filter "$script:EPISODE_PREFIX*.json" ) | ForEach-Object {
            Remove-Item $_ -Confirm
        }
    }
    Default {}
}

if ($Thumbnails) {
    $(Get-ChildItem -Path '.\resource' -Filter "thumb_*.jpg") | ForEach-Object {
        Remove-Item -Force $_
    }
}
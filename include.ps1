<#
.SYNOPSIS
Congregating setup information to a single file for simpler access.
.NOTES
Change with caution!
#>

. '.\utils.ps1'

$CONFIG_FILE_NAME = "config.ini"
$setup = Get-Content -Path ".\$CONFIG_FILE_NAME" -Raw | ConvertFrom-StringData
$FEEDS_FILE = $setup.file_feeds
$EPISODE_PREFIX = $setup.prefix_episode_list
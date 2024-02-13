# Change with caution!
# May require re-running setup.
$CONFIG_FILE_NAME = "config.ini" 
$CONFIG_FILE_PREFIX = "prefix_config_file"

$d = "===>"
Write-Host "$d Performing Setup "

# Create default config file if it doesn't exist.
if ( !$(Test-Path -Path $CONFIG_FILE_NAME -PathType Leaf) ) {
    $setup = "# Change KEYS below with caution!`n"`
        + "file_feeds=feeds.json`n"`
        + "file_search=search.json`n"`
        + "prefix_episode_list=episodes_`n"`
        + "# Change PAIRS below with caution!`n"`
        + "$CONFIG_FILE_PREFIX=file_`n"`
        + "config_file=$CONFIG_FILE_NAME" # Note: RET added here automatically.
    $setup | Out-File -FilePath $CONFIG_FILE_NAME | Out-Null
    write-host "Created '$CONFIG_FILE_NAME'."
} elseif ( $(Test-Path -Path $CONFIG_FILE_NAME -PathType Leaf) ) {
    write-host "Reading configuration from: $CONFIG_FILE_NAME"
    # Create feeds and search data files if they don't exist.
    # Only those that match the term are desired.
    $pad = " " * 3
    $setup = Get-Content -Path ".\$CONFIG_FILE_NAME" -Raw | ConvertFrom-StringData
    $term = $setup[$setup.Keys -match $CONFIG_FILE_PREFIX]
    $setup.Keys -match $term | ForEach-Object {
        $tmp = $setup[$_]
        $file = ".\$tmp"
        if ( !$(Test-Path $file -PathType Leaf) ) {
            @() | ConvertTo-Json | Out-File -Path $file
            write-host "${pad}Created '$file'."
        }
        else {
            write-host "${pad}Not creating '$file' as it already exists."
        }
    }
}

Write-Host "$d Setup Complete"

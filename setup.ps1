. .\utils.ps1

try {
    Write-Host-Welcome -Message " ~ Performing Setup ~ "

    # Create default settings file if it doesn't exist.
    $settings_file = 'conf.json'
    if ( !$(Test-Path -Path $settings_file -PathType Leaf) ) {
        $settings = @{
            "file" = @{
                "search" = "search.json"
                "feeds"  = "feeds.json"
            }
        }
        $settings | ConvertTo-Json | Out-File -FilePath $settings_file
    }
    
    $settings = Get-Content -Path $settings_file -Raw | ConvertFrom-Json -AsHashtable
    
    # Create feeds and search data files if they don't exist.
    $settings.file.Keys | ForEach-Object {
        if ( !$(Test-Path $settings.file.$_ -PathType Leaf) ) {
            @() | ConvertTo-Json | Out-File -Path $settings.file.$_
            write-host "Created $_"
        }
    }
    
    Write-Host-Welcome -Message " Setup Complete "
}
catch {
    throw $_
}
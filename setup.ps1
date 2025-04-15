<#

.SYNOPSIS

Read and or setup powershell podcasts configuration.

#>
[CmdletBinding()]
param ()

begin {

    $podcasts = @{}
    $config = @{}

    function Set-Constants {
        try {
            try {
                Set-Variable -Name CONFIG_BASENAME -Value "config.json" -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'CONFIG_BASENAME' already set."
            }

            try {
                Set-Variable -Name CONFIG_FILEPATH -Value $(Join-Path $PSScriptRoot $CONFIG_BASENAME) -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'CONFIG_FILEPATH' already set."
            }
            
            try {
                Set-Variable -Name PODCAST_DIRECTORY_BASENAME -Value "psPodcasts" -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'PODCAST_DIRECTORY_BASENAME' already set."
            }

            try {
                Set-Variable -Name PODCAST_DIRECTORY_PATH -Value $(Join-Path $HOME $PODCAST_DIRECTORY_BASENAME) -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'PODCAST_DIRECTORY_PATH' already set."
            }

            try {
                Set-Variable -Name PODCAST_JSON_FILEPATH -Value $(Join-Path $PODCAST_DIRECTORY_PATH "podcasts.json" ) -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'PODCAST_JSON_FILEPATH' already set."
            }
        }
        catch {
            Write-Error "Unexpected exception occured during the setup of constant variables."
            throw $_
            exit 1
        }
    }
    
    function Resolve-ConfigJSON {
        if (-not (Test-Path -Path $CONFIG_FILEPATH -PathType Leaf)) {
            Save-DefaultConfig
        }
    }

    function Read-ConfigJSON {
        Get-Content $CONFIG_FILEPATH -ErrorAction Stop | Out-String | ConvertFrom-Json
    }
    
    function Save-DefaultConfig {
        New-Item -Path $CONFIG_FILEPATH -ItemType File -Value ($(.\.config.default.ps1) | Out-String) -ErrorAction Stop | Out-Null
    }
    
    function Save-ConfigJSON {
        Set-Content -Path $CONFIG_FILEPATH -Value ($config | ConvertTo-Json | Out-String) -ErrorAction Stop | Out-Null
    }

    function Resolve-VLC {
        if ([String]::IsNullOrEmpty($config.vlc)) {
            $search = @("C:\Program Files\VideoLAN\VLC\vlc.exe", "/usr/bin/vlc", "/snap/bin/vlc")
            foreach ($path in $search) {
                if (Test-Path -Path $path -PathType Leaf) {
                    $config.vlc = $path
                    break
                }
            }
            if ([String]::IsNullOrEmpty($config.vlc)) {
                Write-Warning "Unable to locate VLC executable. If desired, please manually provide the absolute path to the VLC executable within '$CONFIG_FILEPATH'."
            }
        }
    }

    function Resolve-TLS {
        if ([String]::IsNullOrEmpty($config.tls)) {
            $search = join-path $HOME "bin" "TagLibSharp.dll"
            if (Test-Path -Path $search -PathType Leaf) {
                $config.tls = $search
            }
            if ([String]::IsNullOrEmpty($config.tls)) {
                Write-Warning "Unable to locate TagLibSharp DLL. If desired, please manually provide the absolute path to the TagLibSharp DLL within '$CONFIG_FILEPATH'."
            }
        }
    }

    <#
    
    .SYNOPSIS

    Create provided directory IFF does not exist.

    #>
    function Save-PodcastsDirectory {
        param (
            [Parameter(Mandatory)]
            [ValidateScript({ ($null -ne $_) -and ($_.length -gt 0) })]
            [string] $Directory
        )
        try {
            if (-not (Test-Path -Path $Directory -PathType Container)) {
                New-Item -Path $Directory -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            Write-Error "Exception occurred during podcast directory setup."
            throw $_
            exit 1
        }
    }

    <#
    
    .SYNOPSIS
    
    Ensure specified directory is created or use the default.

    #>
    function Resolve-PodcastsDirectory {
        if ([String]::IsNullOrEmpty($config.podcasts)) {
            Save-PodcastsDirectory -Directory $PODCAST_DIRECTORY_PATH
            $config.podcasts = $PODCAST_DIRECTORY_PATH
        }
        else {
            if (-not (Test-Path -Path $config.podcasts -PathType Container)) {
                Write-Host "Podcasts directory '$($config.podcasts)' doesn't exist. Attempting to setup."
                Save-PodcastsDirectory -Directory $config.podcasts
                Write-Host "'$($config.podcasts)' setup complete."
            }
        }
    }

    <#
    
    .SYNOPSIS

    Convert 'rss.json' into new JSON file for podacsts.

    .NOTES

    Regenerate simply by deleting '<PODCAST_DIRECTORY_PATH>/podcasts.json' and ensuring 'rss.json' containing 
    podcast information is somewhere within the root project. The default for v1 was '<ROOT>/resource/rss.json' 
    but a recursive search is performed so it may be placed anywhere. 
    
    An empty JSON file will be created if no podcast information is found. This will be the new location for
    podcast inforamtion storage.

    #>
    function ConvertFrom-RSSv1 {
        $pods = @{}
        $deprecated = (Get-ChildItem -Recurse -Filter "rss.json").FullName
        if (-not [String]::IsNullOrEmpty($deprecated)) {
            foreach ($item in $(Get-Content $deprecated | Out-String | ConvertFrom-Json)) {
                $value = ConvertFrom-SearchPodcasts -Data $item
                $pods.Add($item.title, $value."$($item.title)")
            }
        }
        $pods
    }

    function Save-PodcastJSON {
        if (-not (Test-Path -Path $PODCAST_JSON_FILEPATH -PathType Leaf)) {
            $converted = ConvertFrom-RSSv1
            if ($converted.Keys.Count -gt 0) {
                New-Item -Path $PODCAST_JSON_FILEPATH -Value ($converted | ConvertTo-Json | Out-String) -Force -ErrorAction Stop | Out-Null
            }
            else {
                New-Item -Path $PODCAST_JSON_FILEPATH -Value ($(.\.config.podcasts.ps1) | ConvertTo-Json | Out-String) -Force -ErrorAction Stop | Out-Null
            }
        }
    }

    function Read-PodcastJSON {
        Get-Content $PODCAST_JSON_FILEPATH -ErrorAction Stop | Out-String | ConvertFrom-Json
    }

    function Repair-AllPodcastsDirectories {
        foreach ($podcastname in ($podcasts | Get-Member -MemberType NoteProperty).Name) {
            $storage = Join-Path $config.podcasts $podcastname
            Save-PodcastsDirectory -Directory $storage
        }
    }

    <#
    
    .SYNOPSIS
    
    Download image from $URL and save as $Path.

    #>
    function Invoke-ThumbnailDownload {
        param (
            [Parameter(Mandatory)]
            [ValidateScript({ -not [string]::IsNullOrEmpty($_) })]
            [string] $URL,
            [Parameter(Mandatory)]
            [ValidateScript({ -not [string]::IsNullOrEmpty($_) })]
            [string] $Path,
            [Parameter()]
            [ValidateRange(10, 3840)]
            [Int16] $Resolution = 250
        )
        try {
            $download = Invoke-Download -URI $URL
            $thumbnail = [System.Drawing.Image]::FromFile($download)
            $resize = New-Object System.Drawing.Bitmap($Resolution, $Resolution)
            $graphics = [System.Drawing.Graphics]::FromImage($resize)
            $graphics.DrawImage($thumbnail, 0, 0, $Resolution, $Resolution)
            $resize.Save($Path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        }
        catch {
            throw $_
        }
        finally {
            if ($thumbnail) { $thumbnail.Dispose() }
            if ($graphics) { $graphics.Dispose() }
            if ($resize) { $resize.Dispose() }
        }
    }

    function Format-Thumbnail {
        param(
            [Parameter(Mandatory)]
            [ValidateScript({ -not [string]::IsNullOrEmpty($_) })]
            [string] $Path,
            [Parameter()]
            [ValidateRange(10, 3840)]
            [Int16] $Resolution = 250
        )
        try {
            $resolve = Resolve-Path -Path $Path
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(17, 17, 17))
            $font = [System.Drawing.Font]::new("Arial", 24)
            $bitmap = [System.Drawing.Bitmap]::new($Resolution, $Resolution)
            $draw = [System.Drawing.Graphics]::FromImage($bitmap)
            $draw.FillRectangle($brush, 0, 0, $bitmap.Width, $bitmap.Height)
            $format = [System.Drawing.StringFormat]::new()
            $format.Alignment = [System.Drawing.StringAlignment]::Center
            $draw.DrawString($resolve.BaseName, $font, $brush, 0.5 * $bitmap.Width, 0.5 * $bitmap.Height, $format)
            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        }
        finally {
            if ($brush) { $brush.Dispose() }
            if ($font) { $font.Dispose() }
            if ($draw) { $draw.Dispose() }
        }
    }

    function Repair-AllPodcastsThumbnails {
        foreach ($podcastname in ($podcasts | Get-Member -MemberType NoteProperty).Name) {
            if ([string]::IsNullOrEmpty($podcasts.("$podcastname").image.url)) {
                # create an image for the podcast using the title
            }
            else {
                

                # search within the podcast folder for thumbnail
                if ([string]::IsNullOrEmpty( $podcasts.("$podcastname").image.local )) {
                    $foldersearch = Get-ChildItem -Path (Join-Path $config.podcasts $podcastname) -Filter "$($podcastname).jpg"
                    if (-not [String]::IsNullOrEmpty($foldersearch)) {
                        # update thumbnail path
                        $podcasts.("$podcastname").image.local = $foldersearch.FullName
                    }
                    else {
                        # search recursively in root script folder
                        $recursivesearch = Get-ChildItem -Recurse -Filter "$($podcastname).jpg"
                        if (-not [String]::IsNullOrEmpty($recursivesearch)) {
                            # copy to podcast folder & update thumbnail path
                            $destination = Join-Path $config.podcasts $podcastname $recursivesearch.Name
                            Copy-Item -Path $recursivesearch.FullName -Destination $destination -ErrorAction Stop | Out-Null
                            $podcasts.("$podcastname").image.local = $destination
                        }
                    }
                }
            }

            
        }
    }
}

process {
    Set-Constants

    Resolve-ConfigJSON

    $config = Read-ConfigJSON

    Resolve-VLC

    Resolve-TLS

    Resolve-PodcastsDirectory

    Save-PodcastJSON

    Save-ConfigJSON

    $podcasts = Read-PodcastJSON

    Repair-AllPodcastsDirectories

    Repair-AllPodcastsThumbnails
}

end {

    return @($podcasts, $config)

}

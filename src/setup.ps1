<#

.SYNOPSIS

Read and or setup powershell podcasts configuration.

.DESCRIPTION

Creates setup files and folders at the locations specified: 
file   | CONFIG_FILEPATH    ~ JSON configuration file path
file   | PODCASTS_FILEPATH  ~ JSON file containing previsouly saved podcasts
folder | LOCAL_PATH         ~ a folder where each podcast is individually saved

A new podcast file is generated that strips unwanted characters.
A recursive search is performed for the deprecated 'rss.json' file 
which contents is used for the new podcast file.

.NOTES

This script uses unremovable constant variables. Changing constants 
requires running the script from a new powershell instance. Even though 
they are set to local they become script scoped. Hopefully this is
changed in the near future.

TODO Investigate use of Start-Process or Invoke-Expression to start new instance each time to prevent constants nuisance.
TODO Start-Process pwsh -ArgumentList '-noexit -command <script>
TODO Invoke-Expression 'cmd /c start pwsh -Command <script>

To regenerate setup files they must first be manually deleted prior to 
executing the script from a new powershell instance.

#>
begin {
    . $PSScriptRoot\utilities.ps1

    Set-Variable -Name 'CONFIG_BASENAME'   -Value "config.json"                                    -Option Constant -Scope Local -ErrorAction stop
    Set-Variable -Name 'CONFIG_FILEPATH'   -Value $(Join-Path $PSScriptRoot ".." $CONFIG_BASENAME) -Option Constant -Scope Local -ErrorAction stop
    Set-Variable -Name 'LOCAL_BASENAME'    -Value ".pwshpodcasts"                                  -Option Constant -Scope Local -ErrorAction stop
    Set-Variable -Name 'LOCAL_PATH'        -Value $(Join-Path $HOME $LOCAL_BASENAME)               -Option Constant -Scope Local -ErrorAction stop
    Set-Variable -Name 'PODCASTS_BASENAME' -Value "podcasts"                                       -Option Constant -Scope Local -ErrorAction stop
    Set-Variable -Name 'PODCASTS_FILEPATH' -Value $(Join-Path $PSScriptRoot $PODCASTS_BASENAME)    -Option Constant -Scope Local -ErrorAction stop
    
    $podcasts = @()
    $config = @{}

    <#
    
    .SYNOPSIS

    Create the default config when nothing is provided or save the provided hashtable as config.

    #>
    function save_config {
        param (
            [Parameter()]
            [hashtable] $Config = @{}
        )
        if ($Config.Keys.Count -eq 0) {
            New-Item -Path $CONFIG_FILEPATH -ItemType File -Value ($(.$PSScriptRoot\.config.default.ps1) | Out-String) -ErrorAction Stop | Out-Null
        }
        else {
            Set-Content -Path $CONFIG_FILEPATH -Value ($Config | ConvertTo-Json | Out-String) -ErrorAction Stop | Out-Null
        }
    }
    function get_config {
        Get-Content $CONFIG_FILEPATH -ErrorAction Stop | Out-String | ConvertFrom-Json -AsHashtable
    }

    function resolve_VLC {
        if ([String]::IsNullOrEmpty($config.vlc)) {
            $search = @("C:\Program Files\VideoLAN\VLC\vlc.exe", "/usr/bin/vlc", "/snap/bin/vlc")
            foreach ($path in $search) {
                if (confirm_leaf $path) {
                    $config.vlc = $path
                    break
                }
            }
            if ([String]::IsNullOrEmpty($config.vlc)) {
                Write-Warning "Unable to locate VLC executable. If desired, please manually provide the absolute path to the VLC executable within '$CONFIG_FILEPATH'."
            }
        }
    }
    function resolve_TLS {
        if ([String]::IsNullOrEmpty($config.tls)) {
            $search = join-path $HOME "bin" "TagLibSharp.dll"
            if (confirm_leaf $search) {
                $config.tls = $search
            }
            if ([String]::IsNullOrEmpty($config.tls)) {
                Write-Warning "Unable to locate TagLibSharp DLL. If desired, please manually provide the absolute path to the TagLibSharp DLL within '$CONFIG_FILEPATH'."
            }
        }
    }

    function save_local {
        save_container $LOCAL_PATH
    }
    function confirm_local {
        if ($config.local -ne $LOCAL_PATH) {
            $config.local = $LOCAL_PATH
        }
        if (!(confirm_container $config.local)) {
            save_local
        }
    }
    <#
    
    .SYNOPSIS

    Convert 'rss.json' into new JSON file for podacsts.

    .NOTES

    Regenerate simply by deleting '<LOCAL_PATH>/podcasts.json' and ensuring 'rss.json' containing 
    podcast information is somewhere within the root project. The default for v1 was '<ROOT>/resource/rss.json' 
    but a recursive search is performed so it may be placed anywhere. 
    
    An empty JSON file will be created if no podcast information is found. This will be the new location for
    podcast inforamtion storage.

    #>
    function get_deprecated_rss {
        $podcasts = @()
        $rssjson = (Get-ChildItem -Recurse -Filter "rss.json").FullName
        if (![String]::IsNullOrEmpty($rssjson)) {
            $rsscontent = (Get-Content -Path $rssjson | ConvertFrom-Json -Depth 6)
            $rsscontent | ForEach-Object {
                $_.title = $_.title -replace "’", "'" -replace "\s+", " "
                $_.description = $_.description -replace "’", "'" -replace "–", "-" -replace " ", " " -replace "\s+", " "
                $podcasts += $_
            }
        }
        $podcasts
    }
    <#

    .SYNOPSIS

    Set podcast content if it exists otherwise combine old and new podcasts.

    #>
    function save_podcasts {
        param (
            [parameter(Position = 0)]
            [array] $Podcasts = @()
        )
        if (confirm_leaf $PODCASTS_FILEPATH) {
            if ($Podcasts.Count -gt 0) {
                Set-Content -Path $PODCASTS_FILEPATH -Value $($Podcasts | ConvertTo-Json -Depth 6) -Force -ErrorAction Stop | Out-Null
            }
        }
        else {
            $pastpodcasts = get_deprecated_rss
            $pastpodcasts | ForEach-Object {
                if (!($Podcasts.title -icontains $_.title)) {
                    $Podcasts += $_
                }
                New-Item -Path $PODCASTS_FILEPATH -Value $($Podcasts | ConvertTo-Json -Depth 6) -Force -ErrorAction Stop | Out-Null
            }
        } 
    }
    function get_podcasts {
        (Get-Content $PODCASTS_FILEPATH -ErrorAction Stop) | ConvertFrom-Json -Depth 6
    }

    function confirm_podcasts_containers {
        param (
            [parameter(Mandatory, Position = 0)]
            [ValidateScript({ $null -ne $_ -and $_.Count -gt 0 -and ![string]::IsNullOrEmpty($($_.title)) })]
            [array] $podcasts
        )
        $podcasts.title | ForEach-Object {
            $name = get_valid_system_chars $_
            $path = $(Join-Path $LOCAL_PATH $name)
            if (!(confirm_container $path)) {
                save_container $path
            }
        }
    }
    <#

    .SYNOPSIS

    Generate an image with the provided text.

    .PARAMETER Text

    Text written on the image.

    .PARAMETER Path

    Path where to save the image. Defaults to temporary path file.

    .OUTPUTS

    Path to the thumbnail, default is a temporary file.

    .NOTES

    Text longer than 10 characters has spaces changed to return lines.

    #>
    function format_thumbnail {
        param(
            [Parameter(Mandatory)]
            [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
            [string] $Text,
            [Parameter()]
            [ValidateScript({ (Test-Path -Path $_ -PathType Leaf -IsValid) })]
            [string] $Path = (Join-Path $([System.IO.Path]::GetTempFileName())),
            [Parameter()]
            [ValidateRange(10, 3840)]
            [Int16] $Resolution = 800
        )
        try {
            if ($Text.Length -gt 10) {
                $Text = $Text -replace " ", "`r`n"
            }
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(17, 17, 17))
            $foreground = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(157, 157, 157))
            $font = [System.Drawing.Font]::new("Consolas", 0.05 * $Resolution)
            $bitmap = [System.Drawing.Bitmap]::new($Resolution, $Resolution)
            $draw = [System.Drawing.Graphics]::FromImage($bitmap)
            $draw.FillRectangle($brush, 0, 0, $bitmap.Width, $bitmap.Height)
            $format = [System.Drawing.StringFormat]::new()
            $format.Alignment = [System.Drawing.StringAlignment]::Center
            $bounds = $draw.MeasureString($Text, $font)
            $widthoffset = $bitmap.Width * 0.5
            $heightoffset = ($bitmap.Height - $bounds.Height) * 0.5
            $draw.DrawString($Text, $font, $foreground, $widthoffset, $heightoffset, $format)
            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        }
        finally {
            if ($brush) { $brush.Dispose() }
            if ($font) { $font.Dispose() }
            if ($draw) { $draw.Dispose() }
        }
        $Path
    }
    <#
    
    .SYNOPSIS

    Download or generate a podcast thumbnail.

    #>
    function confirm_podcasts_image {
        param (
            [parameter(Mandatory, Position = 0)]
            [ValidateScript({ $null -ne $_ -and $_.Count -gt 0 -and ![string]::IsNullOrEmpty($($_.image)) })]
            [array] $podcasts
        )
        $podcasts | ForEach-Object {
            $title = get_valid_system_chars $_.title
            $thumbnail = $null -ne $_.thumbnail ? $_.thumbnail : $(Join-Path $LOCAL_PATH $title "$($title).jpg")
            if (!(confirm_leaf $thumbnail)) {
                if ([uri]::IsWellFormedUriString($_.image, 'Absolute')) {
                    $tmp = (Join-Path $([System.IO.Path]::GetTempPath()) $title)
                    Invoke-WebRequest -Uri $_.image -OutFile $tmp -ErrorAction Stop
                    Move-Item -Path $tmp -Destination $thumbnail -ErrorAction Stop
                }
                else {
                    # invalid uri so instead format thumbnail
                    $tmp = format_thumbnail -Text $_.title -ErrorAction Stop
                    Move-Item -Path $tmp -Destination $thumbnail -ErrorAction Stop
                }
            }
            # add or update thumbnail for podcast
            if (confirm_leaf $thumbnail) {
                if ($null -ne $_.thumbnail) {
                    $_.thumbnail = $thumbnail
                } else {
                    $_ | Add-Member -MemberType NoteProperty -Name 'thumbnail' -Value $thumbnail
                }
            }
        }
    }
}
process {
    if (!(confirm_leaf $CONFIG_FILEPATH)) {
        save_config # default; config template
    }
    $config = get_config
    confirm_local
    resolve_VLC
    resolve_TLS
    save_config $config
    if (!(confirm_leaf $PODCASTS_FILEPATH)) {
        save_podcasts # default; empty if missing 'rss.json'
    }
    $podcasts = get_podcasts
    confirm_podcasts_containers $podcasts
    confirm_podcasts_image $podcasts
    save_podcasts $podcasts
}
end {
    @($podcasts, $config)
}

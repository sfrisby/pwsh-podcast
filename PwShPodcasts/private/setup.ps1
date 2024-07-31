<#
.SYNOPSIS
Ensures the creation of the expected folder structure.
.DESCRIPTION
Ensures the following folder structure is created or throws failure:
ROOT: The parent folder of the module where this script is executed.
|- resource: A folder to store resources.
   |- thumbnails: A folder to store podcast thumbnails.
   |- all.json: A file to store all podcast episodes.
   |- rss.json: A file to store podcast information.
#>
[CmdletBinding()]
$private:SETUP = @{}
try {
    $location = $PSScriptRoot
    $module = Split-Path $location -Parent
    $path_root = Split-Path $module -parent
    $path_downloads = $( join-path $path_root "downloads" )
    $path_resource = $( join-path $path_root "resource" )
    $path_thumbnails = $( join-path $path_resource "thumbnails" )
    $path_icon = $( join-path $path_resource "p.ico" )

    # Ensure folder structure creation.
    $folders = @($path_downloads, $path_resource, $path_thumbnails)
    foreach ($folder in $folders) {
        if ( -not (Test-Path -Path $folder -PathType Container) ) {
            try {
                New-Item -Path $folder -ItemType Directory -Force
                Write-Information "Created $folder."
            }
            catch [System.IO.IOException] {
                throw "Failed to create '$folder' : $_"
            }
        }
    }

    # Ensure VLC location based on OS.
    $path_vlc = $null
    $platform = [System.Environment]::OSVersion.Platform
    if ( ($null -eq $platform) -or ("" -eq $platform) ) {
        throw "Unable to detect OS platform within ${PSScriptRoot}. Exiting setup."
    }
    switch ($platform) {
        "Unix" { 
            $snap = "/snap/bin/vlc"
            $user = "/usr/bin/vlc"
            if (Test-Path -Path $snap -PathType Leaf -IsValid) {
                $path_vlc = $snap
            } elseif (Test-Path -Path $user -PathType Leaf -IsValid) {
                $path_vlc = $user
            }
        }
        Default {
            $path_vlc = "C:\Program Files\VideoLAN\VLC\vlc.exe"
        }
    }
    if ( -not (Test-Path -Path $path_vlc -PathType Leaf -IsValid) ) {
        throw "Change VLC path within ${PSScriptRoot} and try again."
    }

    $private:SETUP = @{
        path = @{
            vlc        = $path_vlc
            icon       = $path_icon
            root       = $path_root
            resource   = $path_resource
            downloads  = $path_downloads
            thumbnails = $path_thumbnails
            podcasts   = @{
                rss = $( join-path $path_resource "rss.json" )
                all = $( join-path $path_resource "all.json" )
            }
        }
    }
    
    # Ensure podcasts JSON files.
    $files = @( $private:SETUP.path.podcasts.rss, $private:SETUP.path.podcasts.all )
    foreach ($file in $files) {
        if ( -not (Test-Path -Path $file -PathType Leaf) ) {
            try {
                "" | Out-File -FilePath $file -Encoding utf8 -Force
                Write-Verbose "Created $($file)."
            }
            catch [System.IO.IOException] {
                throw "Failed to create '$file' : $_"
            }
        }
    }
}
catch {
    throw "An error has occurred during setup: $_"
}

# Getter variables (not accessible directly).
$VLC_PATH = $private:SETUP.path.vlc
$ICON_PATH = $private:SETUP.path.icon
$RESOURCE_FOLDER = $private:SETUP.path.resource
$DOWNLOADS_FOLDER = $private:SETUP.path.downloads
$THUMBNAIL_FOLDER = $private:SETUP.path.thumbnails
$PODCAST_RSS_FILE = $private:SETUP.path.podcasts.rss
$EPISODES_FILE = $private:SETUP.path.podcasts.all

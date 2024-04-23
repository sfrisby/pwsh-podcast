<#
.SYNOPSIS
Ensures the creation of the expected folder structure.
.DESCRIPTION
Ensures the following folder structure is created or throws failure:
ROOT: The parent folder of the module where this script is executed.
|- resource: A folder to store resources.
   |- episodes: A folder to store podcast episode lists.
   |- thumbnails: A folder to store podcast thumbnails.
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
    $path_episodes = $( join-path $path_resource "episodes" )
    $path_thumbnails = $( join-path $path_resource "thumbnails" )
    # Ensure folder structure creation.
    $folders = @($path_downloads, $path_resource, $path_episodes, $path_thumbnails)
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
    $private:SETUP = @{
        path = @{
            root       = $path_root
            resource   = $path_resource
            downloads  = $path_downloads
            episodes   = $path_episodes
            thumbnails = $path_thumbnails
            podcasts   = @{
                rss = $( join-path $path_resource "rss.json" )
            }
        }
    }
    Write-Debug "Setup variable is: $($private:SETUP)"
    # Ensure podcasts RSS feeds creations.
    if ( -not (Test-Path -Path $private:SETUP.path.podcasts.rss -PathType Leaf) ) {
        try {
            "" | Out-File -FilePath $private:SETUP.path.podcasts.rss -Encoding utf8 -Force
            Write-Information "Created $($private:SETUP.path.podcasts.rss)."
        }
        catch [System.IO.IOException] {
            throw "Failed to create '$($private:SETUP.path.podcasts.rss)' : $_"
        }
    }
}
catch {
    throw "An error has occurred during setup: $_"
}

# Getter variables (not accessible directly).
$RESOURCE_FOLDER = $private:SETUP.path.resource
$DOWNLOADS_FOLDER = $private:SETUP.path.downloads
$EPISODES_FOLDER = $private:SETUP.path.episodes
$THUMBNAIL_FOLDER = $private:SETUP.path.thumbnails
$PODCAST_RSS_FILE = $private:SETUP.path.podcasts.rss
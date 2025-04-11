<#

.SYNOPSIS

Read and or setup powershell podcasts configuration.

#>
[CmdletBinding()]
param ()

begin {

    $config = @{}
    $podcasts = @{}

    function Set-ConstantPodcastVariables() {
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
                Set-Variable -Name PODCASTS_BASENAME -Value "psPodcasts" -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'PODCASTS_BASENAME' already set."
            }

            try {
                Set-Variable -Name PODCASTS_PATH -Value $(Join-Path $HOME $PODCASTS_BASENAME) -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'PODCASTS_PATH' already set."
            }

            try {
                Set-Variable -Name RSS_FILEPATH -Value $(Join-Path $PODCASTS_PATH "podcasts.json" ) -Option Constant -Scope Script -ErrorAction Stop
            }
            catch [System.Management.Automation.SessionStateUnauthorizedAccessException] {
                Write-Verbose "Constant variable 'RSS_FILEPATH' already set."
            }

        }
        catch {
            Write-Error "Unexpected exception occured."
            throw $_
            exit 1
        }
    }
    
    function Get-PodcastsConfiguration() {
        try {
            if (Test-Path -Path $CONFIG_FILEPATH -PathType Leaf) {
                $config = Get-Content $CONFIG_FILEPATH | Out-String | ConvertFrom-Json
            }
            else {
                Write-Verbose "Setting up default configuration."
                Save-DefaultPodcastConfig
                $config = Get-Content $CONFIG_FILEPATH | Out-String | ConvertFrom-Json
            }
        }
        catch [System.IO.FileAccess] {
            Write-Error "Unable to access file: '$CONFIG_FILEPATH'. Check permissions and try again."
            throw $_
            exit 1
        }
        catch {
            Write-Error "Unknown exception occurred."
            throw $_
            exit 1
        }
    }
    
    function Save-DefaultPodcastConfig() {
        New-Item -Path $CONFIG_FILEPATH -ItemType File -ErrorAction Stop | Out-Null
        Set-Content -Path $CONFIG_FILEPATH -Value $($(.\.config.default.ps1) | Out-String) -ErrorAction Stop | Out-Null
    }
    
    function Save-PodcastConfig() {
        Set-Content -Path $CONFIG_FILEPATH -Value $($config | ConvertTo-Json | Out-String) -ErrorAction Stop | Out-Null
    }

    function Resolve-VLC() {
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

    function Resolve-TLS() {
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

    function Resolve-Podcasts() {
        if ([String]::IsNullOrEmpty($config.podcasts)) {
            Write-Host "Podcasts directory not found. Default path: '$PODCASTS_PATH'"
            $choice = Read-Host "Provide an absolute path or leave blank to use the default"
            try {
                if ([String]::IsNullOrEmpty($choice)) {
                    New-Item -Path $PODCASTS_PATH -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    $config.podcasts = $PODCASTS_PATH
                }
                else {
                    New-Item -Path $choice -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    $config.podcasts = $choice
                }
            }
            catch {
                Write-Error "Error occurred when setting up podcasts folder."
                throw $_
                exit 1
            }
        }
        elseif (-not $( Test-Path -Path $config.podcasts -PathType Container )) {
            throw [System.IO.DirectoryNotFoundException] "The podcast folder '$($config.psPodcasts)' does not exist. Please create it manually."
            exit 1
        }
    }

    function ConvertFrom-PodcastsVersionOneRss() {
        $rssdeprecated = $(Join-Path $PSScriptRoot "resource" "rss.json")
        if (Test-Path -Path $rssdeprecated -PathType Leaf) {
            $content = Get-Content $rssdeprecated | Out-String | ConvertFrom-Json
            foreach ($item in $content) {
                $value = @{
                    'about'     = $item.description
                    'added'     = $(Get-Date -Format "yyMMdd")
                    'author'    = $item.author
                    'downloads' = ""
                    'episodes'  = ""
                    'image'     = @{
                        'local' = ""
                        'url'   = $item.image
                    }
                    'pull'      = ""
                    'rss'       = $item.url
                }
                $podcasts.Add($item.title, $value)
            }
            New-Item -Path $RSS_FILEPATH -ErrorAction Stop
            Set-Content -Path $RSS_FILEPATH -Value $($podcasts | ConvertTo-Json | Out-String) -ErrorAction Stop
        }
    }

    function Resolve-PodcastsRss() {
        try {
            $podcasts = Get-Content $RSS_FILEPATH -ErrorAction Stop | Out-String | ConvertFrom-Json
        }
        catch [System.IO.FileNotFoundException], [System.Management.Automation.ItemNotFoundException] {
            write-host "Missing '$RSS_FILEPATH'."
        }
        catch {
            Write-Error "Unexpected error occurred when trying to read '$RSS_FILEPATH' content." 
            throw $_
            exit 1
        }
    }
}

process {
    Set-ConstantPodcastVariables

    Get-PodcastsConfiguration | Out-Null

    Resolve-VLC | Out-Null

    Resolve-TLS | Out-Null

    Resolve-Podcasts | Out-Null

    Resolve-PodcastsRss | Out-Null
}

end {
    Save-PodcastConfig

    return $podcasts, $config
}

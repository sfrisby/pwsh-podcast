# TODO replace
$settings = $(get-content -Path .\settings.json -Raw | ConvertFrom-Json)

. .\Invoke-CastosPodcastSearch.ps1

. .\utils.ps1
function write-host-choices() {
    Write-Host " s > search and add a new podcast"
    Write-Host " l > list all podcasts"
    Write-Host " r > remove a podcast"
    Write-Host " q > quit"
}

# Calculating padding to display for the podcasts found.
function displayPodcastsFeeds() {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $($null -ne $_) -and $($_.count -ne 0) })]
        [array] $Podcasts
    )
    $extraPadding = 3
    $titlePadding = $($($($Podcasts) | ForEach-Object { $_.title.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $authorPadding = $($($($Podcasts) | ForEach-Object { $_.author.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $urlPadding = $($($($Podcasts) | ForEach-Object { $_.url.length }) | Measure-Object -Maximum).Maximum + $extraPadding
    $indexPadding = $Podcasts.Count.ToString().Length
    $origBgColor = $host.UI.RawUI.BackgroundColor
    $Podcasts | ForEach-Object {
        if ( $Podcasts.indexof($_) % 2) { # Alternating for visual cue.
            $host.UI.RawUI.BackgroundColor = 'DarkYellow'
            $([string]$Podcasts.indexof($_)).padleft($indexPadding) +
            " " + $([string]$_.title).PadLeft($titlePadding) +
            " " + $([string]$_.author).PadLeft($authorPadding) +
            " " + $([string]$_.url).PadLeft($urlPadding)
        }
        else {
            $host.UI.RawUI.BackgroundColor = $origBgColor
            $([string]$Podcasts.indexof($_)).padleft($indexPadding) +
            " " + $([string]$_.title).PadLeft($titlePadding) +
            " " + $([string]$_.author).PadLeft($authorPadding) +
            " " + $([string]$_.url).PadLeft($urlPadding)
        }
    }
    $host.UI.RawUI.BackgroundColor = $origBgColor
}

$isActive = $true
Write-Host-Welcome -Message " Podcast Manager "
write-host-choices
while ($isActive) {
    $choice = Read-Host "Provide an action (above)"
    switch ($choice) {
        "s" {
            $isSearching = $true
            while ($isSearching) {
                $choice = Read-Host "Enter the name of the podcast to search for"
                switch ($choice) {
                    "" {
                        Write-Host "Nothing was provided. Provide 'q' to return to the previous menu."
                    }
                    "q" {
                        Write-Host "Returning to previous menu."
                        $isSearching = $false
                    }
                    Default {
                        Write-Host "Searching for '$choice' podcasts ..."
                        $search = $(Invoke-CastosPodcastSearch -Podcast $choice)
                        if ($search -ne "No feeds found.") {
                            $search | ConvertTo-Json | Out-File -FilePath $settings.file.search
                            # Write-Host "The following podcasts were found:"
                            # displayPodcasts -Podcast $search
                            $isAdding = $true
                            while ($isAdding) {
                                try {
                                    $search = [array]$(Get-Content -Path $settings.file.search -Raw | ConvertFrom-Json -AsHashtable)
                                    displayPodcastsFeeds -Podcasts $search -ErrorAction Stop
                                    $choice = Read-Host "Provide the podcast # (above) to add it or 'q' to enter a new search"
                                    switch ($choice) {
                                        "q" {
                                            Write-Host "Returning to search."
                                            $isAdding = $false
                                        }
                                        Default {
                                            $feed = @($search[[int]$choice])
                                            $feeds = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable)
                                            if ($feeds.title -contains $feed.title -and $feeds.author -contains $feed.author) {
                                                Write-Host "Podcast $($feed.title) already exists. Choose a different podcast."
                                            }
                                            else {
                                                $feeds += @( $feed )
                                                $feeds | ConvertTo-Json | Out-File $settings.file.feeds
                                                write-host "Added $($feed.title) by $($feed.author) to podcast feeds."
                                                $isAdding = $false
                                            }
                                        }
                                    }
                                }
                                catch {
                                    Write-Debug $_
                                    write-host "The search failed. Try again."
                                }
                            }
                        }
                        else {
                            Write-Host $search
                        }
                    }
                }
            }
            write-host-choices
        }
        "l" {
            try {
                $feeds = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable)
                Write-Host-Welcome -Message " Podcasts List " -delimiter " "
                displayPodcastsFeeds -Podcasts $feeds
                Write-Host-Welcome -Message " End of Podcast List " -delimiter " "
            }
            catch [System.Management.Automation.ParameterBindingException] {
                Write-Debug "Invalid podcasts detected. Attempting to repair."
                $feedsToKeep = @()
                $invalidCount = 0
                $feeds | ForEach-Object {
                    if ($null -ne $_) {
                        $feedsToKeep += $_
                    }
                    else {
                        $invalidCount++
                    }
                }
                $feedsToKeep | ConvertTo-Json | Out-File $settings.file.feeds
                Write-Debug "Removed $invalidCount podcast(s)."
                Write-Host-Welcome -Message " Podcasts List "
                displayPodcastsFeeds -Podcasts $feedsToKeep
                Write-Host-Welcome -Message " End of Podcast List "
            }
            catch {
                Write-Debug $_
                Write-Host "Unable to locate podcasts. Try adding a podcast. Returning to the previous menu."
            }
            write-host-choices
        }
        "r" {
            $isRemoving = $true
            while ($isRemoving) {
                try {
                    $feeds = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable)
                    displayPodcastsFeeds -Podcasts $feeds -ErrorAction Stop
                    $choice = Read-Host " Provide the # from above for the podcast to remove" # TODO multiple podcasts or single
                    switch ($choice) {
                        "q" {
                            Write-Host "Returning to previous menu."
                            $isRemoving = $false
                        }
                        Default {
                            $index = [int]$choice
                            $feedsToKeep = @()
                            for ($i = 0; $i -lt $feeds.Length; $i++) {
                                if ( $i -ne $index ) {
                                    $feedsToKeep += $feeds[$i]
                                }
                            }
                            $feedsToKeep | ConvertTo-Json | Out-File $settings.file.feeds
                            write-host "Removed $($feeds[$index].title) by $($feeds[$index].author) from podcast feeds."
                            $isRemoving = $false
                        }
                    }
                }
                catch {
                    Write-Debug $_
                    write-host "No search results were obtainable. Perform another search."
                    $isRemoving = $false
                }
            }
        }
        "q" {
            $isActive = $false
        }
        Default {
            Write-Host "Unable to process '$choice'. Please select one of the following"
            write-host-choices
        }
    }
}



. '.\include.ps1'

function write-host-choices() {
    Write-Host " s : search and add a new podcast"
    Write-Host " l : list all podcasts"
    Write-Host " r : remove a podcast"
    Write-Host " q : quit"
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
                            $search | ConvertTo-Json | Out-File -FilePath $SEARCH_FILE
                            # Write-Host "The following podcasts were found:"
                            # displayPodcasts -Podcast $search
                            $isAdding = $true
                            while ($isAdding) {
                                try {
                                    $search = [array]$(Get-Content -Path $SEARCH_FILE -Raw | ConvertFrom-Json -AsHashtable)
                                    displayPodcastsFeeds -Podcasts $search -ErrorAction Stop
                                    $choice = Read-Host "Provide the podcast # (above) to add it or 'q' to enter a new search"
                                    switch ($choice) {
                                        "q" {
                                            Write-Host "Returning to search."
                                            $isAdding = $false
                                        }
                                        Default {
                                            $feed = @($search[[int]$choice])
                                            $feeds = [array]$(Get-Content -Path $FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable)
                                            if ($feeds.title -contains $feed.title -and $feeds.author -contains $feed.author) {
                                                Write-Host "Podcast $($feed.title) already exists. Choose a different podcast."
                                            } 
                                            else {
                                                try {
                                                    Invoke-PodcastFeed -URI $feed.url
                                                    $feeds += @( $feed )
                                                    $feeds | ConvertTo-Json | Out-File $FEEDS_FILE
                                                    write-host "Added $($feed.title) by $($feed.author) to podcast feeds."
                                                    $isAdding = $false
                                                }
                                                catch [System.Net.Http.HttpRequestException] {
                                                    Write-Host "Podcast $($feed.title) appears to exist behind a paywall. Choose a different podcast."
                                                }
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
                $feeds = [array]$(Get-Content -Path $FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable)
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
                $feedsToKeep | ConvertTo-Json | Out-File $FEEDS_FILE
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
                    $feeds = [array]$(Get-Content -Path $FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable)
                    displayPodcastsFeeds -Podcasts $feeds -ErrorAction Stop
                    $choice = Read-Host " Provide the number (#) above for the podcast to remove"
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
                            $feedsToKeep | ConvertTo-Json | Out-File $FEEDS_FILE
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
            write-host-choices
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


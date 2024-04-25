<#
.NOTES
.COMPONENT 
MIN_EPS - The minimun number of episodes found for any single podcast.
#>

Set-Variable MIN_EPS -Option Constant -Value 29

BeforeAll {
    if (Get-Module -Name PwShPodcasts) {
        Remove-Module PwShPodcasts
    }
    Import-Module .\PwShPodcasts
}
 
Describe "Setup" {
    Context "Folders" {
        It "resource folder" {
            Test-Path -Path $(Get-ResourceFolderPath) -PathType Container | Should -Be $true
        }
        It "thumbnails folder" {
            Test-Path -Path $(Get-ThumbnailFolderPath) -PathType Container | Should -Be $true
        }
    }
    Context "Files" {
        It "RSS file" {
            Test-Path -Path $(Get-RssFilePath) -PathType Leaf | Should -Be $true
        }
    }
}

Describe "Format-PodcastsTasks" {
    Context "threads" {
        It "_uses_Get-Podcasts_for_comparison" {
            $podcasts = $(Get-Podcasts)
            $e = Format-PodcastsTasks
            foreach ($podcast in $podcasts) {
                $e.all.podcast_title.indexof($podcast.title) | should -Not -Be $null
                $tmp = $e.all | Where-Object { $_.podcast_title -eq $podcast.title }
                $tmp.Count | Should -BeGreaterOrEqual $MIN_EPS
                Test-Path -Path $(Get-PodcastThumbnailFileName -Name $podcast.title) -PathType Leaf | Should -Be $true
            }
        }
    }
}

Describe "Thumbnail" {
    Context "ConfirmAllPodcastThumbnails" {
        It "threads" {
            InModuleScope PwShPodcasts {
                $expected = @(Get-Podcasts)
                $jobs = ConfirmAllPodcastThumbnails | Wait-Job # Must wait or missing thumbnail jobs won't be initialized.
                foreach ($e in $expected) {
                    $tmp = $(Get-PodcastThumbnailFileName -Name $e.title)
                    Test-Path -Path $tmp -PathType Leaf | Should -Be $true
                }
                $jobs | remove-job
            }
        }
    }
    Context "ConfirmPodcastThumbnail" {
        It "method" {
            InModuleScope PwShPodcasts {
                $podcast = @(Get-Podcasts)[0]
                $tmp = join-path $PSScriptRoot "test_thumbnail.jpg"
                try {
                    ConfirmPodcastThumbnail -Podcast $podcast -File $tmp
                    Test-Path -Path $tmp -PathType Leaf | Should -Be $true
                    Get-Content -Path $tmp | Should -Not -Be $null
                    $(get-childitem -Path $tmp).Length | Should -BeGreaterThan 0
                }
                finally {
                    Remove-Item -Path $tmp
                }
            }
        }
    }
}

Describe "GetAllEpisodesOnline" {
    Context "threads" {
        It "_uses_Get-Podcast_to_compare_and_cleans_jobs" {
            InModuleScope PwShPodcasts {
                try {
                    $expected = @(Get-Podcasts)
                    $jobs = GetAllEpisodesOnline | Wait-Job # Wait or may not initialize.
                    $episodes = $jobs | Receive-Job
                    foreach ($expect in $expected) {
                        $($episodes | Where-Object { $_.podcast_title -eq $expect.title }).Count | Should -BeGreaterOrEqual $MIN_EPS
                    }
                }
                finally {
                    $jobs | Remove-Job
                }
            }
        }
    }
    Context "Get-EpisodesOnline" {
        It "_uses_Save-Episodes_Get-EpisodesOnline_Get-Podcastspulls_and_checks_file_contents_and_cleans_file." {
            $podcast = @(Get-Podcasts)[0]
            $tmp = [System.IO.Path]::GetTempFileName()
            $episodes = @(Get-EpisodesOnline -Podcast $podcast)
            try {
                Save-Episodes -Episodes $episodes -File $tmp
                Test-Path -Path $tmp -PathType Leaf | Should -Be $true
                Get-Content -Path $tmp | Should -Not -Be $null
                $(get-childitem -Path $tmp).Length | Should -BeGreaterThan 0
            }
            finally {
                Remove-Item $tmp
            }
        }
        It "_uses_default_Get-EpisodesOnline_Get-Podcasts_Invoke-Download_and_checks_file_contents_and_cleans_file." {
            $podcast = @(Get-Podcasts)[0]
            $episode = @(Get-EpisodesOnline -Podcast $podcast)[0]
            $file = ""
            try {
                $file = Invoke-Download -URI $episode.enclosure.url
                $(Get-ChildItem -Path $file).Length | Should -BeGreaterThan 0
            }
            finally {
                Remove-Item $file
            }
        }
    }
}

Describe " Compare-Episodes" {
    Context "integration_module_scope" {
        It "gets first podcast online episodes; compares to a subset; ensures new contains amount expected." {
            $index = 3
            $podcast = @(Get-Podcasts)[0]
            $online = @(Get-EpisodesOnline -Podcast $podcast)
            $less = @($online[$index .. $($online.Count - 1)])
            $tmp = [System.IO.Path]::GetTempFileName()
            $tmp_file = $tmp + ".json"
            Move-Item $tmp $tmp_file
            $tmp = $tmp_file
            try {
                Save-Episodes -Episodes $less -File $tmp
                $local = @(Get-EpisodesLocal -File $tmp)
                $table =  Compare-Episodes -Oldest $local -Latest $online
                $table.new | Should -Not -BeNullOrEmpty
                $table.new.Count | Should -Be $index
                $table.all | Should -Not -BeNullOrEmpty
                $($local.Count + $table.new.Count) | Should -Be $online.Count
            }
            finally {
                Remove-Item -Path $tmp
            }
        }
    }
}

Describe "Webrequests" {
    Context "ConvertFrom-PodcastWebRequestContent_and_Invoke-PodcastFeed" {
        It "inspects_pbs" {
            InModuleScope PwShPodcasts {
                $pbs = "https://www.pbs.org/newshour/feeds/rss/podcasts/show"
                $episodes = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-PodcastFeed -Uri $pbs)
                $episodes | ForEach-Object {
                    $_.author | Should -BeExactly "PBS NewsHour"
                }
            }
        }
        It "inspects_lpn" {
            InModuleScope PwShPodcasts {
                $lpn = "https://feeds.simplecast.com/dCXMIpJz"
                $episodes = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-PodcastFeed -Uri $lpn)
                $episodes | ForEach-Object {
                    $_.author | Should -BeExactly "The Last Podcast Network"
                }
            }
        }
    }
}

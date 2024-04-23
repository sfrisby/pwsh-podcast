BeforeAll {
    if (Get-Module -Name PwShPodcasts) {
        Remove-Module PwShPodcasts
    }
    Import-Module ".\PwShPodcasts"
}

Describe "Setup" {
    Context "Folders" {
        It "resource folder" {
            Test-Path -Path $(Get-ResourceFolderPath) -PathType Container | Should -Be $true
        }
        It "episodes folder" {
            Test-Path -Path $(Get-EpisodeFolderPath) -PathType Container | Should -Be $true
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

Describe "Functions" {
    Context "Get-NewAndAllSetForEpisodes & Get-EpisodesOnline & Get-EpisodesLocal & Get-Podcasts" {
        It "inspects generated set" {
            $podcast = @(Get-Podcasts)[0]
            $online = @(Get-EpisodesOnline -Podcast $podcast)
            $tmp = [System.IO.Path]::GetTempFileName()
            Save-Episodes -Episodes $online -File $tmp
            $local = @(Get-EpisodesLocal -File $tmp)
            $table = Get-NewAndAllSetForEpisodes -Oldest $local -Latest $online
            $table.new | Should -BeNullOrEmpty
            $table.all | Should -Not -BeNullOrEmpty
            Remove-Item -Path $tmp
        }
    }
}

Describe "Integration" {
    Context "Save-Episodes & Get-EpisodesOnline & Get-Podcasts" {
        It "pulls online episodes and saves them to temporary file and checks contents and cleans up." {
            InModuleScope PwShPodcasts {
                $podcast = @(Get-Podcasts)[0]
                $tmp = [System.IO.Path]::GetTempFileName()
                $episodes = @(Get-EpisodesOnline -Podcast $podcast)
                Save-Episodes -Episodes $episodes -File $tmp
                Test-Path -Path $tmp -PathType Leaf | Should -Be $true
                Get-Content -Path $tmp | Should -Not -Be $null
                $(get-childitem -Path $tmp).Length | Should -BeGreaterThan 0
                Remove-Item $tmp
            }
        }
    }
    Context "ConvertFrom-PodcastWebRequestContent & Invoke-PodcastFeed" {
        It "inspect PBS episodes" {
            InModuleScope PwShPodcasts {
                $pbs = "https://www.pbs.org/newshour/feeds/rss/podcasts/show"
                $episodes = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-PodcastFeed -Uri $pbs)
                $episodes | ForEach-Object {
                    $_.author | Should -BeExactly "PBS NewsHour"
                }
            }
        }
        It "inspect LPN episodes" {
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

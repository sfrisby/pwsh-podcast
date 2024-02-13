BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    $script:pbs = "https://www.pbs.org/newshour/feeds/rss/podcasts/show"
    $script:lpn = "https://feeds.simplecast.com/dCXMIpJz"
}

Describe "ConvertFrom-PodcastWebRequestContent" {
    It "Confirms the exact number of PBS NewsHour episodes." {
        $episodes = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-WebRequest -Uri $script:pbs)
        $episodes.Count | Should -Be 30
    }
    It "Confirms a threshold for Last Podcast Network episodes." {
        $episodes = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-WebRequest -Uri $script:lpn)
        $episodes.Count | Should -BeGreaterThan 300
    }
}
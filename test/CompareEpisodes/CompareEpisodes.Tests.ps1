<#

Thanks fiven to https://adamtheautomator.com/powershell-compare-arrays/

#>

BeforeAll {
    # PSCommandPath contains network resolver path information that will be stripped here.
    $ps_path = $PSCommandPath
    $drive = get-location -PSDrive "v"
    $split = $ps_path.Split("\")
    $beg = $split.IndexOf('home')
    $end = $split.Count - 1
    $parts = $split[$beg..$end] | Join-String -Separator "\"
    $source = ""
    $source += "$drive"
    $source += "$parts"
    $path = Get-ChildItem $source -Directory
    $name = $path.Name
    
    # Lore episodes list grow when a new episode is added.
    $lore = $path.FullName.Replace($name, 'Lore_240319.json')
    $script:lore_static_episodes = [array]$(Get-Content -Path $lore -Raw | ConvertFrom-Json -AsHashtable);

    # PBS NewsHour appears to only have 30 episodes, the oldest is removed while the latest takes the first position.
    $pbs = $path.FullName.Replace($name, 'PBS NewsHour - Full Show_240319.json')
    $script:pbs_static_episodes = [array]$(Get-Content -Path $pbs -Raw | ConvertFrom-Json -AsHashtable);

    . $path.FullName.Replace('.Tests.ps1', '.ps1')

    $root = $path.Directory.Parent
    $convert = "ConvertFrom-PodcastWebRequestContent"
    $convert_path = Join-Path $root $convert $($convert+'.ps1')
    . $convert_path

    $script:pbs_feed = "https://www.pbs.org/newshour/feeds/rss/podcasts/show"
    $script:lore_feed = "https://feeds.libsyn.com/65267/rss"
}

Describe "Episode Comparison Tests" {
    Context "Expected Different Episode Counts" {
        It "Inspecting Lore" {
            <#
            
                The static episodes are an ordered hashtable while the latest are just the basic hashtable.

                However, the order appears to still be preserved.

            #>
            $latest = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-WebRequest -Uri $script:lore_feed)
            $script:lore_static_episodes.Count | Should -BeLessOrEqual $latest.Count
            $compare = Compare-Object -ReferenceObject $script:lore_static_episodes -DifferenceObject $latest -Property title
            if ($compare.count -eq 0) {
                $script:lore_static_episodes[0].title | Should -BeExactly $latest[0].title
            } else {
                $script:lore_static_episodes[0].title | Should -Not -BeExactly $latest[0].title
            }

            
        }
    }
    
    Context "Expected Identical Episode Count With Differing Episodes" {
        It "PBS Newshour" {
            $script:pbs_static_episodes.Count | Should -Be 30

            $latest = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-WebRequest -Uri $script:pbs_feed)
            $latest.Count | Should -Be 30

            # TODO: Expected to fail next episode update
            $script:pbs_static_episodes[0].title | Should -BeExactly $latest[0].title
        }
    }
}

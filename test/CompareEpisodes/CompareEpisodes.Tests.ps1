<#

    Thanks given to https://adamtheautomator.com/powershell-compare-arrays/

#>

BeforeAll {
    # PSCommandPath contains 'network resolver path information' which is parsed to simplify path naviagtion.
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

    # TODO: use Get-EpisodeFileContent method.
    # Elements are OrderedHashtable
    $script:lore_static_episodes = [array]$(Get-Content -Path $lore -Raw | ConvertFrom-Json -AsHashtable);

    # PBS NewsHour appears to only have 30 episodes, the oldest is removed while the latest is first.
    $pbs = $path.FullName.Replace($name, 'PBS NewsHour - Full Show_240319.json')
    $script:pbs_static_episodes = [array]$(Get-Content -Path $pbs -Raw | ConvertFrom-Json -AsHashtable);

    . $path.FullName.Replace('.Tests.ps1', '.ps1')

    $root = $path.Directory.Parent
    $convert = "ConvertFrom-PodcastWebRequestContent"
    $convert_path = Join-Path $root $convert $($convert + '.ps1')
    . $convert_path

    $script:pbs_feed = "https://www.pbs.org/newshour/feeds/rss/podcasts/show"
    $script:lore_feed = "https://feeds.libsyn.com/65267/rss"
}

Describe "PBS Newshour" {
    Context "New Episodes" {
        It "Compares Episodes" {
            $script:pbs_static_episodes.Count | Should -Be 30
            
            $latest = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-WebRequest -Uri $script:pbs_feed)
            $latest.Count | Should -Be 30
            
            # Reverse iterating to keep latest episode first.
            $compare = Compare-Object -ReferenceObject $script:pbs_static_episodes -DifferenceObject $latest -Property title
            $tmp = New-Object 'System.Collections.ArrayList'
            $tmp.AddRange($script:pbs_static_episodes)
            for ($i = $compare.Length - 1; $i -ge 0; $i--) {
                if ($compare[$i].SideIndicator -eq "=>") {
                    # $tmp.Insert(0, $latest[$latest.title.IndexOf($compare[$i].title)] -as [System.Management.Automation.OrderedHashtable])
                    $tmp.Insert(0, $latest[$latest.title.IndexOf($compare[$i].title)] -as $tmp[0].GetType())
                }
            }
            <# 
            
                Converting from ArrayList (C#) back to array (PowerShell).

                NOTE: The debugger states the new items as type of 'OrderedHashtable' while the
                    older episodes are of type 'System.Management.Automation.OrderedHashtable' which
                    is why type equality is checked. They appear to be 'identical' though their 
                    names differ ... gorgeous.

            #>
            $all = $tmp -as [array]
            $all[0].GetType() | Should -Be $all[-1].GetType()
            $all[0].GetType() | Should -BeExactly $all[-1].GetType()
            $all.count | should -BeGreaterThan $latest.count
            $all.count | should -BeGreaterThan $script:pbs_static_episodes.Count
        }
    }
}

Describe "Lore" {
    Context "New Episodes" {
        It "Compares Episodes" {
            $script:lore_static_episodes.Count | Should -BeGreaterThan 0

            # NOTE: $latest Elements are of type Hashtable NOT OrderedHashtable as in $script:lore_static_episodes
            $latest = ConvertFrom-PodcastWebRequestContent -Request $(Invoke-WebRequest -Uri $script:lore_feed) 
            $script:lore_static_episodes.Count | Should -BeLessOrEqual $latest.Count

            $compare = Compare-Object -ReferenceObject $script:lore_static_episodes -DifferenceObject $latest -Property title
            $tmp = New-Object 'System.Collections.ArrayList'
            $tmp.AddRange($script:lore_static_episodes)
            for ($i = $compare.Length - 1; $i -ge 0; $i--) {
                if ($compare[$i].SideIndicator -eq "=>") {
                    $tmp.Insert(0, $latest[$latest.title.IndexOf($compare[$i].title)] -as $tmp[0].GetType())
                }
            }
            $all = $tmp -as [array]
            $all[0].GetType() | Should -Be $all[-1].GetType()
            $all[0].GetType() | Should -BeExactly $all[-1].GetType()
            $all.count | should -BeGreaterOrEqual $latest.count
            $all.count | should -BeGreaterThan $script:lore_static_episodes.Count
        }
    }
}
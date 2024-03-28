
BeforeAll {
    # Parsing 'network resolver path information' from PSCommandPath.
    $ps_path = $PSCommandPath
    $drive = get-location -PSDrive "v"
    $split = $ps_path.Split("\")
    $beg = $split.IndexOf('home')
    $end = $split.Count - 1
    $parts = $split[$beg..$end] | Join-String -Separator "\"
    $source = "$drive" + "$parts"
    $path = Get-ChildItem $source -Directory
    . $path.FullName.Replace('.Tests.ps1', '.ps1')
    
    $r = ($split[$beg..$($split.indexof('test'))] | Join-String -Separator "\") 
    $resources = Get-ChildItem $( "$drive" + "$r" + "\resources\static-episode" )
}

Describe "Get-EpisodeFileContent" {
    Context "Method" {
        It "Calls the method for each resource" {
            foreach ($resource in $resources) {
                $tmp = Get-EpisodeFileContent -File $resource.FullName
                $tmp.Count | should -BeGreaterThan 0
            }
        }
    }
}
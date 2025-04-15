Describe "search_podcasts.ps1" {
    It "performs a podcast search" {
        $s = . "$PSScriptRoot\search_podcasts.ps1" -Title "npr"
        $s.gettype().name | Should -Match "hashtable"
        $s.response.StatusCode | should -Be 200
        $s.response.StatusDescription | should -Be "OK"
        $s.data | should -BeOfType [PSCustomObject]
    }
}


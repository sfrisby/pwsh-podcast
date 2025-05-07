Describe "episodes.ps1" {
    BeforeAll {
        $script:root = $PSCommandPath | Split-Path -Parent | Split-Path -Parent
        $script:run = Join-Path $root "src" "episodes.ps1"
    }
    context "multiple valid podcasts" {
        BeforeAll {
            $script:p0 = [pscustomobject]@{
                title       = "pbs news hour mock";
                author      = 'pbs';
                url         = "https://www.pbs.org/newshour/feeds/rss/podcasts/show";
                description = "mock of pbs podcast item"
            }
            $script:p1 = [pscustomobject]@{
                title       = "npr polictics podcast mock";
                author      = 'npr';
                url         = "https://feeds.npr.org/510310/podcast.xml";
                description = "mock of pbs podcast item"
            }
            $script:p2 = [pscustomobject]@{
                title       = "se-radio podcast mock";
                author      = 'se-radio team';
                url         = "https://feeds.feedburner.com/se-radio";
                description = "mock of software engineering radio podcast"
            }
            $script:podcasts = @($p0, $p1, $p2)
            $script:out = @()
        }
        It "executes thread episodes script and confirms job output" {
            $script:out = & $script:run $podcasts
            $script:out.gettype() -eq [object[]] | should -BeTrue
        }
        It "confirms first mock podcast info" {
            $script:out[0].podcast.title | Should -BeExactly 'pbs news hour mock'
            $script:out[0].episodes[0].gettype() -eq [hashtable] | should -BeTrue
        }
        It "confirms second mock podcast info" {
            $script:out[1].podcast.title | Should -BeExactly 'npr polictics podcast mock'
            $script:out[1].episodes[0].gettype() -eq [hashtable] | should -BeTrue
        }
        It "confirms last mock podcast info" {
            $script:out[2].podcast.title | Should -BeExactly 'se-radio podcast mock'
            $script:out[2].episodes[0].gettype() -eq [hashtable] | should -BeTrue
        }
    }
    context "invalid podcasts handling" {
        BeforeAll {
            $script:invalid0 = [pscustomobject] @{
                title       = "invalid podcast mock";
                author      = 'invalid team';
                url         = "https://feeds.extinct.invalid.nobueno.com/invalid/please/dont/exist";
                description = "mock of invalid podcast"
            }
            $script:invalid1 = [pscustomobject] @{
                title       = "second invalid podcast mock";
                author      = 'second invalid team';
                url         = "https://feeds.extinct.invalid.nobueno.com/fakenews";
                description = "second mock of invalid podcast"
            }
        }
        It "confirms single invalid podcast job handling" {
            $out = & $script:run @($invalid0)
            $out.gettype() -eq [hashtable]
            $out.errors.gettype() -eq [System.Management.Automation.ErrorRecord]
        }
        It "confirms multiple invalid podcast job handling" {
            $out = & $script:run @($invalid0, $invalid1)
            $out.gettype() -eq [object[]] 
            $out[0].errors.gettype() -eq [System.Management.Automation.ErrorRecord]
            $out[1].errors.gettype() -eq [System.Management.Automation.ErrorRecord]
        }
    }
}
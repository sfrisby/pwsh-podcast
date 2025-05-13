<#

.SYNOPSIS

Episodes order is no longer guaranteed. Searching and sorting required.

.NOTES

Any errors that occur will be contained within an 'error' property with the podcast title.

#>
Describe "invoke_then_format_podcasts_episodes.ps1" {
    BeforeAll {
        $script:root = $PSCommandPath | Split-Path -Parent | Split-Path -Parent
        $script:run = Join-Path $root "src" "invoke_then_format_podcasts_episodes.ps1"
    }
    context "multiple valid podcasts" {
        BeforeAll {
            $script:p0 = [pscustomobject]@{
                title       = "pbs news hour mock";
                author      = 'pbs';
                url         = "https://www.pbs.org/newshour/feeds/rss/podcasts/show";
                description = "mock of pbs podcast"
            }
            $script:p1 = [pscustomobject]@{
                title       = "npr polictics podcast mock";
                author      = 'npr';
                url         = "https://feeds.npr.org/510310/podcast.xml";
                description = "mock of npr podcast"
            }
            $script:p2 = [pscustomobject]@{
                title       = "se-radio podcast mock";
                author      = 'se-radio team';
                url         = "https://feeds.feedburner.com/se-radio";
                description = "mock of software engineering radio podcast"
            }
            $script:podcasts = @($script:p0, $script:p1, $script:p2)
            $script:out = & $script:run $script:podcasts
        }
        It "executes thread episodes script and confirms job output" {
            $script:out.gettype() -eq [object[]] | should -BeTrue
        }
        It "confirms first mock podcast info" {
            $t = $script:out | Where-Object { $_.podcast -eq 'pbs news hour mock' }
            $t.gettype() -eq [object[]] | should -BeTrue
            $t | ForEach-Object {
                $_.gettype() -eq [pscustomobject]::new().gettype() | should -BeTrue
            }
        }
        It "confirms second mock podcast info" {
            $t = $script:out | Where-Object { $_.podcast -eq 'npr polictics podcast mock' }
            $t.gettype() -eq [object[]] | should -BeTrue
            $t | ForEach-Object {
                $_.gettype() -eq [pscustomobject]::new().gettype() | should -BeTrue
            }
        }
        It "confirms last mock podcast info" {
            $t = $script:out | Where-Object { $_.podcast -eq 'se-radio podcast mock' }
            $t.gettype() -eq [object[]] | should -BeTrue
            $t | ForEach-Object {
                $_.gettype() -eq [pscustomobject]::new().gettype() | should -BeTrue
            }
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
            $t = & $script:run @($invalid0)
            $t.gettype() -eq [pscustomobject]::new().gettype() | should -BeTrue
            [string]::IsNullOrEmpty($t.podcast) | should -BeFalse
            $t.error.gettype() -eq [System.Management.Automation.ErrorRecord] | should -BeTrue
        }
        It "confirms multiple invalid podcast job handling" {
            $t = & $script:run @($invalid0, $invalid1)
            $t.gettype() -eq [object[]]

            $p = $t | Where-Object { $_.podcast -eq 'invalid podcast mock' }
            $p.gettype() -eq [pscustomobject]::new().gettype() | should -BeTrue
            [string]::IsNullOrEmpty($p.podcast) | should -BeFalse
            $p.error.gettype() -eq [System.Management.Automation.ErrorRecord] | should -BeTrue

            $p = $t | Where-Object { $_.podcast -eq 'second invalid podcast mock' }
            $p.gettype() -eq [pscustomobject]::new().gettype() | should -BeTrue
            [string]::IsNullOrEmpty($p.podcast) | should -BeFalse
            $p.error.gettype() -eq [System.Management.Automation.ErrorRecord] | should -BeTrue
        }
    }
}
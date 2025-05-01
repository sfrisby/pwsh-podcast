BeforeAll {
    . $PSScriptRoot\..\src\utilities.ps1
}

Describe "confirm_leaf" {
    it "creates new file and confirms existance" {
        $f = "TestDrive:\\confirm_leaf_test_file"
        New-Item -ItemType File -Value "hello world" -Path $f -Force -ErrorAction Stop | Out-Null
        confirm_leaf $f | Should -BeTrue
    }
    it "confirms extinction of file" {
        $f = "TestDrive:\\confirm_leaf_imaginary"
        confirm_leaf $f | Should -BeFalse
    }
}

Describe "confirm_container" {
    it "creates new container and confirms existance" {
        $f = "TestDrive:\\confirm_container_test_folder"
        New-Item -ItemType Directory -Path $f -Force -ErrorAction Stop | Out-Null
        confirm_container $f | Should -BeTrue
        Test-Path $f | should -BeTrue
    }
    it "confirms extinction of container" {
        $f = "TestDrive:\\confirm_container_imaginary"
        confirm_container $f | Should -BeFalse
        Test-Path $f | should -BeFalse
    }
}

Describe "save_container" {
    it "confirms existance of new container" {
        $f = "TestDrive:\\save_container_test_folder"
        save_container $f
        Test-Path $f | Should -BeTrue
    }
    it "confirms failure of invalid container name" {
        $f = "TestDrive:\\save?_\container/_test_folder"
        { save_container $f } | should -Throw
    }
}

Describe "get_valid_system_chars" {
    It "checks removal of invalid system characters" {
        $text = "this `n is*one ???awesome `r`n`t\podcast//////title test"
        $test = get_valid_system_chars $text
        $test | Should -BeExactly 'this_is_one_awesome_podcast_title_test'
    }
    It "checks multiple space and hyphen replacements with single underscores" {
        $text = "this  ---  is--one-awesome _-_podcast_title test"
        $test = get_valid_system_chars $text
        $test | Should -BeExactly 'this_is_one_awesome_podcast_title_test'
    }
    It "shows powershell characters expression issue when not using string literals" {
        # expression
        $tmp = "foo" # $$ automatic variable that contains the last token of the last line input into the shell (brave's leo)
        $text = "$null($tmp)null($tmp)$null($tmp)($tmp)null"
        $test = get_valid_system_chars $text
        $test | Should -BeExactly "(foo)null(foo)(foo)(foo)null"
        # literal
        $text = '$null$$null$$$null$$$$null'
        $test = get_valid_system_chars $text
        $test | Should -BeExactly '_null_null_null_null'
    }
    It "shows embedded expression case" {
        # embedded expression
        $text = "$(@('null'))"
        $test = get_valid_system_chars $text
        $test | Should -BeExactly "null"
        # literal
        $text = '$(@(''null''))'
        $test = get_valid_system_chars $text
        $test | Should -BeExactly "_(_('null'))"
    }
}

Describe "invoke_podcasts" {
    BeforeAll {
        <#

        .FUNCTIONALITY

        If results change then try out queries at https://castos.com/tools/find-podcast-rss-feed/ to fix tests

        #>
        $script:q = invoke_podcasts "pbs"
        $script:s = invoke_podcasts "Philosophize This! Stephen West"
        $script:n = invoke_podcasts "!@#$%^&*()"
        $script:nofeedmsg = 'No feeds found.'
    }
    Context "invoke_podcast_query" {
        it "confirms multiple podcast response" {
            $null -ne $q.response | should -BeTrue
        }
        it "confirms single podcast response" {
            $null -ne $s.response | should -BeTrue
        }
        it "confirms no podcast response" {
            $null -ne $n.response | should -BeTrue
            $null -ne $n.response.content | should -BeTrue
            ($n.response.content | ConvertFrom-Json).data | should -BeExactly $nofeedmsg
        }
    }
    Context "format_podcast_query" {
        it "inspects multiple podcasts" {
            ($q.podcasts | Join-String) -contains "’" | should -BeFalse
        }
        it "inspects single podcast" {
            ($s.podcasts | Join-String) -contains "’" | should -BeFalse
        }
        it "inspects no podcast" {
            ($n.podcasts | Join-String) -contains "’" | should -BeFalse
        }
    }
    context "podcast case types" {
        It "multiple podcasts found" {
            $q.gettype() -eq [hashtable] | should -BeTrue
            $q.podcasts.gettype() -eq [object[]] | should -BeTrue
        }
        It "single podcast found" {
            $s.gettype() -eq [hashtable] | should -BeTrue
            $s.podcasts.count | Should -BeExactly 1
            # NOTE: only using [pscustomobject] became [psobject] which failed equality test
            $s.podcasts.GetType() -eq [pscustomobject]::new().gettype() | should -BeTrue
        }
        It "no podcast found" {
            $n.gettype() -eq [hashtable] | should -BeTrue
            $n.podcasts.gettype() -eq [string] | should -BeTrue
            $n.podcasts | should -BeExactly $nofeedmsg
        }
    }
}

Describe "invoke_podcast_episodes" {
    BeforeAll {
        $script:p = @{
            title       = "pbs news hour mock";
            author      = 'pbs';
            url         = "https://www.pbs.org/newshour/feeds/rss/podcasts/show";
            description = "mock of pbs podcast item"
            image       = "https://image.pbs.org/contentchannels/k1Gwt8I-show-poster2x3-EWWT8oy.jpg?format=webp&crop=227x340"
        }
        $script:e = $(invoke_podcast_episodes $p)
    }
    Context "invoke_podcast_url" {
        It "confirms unchanged response content" {
            $e.response.gettype() -eq [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]
            $e.response.content.gettype() -eq [string] | should -BeTrue
            $e.response.content.contains('&rsquo;') | should -BeTrue
            $e.response.content.contains('&#8211;') | should -BeTrue
        }
    }
    Context "format_podcast_url" {
        It "confirms changed response content" {
            $e.content.gettype() -eq [string] | should -BeTrue
            $e.content.contains('&rsquo;') | should -BeFalse
            $e.content.contains('&#8211;') | should -BeFalse
        }
    }
    Context "format_podcast_content" {
        $e.episodes | foreach-object {
            $_.description -contains "’" | Should -BeFalse
        }
    }
    It "confirms types" {
        $e.episodes.gettype() -eq [System.Object[]] | Should -BeTrue
        $e.podcast.gettype() -eq [hashtable] | should -BeTrue
    }
    It "confirms array elements type" {
        $e.episodes | foreach-object {
            $_.gettype() -eq [hashtable] | Should -BeTrue
        }
    }
}
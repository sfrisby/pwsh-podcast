<#

.EXAMPLE

From within the working directory:

Invoke-Pester -Container $(New-PesterContainer -Path .\test\setup.Tests.ps1 -Data @{ FOO = $false; })

Verbose:

invoke-Pester -Container $(New-PesterContainer -Path .\test\setup.Tests.ps1 -Data @{ FOO = $true; Verbose = $true; })

.EXAMPLE DEPRECATED

Used for pester version 4:

Invoke-Pester -Script @{Path = '.\test\setup.Tests.ps1'; Parameters = @{"FOO" = $True}}

#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch] $FOO
)

BeforeAll {

    $pods, $cfg = .\"$PSScriptRoot\..\setup.ps1" -Verbose

}

Describe "Constant variables scope" {
    Context "script scope variables should not exist" {
        It "checks existance of CONFIG_BASENAME" {
            Test-Path Variable:Script:CONFIG_BASENAME | Should -Be $false
        }
        It "checks existance of CONFIG_FILEPATH" {
            Test-Path Variable:Script:CONFIG_FILEPATH | Should -Be $false
        }
        It "checks existance of PODCAST_DIRECTORY_BASENAME" {
            Test-Path Variable:Script:PODCAST_DIRECTORY_BASENAME | Should -Be $false
        }
        It "checks existance of PODCAST_DIRECTORY_PATH" {
            Test-Path Variable:Script:PODCAST_DIRECTORY_PATH | Should -Be $false
        }
        It "checks existance of PODCAST_JSON_FILEPATH" {
            Test-Path Variable:Script:PODCAST_JSON_FILEPATH | Should -Be $false
        }
    }
}

Describe "Configuration" {
    Context "Keys that should exist" {
        It "check for 'vlc" {
            ($cfg | get-member).name -ccontains 'vlc' | should -Be $true
        }
        It "check for 'tls" {
            ($cfg | get-member).name -ccontains 'tls' | should -Be $true
        }
        It "check for 'podcasts" {
            ($cfg | get-member).name -ccontains 'podcasts' | should -Be $true
        }
        It "check for 'version" {
            ($cfg | get-member).name -ccontains 'version' | should -Be $true
        }
    }
    Context "Local storage" {
        It "checks existance of podcast directory" {
            Test-Path -Path $cfg.podcasts -PathType Container | Should -Be $true
        }
    }
}

Describe "function Repair-AllPodcastsDirectories" {
    Context "Local storage" {
        It "ensure local existance of each podcast folder" {
            foreach ($p in ($pods | Get-Member).Name) {
                $tmp = Join-Path $cfg.podcasts $p
                Test-Path -Path $tmp -PathType Container | Should -Be $true
            }
        }
    }
}

Describe "function Repair-AllPodcastsThumbnails" {
    Context "Local storage" {
        It "confirms path for local thumbnail" {

            $foo = 1
        }
    }
}

Describe "function Format-Thumbnail" {
    Context "Local storage" {
        It "create an image" {

            $foo = 1
        }
    }
}

AfterAll {
    if ($FOO) {
        Write-Verbose "Received switch parameter: 'FOO'."
    }
}



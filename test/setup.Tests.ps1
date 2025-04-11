<#

.EXAMPLE

From within the working directory:

Invoke-Pester -Container $(New-PesterContainer -Path .\test\setup.Tests.ps1 -Data @{ REMOVE_TEST_ARTIFACTS = $false; })

Verbose:

invoke-Pester -Container $(New-PesterContainer -Path .\test\setup.Tests.ps1 -Data @{ REMOVE_TEST_ARTIFACTS = $true; Verbose = $true; })

.EXAMPLE DEPRECATED

Used for pester version 4:

Invoke-Pester -Script @{Path = '.\test\setup.Tests.ps1'; Parameters = @{"REMOVE_TEST_ARTIFACTS" = $True}}

#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch] $REMOVE_TEST_ARTIFACTS
)

. "$PSScriptRoot\..\setup.ps1"

Describe "Constant variables scope" {
    Context "script scope variables should not exist" {
        It "checks existance of CONFIG_BASENAME" {
            Test-Path Variable:Script:CONFIG_BASENAME | Should -Be $false
        }
        It "checks existance of CONFIG_FILEPATH" {
            Test-Path Variable:Script:CONFIG_FILEPATH | Should -Be $false
        }
        It "checks existance of PODCASTS_BASENAME" {
            Test-Path Variable:Script:PODCASTS_BASENAME | Should -Be $false
        }
        It "checks existance of PODCASTS_PATH" {
            Test-Path Variable:Script:PODCASTS_PATH | Should -Be $false
        }
        It "checks existance of RSS_FILEPATH" {
            Test-Path Variable:Script:RSS_FILEPATH | Should -Be $false
        }
    }
}

if ($REMOVE_TEST_ARTIFACTS) {
    Write-Verbose "Received switch parameter: 'REMOVE_TEST_ARTIFACTS'."
}

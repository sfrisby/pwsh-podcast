BeforeAll {

    . $PSScriptRoot\..\src\utilities.ps1

    $p, $c = .\$PSScriptRoot\..\src\setup.ps1

}

Describe "constants setup scope" {
    It "checks existance of constants defined in setup.ps1 within this scope" {
        # get the constant names from the script
        $parse = Get-Content .\src\setup.ps1 | where-Object { $_ -match ' set-constant ' }
        $parse | ForEach-Object {
            $parts = $_ -split "'"
            $name = $parts[1]
            Write-Verbose "looking at $name"
            Test-Path "Variable:Script:$name" | Should -Be $false
        }
    }
}

Describe "configuration" {
    Context "members" {
        It "confirm 'vlc'" {
            $c.Keys -contains 'vlc' | should -BeTrue
        }
        It "confirm 'tls'" {
            $c.Keys -contains 'tls' | should -BeTrue
        }
        It "confirm 'local'" {
            $c.Keys -contains 'local' | should -BeTrue
        }
        It "confirm 'version'" {
            $c.Keys -contains 'version' | should -BeTrue
        }
    }
    Context "storage" {
        It "confirm podcasts storage folder existance" {
            Test-Path -Path $c.local -PathType Container | Should -BeTrue
        }
    }
}

Describe "podcasts" {
    Context "storage" {
        It "confirm individual podcast folder existance" {
            $p.title | ForEach-Object {
                $f = get_valid_system_chars $_
                Test-Path -Path $(Join-Path $c.local $f) -PathType Container | Should -BeTrue
            }
        }
    }
}

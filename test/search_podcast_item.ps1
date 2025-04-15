<#

.SYNOPSIS

Provide the file system information for the provided path or 0 if not found.

.NOTES

[System.IO.FileInfo]
[System.IO.DirectoryInfo]

Gotta just use item objects for handling paths

(Get-Item .).gettype() -eq [System.IO.DirectoryInfo]
(Get-Item .).gettype() -eq [System.IO.FileInfo]

(Get-Item .).gettype().BaseType -eq [System.IO.FileSystemInfo]

join-path $pwd "some" "directories" "file.ext"

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
    [string]
    $Path
)
begin {
    function Search-PodcastItem {
        try {
            return Get-Item -Path $Path -ErrorAction Stop
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            return 0
        }
        catch {
            throw $_
        }
    }
}
process {
    $_d = Search-PodcastItem
}
end {
    return $_d
}
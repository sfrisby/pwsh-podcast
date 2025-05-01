if (!$q) { 
    $q = .\test\get_podcasts.ps1 "city cast" # "pbs news hour"
}

.\test\show_podcasts.ps1 $q.podcasts | Format-Table

$i = Read-Host -Prompt "Select the '#' of the podcast"

$table = .\test\get_podcast_episodes.ps1 $q.podcasts[$i]

.\test\show_episodes.ps1 $table.episodes | Format-Table

$file = (Join-Path $([System.IO.Path]::GetTempPath()) "test.json")

@($table.podcast, $table.episodes) | ConvertTo-Json -Depth 6 | Out-File -FilePath $file

$load = Get-Content -Path $file | ConvertFrom-Json -Depth 6 -AsHashtable

$load[1].GetType() -eq $table.episodes.gettype()       # the same | true

$load[1][0].GetType() -eq $table.episodes[0].gettype() # NOT the same due to load being [System.Management.Automation.OrderedHashtable] and initial [hashtable] | false
$load[1][0] = [hashtable] $load[1][0]                  # type cast doesn't work ~ type NOT changed
$load[1][0].GetType() -eq $table.episodes[0].gettype() # false
$load[1][0] = [hashtable]::new($load[1][0])            # instead have to reinitialize
$load[1][0].GetType() -eq $table.episodes[0].gettype() # now the same type - but only the single index! | true

$load[0].GetType() -eq $table.podcast.GetType()        # NOT the same due to load being [System.Management.Automation.OrderedHashtable] and initial [pscustomobject] | false
$load[0] = [pscustomobject] $load[0]                   # type cast changes the type
$load[0].GetType() -eq $table.podcast.GetType()        # now the same | true

<#

TODO in podcasts folder, store podcasts titles each on single line

>   $file = $(Join-Path $([System.IO.Path]::GetTempPath()) "podcasts")
>   @("testing some names", "another name of something", "last of something") | Out-File -Path $file
each element placed on its own line

>   Get-Content -Path $file
>   $(Get-Content -Path $file) -contains "testing some names"
able to determine what already exists

>   $u = (Get-Content -Path $file)
>   $u | ForEach-Object { $u[[array]::IndexOf($u, $_)] = $($_ -replace " ", "_") }
replacing spaces with underscores

then a function to convert the title into the folder for the podcast inforamtion
- podcast folder should be the title with underscores instead of spaces, all lowervercase, and only alphanumeric characters

Should also keep track of browser since that way we can open links there directly
- start 'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe' "google.com"

query via registry for default https browser, BraveHTML
> Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice'

showing default browser shell command, but requires setting registry for powershell
> New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
> $defaultBrowser = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice").Progid
> Get-ItemProperty "HKCR:\$defaultBrowser\shell\open\command"
> (Get-ItemProperty "HKCR:\$defaultBrowser\shell\open\command").'(default)'


#>
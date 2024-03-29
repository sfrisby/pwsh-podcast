# Doesn't work and doesn't appear to be the way to go for things.
# Attempts to create an instance of a window and emulate a click to
# make the page load fully, but has not been successful. Much simpler
# to just grab the feed directly.

$site = "https://player.simplecast.com/4ca28c43-1b5a-4fc4-bc21-fc9e79754a3a?dark=false&show=true&color=D94E23&wmode=opaque"
&  "$env:programfiles\Internet Explorer\iexplore.exe" $site
$win = New-Object -comObject Shell.Application
$try = 0
$wObj = $null
do {
  Start-Sleep -milliseconds 500
$wObj = @($win.windows() | Where-Object { $_.locationName -like '*Simplecast*' })[0]
$try ++
if ($try -gt 20) { Throw "Web Page cannot be opened." }
} while ($null -eq $wObj)
[System.Threading.Thread]::Sleep(100) 
# put both Iframe name and id both to "fraMain" 
$wObj.document.getElementbyID("fraMain").contentWindow.document.getElementbyID("name").value = "test name"
$wObj.document.getElementbyID("fraMain").contentWindow.document.getElementbyID("button").Click()
$foo = 1
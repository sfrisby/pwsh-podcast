<#
See working with feeds script.
  * https://castos.com/tools/find-podcast-rss-feed/
  * Network tools with revealed a fetch from admin-ajax.php, which provided results data. Copied as PowerShell for script baseline.

Grattitude and thanks goes to:
  * https://stackoverflow.com/questions/62639056/browse-and-submit-to-webform-using-powershell
#>

$podcast = @{
  pbsnewshour        = "pbs newshour"
  stuffyoushouldknow = "stuff you should know"
  madiganpubcast     = "madigan's pubcast"
  lpotl              = "last podcast on the left"
  open2debate        = "open to debate"
  nprpolitics        = "NPR Politics"
}

$search = $podcast.nprpolitics

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
$session.Cookies.Add((New-Object System.Net.Cookie("tlf_58", "1", "/", "castos.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("tve_leads_unique", "1", "/", "castos.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("tl_21131_21132_58", "a%3A1%3A%7Bs%3A6%3A%22log_id%22%3BN%3B%7D", "/", "castos.com")))
$response = Invoke-WebRequest -UseBasicParsing -Uri "https://castos.com/wp-admin/admin-ajax.php" `
  -Method "POST" `
  -WebSession $session `
  -Headers @{
  "authority"          = "castos.com"
  "method"             = "POST"
  "path"               = "/wp-admin/admin-ajax.php"
  "scheme"             = "https"
  "accept"             = "*/*"
  "accept-encoding"    = "gzip, deflate, br"
  "accept-language"    = "en-US,en;q=0.7"
  "cache-control"      = "no-cache"
  "origin"             = "https://castos.com"
  "pragma"             = "no-cache"
  "referer"            = "https://castos.com/tools/find-podcast-rss-feed/"
  "sec-ch-ua"          = "`"Not A(Brand`";v=`"99`", `"Brave`";v=`"121`", `"Chromium`";v=`"121`""
  "sec-ch-ua-mobile"   = "?0"
  "sec-ch-ua-platform" = "`"Windows`""
  "sec-fetch-dest"     = "empty"
  "sec-fetch-mode"     = "cors"
  "sec-fetch-site"     = "same-origin"
  "sec-gpc"            = "1"
} `
  -ContentType "multipart/form-data; boundary=----WebKitFormBoundaryEvNAMJxBVu6aUrB3" `
  -Body ([System.Text.Encoding]::UTF8.GetBytes("------WebKitFormBoundaryEvNAMJxBVu6aUrB3$([char]13)$([char]10)Content-Disposition: form-data; name=`"search`"$([char]13)$([char]10)$([char]13)$([char]10)$($search)$([char]13)$([char]10)------WebKitFormBoundaryEvNAMJxBVu6aUrB3$([char]13)$([char]10)Content-Disposition: form-data; name=`"action`"$([char]13)$([char]10)$([char]13)$([char]10)feed_url_lookup_search$([char]13)$([char]10)------WebKitFormBoundaryEvNAMJxBVu6aUrB3--$([char]13)$([char]10)"))

if ($response.StatusCode -eq 200) {
  try {
    $results = $($response.Content | ConvertFrom-json).data | ConvertTo-Json
    $fileName = $search + "-" + $(Get-Date -Format yyMMddHHss) + "-search_results.json"
    $results | Out-File $fileName -Force
    Write-Host "$filename created." 
  }
  catch {
    Write-Host "Issue during $fileName creation."
    Write-Host $_.ScriptStackTrace
  }
}
else {
  Write-Host "Response code was: $($response.StatusCode) | $($response.StatusDescription)."
}

[Reflection.Assembly]::LoadFrom((Resolve-Path "~\bin\TagLibSharp.dll"))

$feedsFileName = "episode_feed.json"
$episodes = ConvertFrom-Json (Get-Content -Path ".\$feedsFileName" -raw)

if ( !$($episodes.Length -gt 0) ) {
    throw "No episodes were found from: $feedsFileName"
}

#Perform an episode selection; for now just grab the first.
$title = $episodes.e0.Title + ".mp3"
$url = $episodes.e0.URL

if ( !$(Test-Path $title -IsValid) ) {
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
        $title = $title.replace("$c",'')
    }
}

Invoke-WebRequest -Uri $url -OutFile $title

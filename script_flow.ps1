$config = (Get-Content .\config.json | ConvertFrom-Json)
$podcastslocal = Get-Content -Path (join-path $config.podcasts 'podcasts.json') | ConvertFrom-Json -Depth 6

# search
$search = . $PSScriptRoot\test\search_podcasts.ps1 -Title "madigan pubcast"

# show ~ provides index
. $PSScriptRoot\test\show_podcasts.ps1 -Podcasts $search

# save desired podcasts locally
# TODO

# selection via index
$title = "Madigan's Pubcast"
$index = [array]::IndexOf($search.data.title, $title)

# get episodes # $episodes[0].episodes[0]
$podcast = $search.data[$index]
$episodes = . $PSScriptRoot\test\get_episodes.ps1 -Podcast $podcast

# saving podcast information
$podcastfile = join-path (Join-Path $config.podcasts $episodes[0].podcast.title) "$($episodes[0].podcast.title).json"
$episodes[0] | ConvertTo-Json -Depth 6 | Out-String | Out-File -Path $podcastfile

# loading saved podcast information ~ pscustomobject ~ $load | Get-Member -Type NoteProperty
$load = Get-Content -Path $podcastfile -Raw | Out-String | ConvertFrom-Json -Depth 6


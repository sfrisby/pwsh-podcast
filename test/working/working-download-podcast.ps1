# [Reflection.Assembly]::LoadFrom((Resolve-Path "~\bin\TagLibSharp.dll"))

$podcasts = @{
    pbs = "PBS NewsHour"
    lpotl = "The Last Podcast"
    nprpolitics = "NPR"
}
$episodeFeeds = Get-ChildItem -Path "*feed.json"

# if ( $episodeFeeds.Length -gt 1) {
#     throw "More than one feed was found: $episodeFeeds."
# }

$file = $episodeFeeds -cmatch $podcasts.nprpolitics
$episodes = ConvertFrom-Json (Get-Content -Path ".\$($file.Name)" -raw)

if ( $episodes.Length -eq 0 ) {
    throw "No episodes were found within $episodeFeeds."
}

# $title = $null
# $url = $null
# $userEpisode = $null
# write-host "Multiple episodes were found:"
# write-host $episodes.title | Format-List
# $prompt = "Please specify the title of the desired episode: "
# $choice = Read-Host -Prompt $prompt
# while ( $null -eq $title -and $null -eq $url) {
#     $userEpisode = $episode.title -cmatch $choice
#     if ( $userEpisode.Length -gt 1 ) {
#         $prompt = "Please provide additional terms to narrow the search: $($userEpisode.title)"
#     } else {
#         $title = $userEpisode.title + ".mp3"
#         $url = $userEpisode.enclosure.url
#     }
#     $choice = Read-Host -Prompt $prompt
# }

#Perform an episode selection; for now just grab the first.
$title = $episodes[0].title[0].'#text' + ".mp3"
$url = $episodes[0].enclosure.url

foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
    $title = $title.replace("$c",'')
}

Invoke-WebRequest -Uri $url -OutFile $title

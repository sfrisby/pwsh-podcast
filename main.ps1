$settings_file = 'conf.json'
$settings = $(get-content -Path $settings_file -Raw | ConvertFrom-Json)

. .\utils.ps1

# $toStream = $true
$toStream = $false

# Display podcasts from feed file and let user choose.
$feeds = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable)
displayPodcastsFeeds -Podcasts $feeds
$choice = Read-Host "Select # (above) of the podcast to listen to"
$podcast = $feeds[[int]$choice]

# Display the episodes and let user choose.
$episodes = Update-Episodes -Podcast $podcast
Write-Episodes -Episodes $episodes
$choice = Read-Host -prompt "Select episode by # (above)"
$episode = @()
try {
    $episode = $episodes[[int]::Parse($choice)]
    Write-Host "Episode selected was: '$($episode.title)'."
}
catch [System.FormatException] {
    throw "A number was not provided. Unable to proceede."
}

if ($toStream) {
    <# 

        This does not work for all podcasts. VLC has reported, "" 
        
        The best option appears to be downloading and then playing ...

    #>
    & "C:\Program Files\VideoLAN\VLC\vlc.exe" --qt-start-minimized --play-and-exit --rate=1.5 $($episode.enclosure.url)
}
else {
    # Download the episode if not already found.
    $title = Approve-String -ToSanitize $episode.title
    $file = join-path (Get-location) "${title}.mp3"
    if ( !(Test-Path -PathType Leaf -Path $file) ) {
        $url = $episode.enclosure.url
        Find-Episode -URI $url -Path $file
    }
    # Updating Tag Information
    .\working-with-tags.ps1 $episode $file
}

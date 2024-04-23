if (Get-Module -Name PwShPodcasts) {
    Remove-Module -Name PwShPodcasts
}
Import-Module '.\PwShPodcasts'

<#
$e = Select-Episode


#>

# <#
# .SYNOPSIS
# CLI for podcasts.
# .PARAMETER $ToStream
# Stream using VLC when true.
# .PARAMETER 
# #>

# param(
#     [parameter(Mandatory = $false)]
#     [bool] $ToStream = $false,
#     [parameter(Mandatory = $false)]
#     [Single] $Rate = 1.5
# )

# . '.\fetch.ps1'

# # Obtaining all feeds
# $feeds = [array]$(Get-Content -Path $script:FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable)

# $selected = @()
# if ($feeds) {

#     # Display latest episodes or continue to podcast selection
#     $found = @()
#     foreach ($podcast in $feeds) {
#         $check = CompareEpisodes -Podcast $podcast -Episodes $script:episodes.$($podcast.title) -UpdateEpisodeFile
#         if ($check) {
#             foreach ($item in $check) {
#                 $found += @{ $podcast.title = $item }
#             }
#         }
#     }
#     if ($found.Count) {    
#         Write-HostCLIEpisodes -Episodes $found
#         $choice = Read-Host -prompt "Select episode by # (above)"
#         try {
#             $selected = $found[[int]$choice]
#             Write-Host "Episode selected was: '$($selected.$($selected.Keys[0]).title)' from '$($selected.Keys[0])'."
#             $selected = $selected.$($selected.Keys[0])
#         }
#         catch [System.FormatException] {
#             throw "A number was not provided. Unable to proceede."
#         } catch {
#             Write-Host "An exception occured while parsing the episode selected."
#             throw $_
#         }
#     }
#     else {
#         # Display podcasts from feed file and let user choose.
#         Write-HostCLIPodcastFeeds -Podcasts $feeds
#         $choice = Read-Host "Select # (above) of the podcast to listen to"
#         $podcast = $feeds[[int]$choice]
#         # Display the episodes and let user choose.
#         $e = $script:episodes."$($podcast.title)"
#         $choice = Read-Host -prompt "Select episode by # (above)"
#         try {
#             $selected = $e[[int]::Parse($choice)]
#             Write-Host "Episode selected was: '$($selected.title)'."
#         }
#         catch [System.FormatException] {
#             throw "A number was not provided. Unable to proceede."
#         }
#     }
# }
# else {
#     Throw "No podcast feeds were found."
# }

# # Streaming does not always work. Unable to identify VLC error. For now the default is download then stream.
# if ($ToStream) {
#     & "C:\Program Files\VideoLAN\VLC\vlc.exe" --play-and-exit --rate=$Rate $($selected.enclosure.url)
# }
# else {
#     # Download the episode if not already found.
#     $title = Approve-String -ToSanitize $selected.title
#     $file = join-path (Get-location) "${title}.mp3"
#     if ( !(Test-Path -PathType Leaf -Path $file) ) {
#         $url = $selected.enclosure.url
#         Invoke-Download -URI $url -Path $file
#     }
#     # Updating Tag Information
#     .\test\UpdateTags\UpdateTags.ps1 $selected $file
#     # Now play in VLC
#     & "C:\Program Files\VideoLAN\VLC\vlc.exe" --play-and-exit --rate=$Rate $file
# }

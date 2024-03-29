<#
.SYNOPSIS
Provided with a list of the latest episodes, return a full list of all episodes.
.DESCRIPTION
Local episodes are contained in JSON.
.PARAMETER File
The local episode JSON file.
.PARAMETER Podcast
The relative podcast information.
.PARAMETER Episodes
The latest (gathered at startup) episodes for the provided podcast.
#>
function CompareEpisodes {
    param(
        [parameter(Mandatory = $true)]
        [hashtable] $Podcast,
        [parameter(Mandatory = $true)]
        [array] $Episodes
    )
    
    $local = @()
    
    $file = $script:EPISODE_PREFIX + "$(Approve-String -ToSanitize $Podcast.title).json"
    if ( Test-Path -Path $file -PathType Leaf ) {
        $local = Get-EpisodeFileContent -File $file
    }
    else {
        # Save baseline episodes as the new podcast episode file.
        Write-EpisodesFile -Episodes $Episodes -File $file
        return 0
    }

    # Reversed indexing to ensure the latest is first.
    $compare = Compare-Object -ReferenceObject $local -DifferenceObject $Episodes -Property title
    $all = New-Object 'System.Collections.ArrayList'
    $all.AddRange($local) # Storing all of the local entries.
    $new = New-Object 'System.Collections.ArrayList'
    for ($i = $compare.Length - 1; $i -ge 0; $i--) {
        if ($compare[$i].SideIndicator -eq "=>") {
            $new.Insert(0, $Episodes[$Episodes.title.IndexOf($compare[$i].title)] -as $Episodes[0].GetType())
            $all.Insert(0, $Episodes[$Episodes.title.IndexOf($compare[$i].title)] -as $Episodes[0].GetType())
        }
    }

    # Update local episode file to contain all episodes and only return the new.
    if ( $new.Count -gt 0 ) {
        Write-EpisodesFile -Episodes $($all -as [array]) -File $file
        $isSingleEpisode = $new.GetType() -eq [System.Management.Automation.OrderedHashtable]
        Write-Host "Found $( $isSingleEpisode ? "one" : "$($new.Count)" ) new episode$( $isSingleEpisode ? " " : "s ")for $($Podcast.title)"
        return $($new -as [array])
    }

    return 0
}

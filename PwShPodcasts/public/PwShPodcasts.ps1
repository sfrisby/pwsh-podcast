<#
.SYNOPSIS
Add a new podcast to the RSS file.
.DESCRIPTION
Search results are based on the $Name provided.
#>
function Add-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ ($null -ne $_) -and ($_.count -gt 0) })]
        [String] $Name
    )    
    $search = Search-Podcasts -Name $Name
    $podcast = Select-Podcast -Podcasts $search.data
    $local = @(Get-Podcasts) # Ensure an collection of hashtables is obtained.
    if ($null -eq $local -or $local.Count -eq 0) {
        Save-Podcasts -Podcasts @( $podcast )
    }
    elseif ($local[0] -eq 'No feeds found.') {
        Save-Podcasts -Podcasts @( $podcast )
    }
    elseif ($local.title -contains $podcast.title) {
        Write-Host "$($podcast.title) already exists."
    }
    else {
        if ($local.GetType().BaseType -ne [array]) {
            throw "Adding podcast failed due to type mismatch."
        }
        $local += @( $podcast )
        Save-Podcasts -Podcasts $local
    }
}

<#
.SYNOPSIS
Obtain the thumbnail (image) by the provided podcast.
.DESCRIPTION
Resizes the thumbnail to $Scale. 
.NOTES
System.Drawing.Bitmap.save does not override existing files.
#>
function ConfirmPodcastThumbnail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ $null -ne $_.image })]
        [hashtable] $Podcast,
        [Parameter()]
        [ValidateScript({ -not [System.IO.File]::Exists($_) })]
        [string] $File = $(Get-PodcastThumbnailFileName -Name $Podcast.title),
        [Parameter()]
        [ValidateRange(100, 500)]
        [Int16] $Scale = 250
    )
    try {
        $tmp = Invoke-Download -URI $Podcast.image
        $thumbnail = [System.Drawing.Image]::FromFile($tmp)
        $resize = New-Object System.Drawing.Bitmap($Scale, $Scale)
        $graphics = [System.Drawing.Graphics]::FromImage($resize)
        $graphics.DrawImage($thumbnail, 0, 0, $Scale, $Scale)
        $resize.Save($File, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $thumbnail.Dispose()
        $graphics.Dispose()
        $resize.Dispose()
    } catch {
        throw $_
    }
    finally {
        if ($thumbnail) { $thumbnail.Dispose() }
        if ($graphics) { $thumbnail.Dispose() }
        if ($resize) { $thumbnail.Dispose() }
    }
}

<#
.SYNOPSIS
Download and resize (if not found) all podcast thumbnails in parallel.
.DESCRIPTION
Because the file name isn't specified, the called method will use the default (podcast title) for file name.
.NOTES
ConfirmPodcastThumbnail MUST be scopped by parent.
.FUNCTIONALITY
DOES NOT CLEANUP JOBS! DO SO WHERE CALLED.
#>
function ConfirmAllPodcastThumbnails {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array] $Podcasts = @(Get-Podcasts)
    )
    $i = { Import-Module .\PwShPodcasts }
    foreach ($podcast in $Podcasts) {
        $n = "thumbnail for $($podcast.title)"
        $block = {
            $function:CPT = $using:function:ConfirmPodcastThumbnail
            return (CPT -Podcast $using:variable:podcast)
        }
        Start-ThreadJob -InitializationScript $i -ScriptBlock $block -Name $n
    }
}

<#
.SYNOPSIS
Provided with lists of the oldest and latest episodes return a full list of all episodes.
.DESCRIPTION
A hashtable is returned containing the keys 'new' for new found episodes and 'all' for all episodes.
Indexing is reversed to ensure the 'newest' episode is first in the list.
.PARAMETER Oldest
Expected to be the oldest list of episodes (local).
.PARAMETER Latest
Expected to be the latest list of episodes (online)
#>
function Compare-Episodes {
    param(
        [parameter(Mandatory = $true)]
        [ValidateScript({ $null -ne $_ })]
        [array] $Oldest,
        [parameter(Mandatory = $true)]
        [ValidateScript({ $null -ne $_ })]
        [array] $Latest
    )
    $compare = Compare-Object -ReferenceObject $Oldest -DifferenceObject $Latest -Property title
    $all = New-Object 'System.Collections.ArrayList'
    $all.AddRange($Oldest) # Storing all of the oldest entries.
    $new = New-Object 'System.Collections.ArrayList'
    for ($i = $compare.Length - 1; $i -ge 0; $i--) {
        if ($compare[$i].SideIndicator -eq "=>") {
            $new.Insert(0, $Latest[$Latest.title.IndexOf($compare[$i].title)] -as $Latest[0].GetType())
            $all.Insert(0, $Latest[$Latest.title.IndexOf($compare[$i].title)] -as $Latest[0].GetType())
        }
    }
    return @{
        new = $( $new -as [array] )
        all = $( $all -as [array] )
    }
}

<#
.SYNOPSIS
Return episodes from a specific podcast.
.NOTES
The break or continue statements do not behave the same way in ForEach-Object cmdlet as they do in other loops.

All episodes for a specific podcast may be accomplished via (# represents the index listed by show-podcasts):
Show-Podcasts
$podcasts = @(get-podcasts)
$episodes = Formate-PodcastTasks
Get-EpisodesByPodcastTitle -Podcast $podcasts[#] -Episodes $episodes

Alternative option:
$episodes = Formate-PodcastTasks
Show-Podcasts
$podcasts = @(get-podcasts)
$specific_podcast_index_episodes = $episodes | Where-Object { $_.podcast_title -eq $podcasts[#].title }
#>
function Get-EpisodesByPodcastTitle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ $null -ne $_.title })]
        [hashtable] $Podcast,
        [Parameter(Mandatory)]
        [array] $Episodes
    )
    return @( $Episodes | Where-Object { $_.podcast_title -eq $Podcast.title } )
}

<#
.SYNOPSIS
Return episodes contained within the provided file.
.NOTES
Best to encapsulate where called, i.e. @(Get-EpisodesLocal -File {})
#>
function Get-EpisodesLocal {
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ (Test-Path -Path $_ -PathType Leaf) -and ($_ -like "*.json") })]
        [string] $File
    )
    [array]$(Get-Content -Path $file -Raw | ConvertFrom-Json -AsHashtable)
}

<#
.SYNOPSIS
Return episodes from the provided podcast.
.DESCRIPTION
Adds the podcast title to the key 'podcast_title'.
.NOTES
Best to encapsulate where called, i.e. @(Get-EpisodesOnline -Podcast {})

When 'No such host is known' (SocketException, HttpRequestException) is thrown it appears to indicate that the RSS is updating.

Idea for tracking 'played' - $table | ForEach-Object { $_.media_accessed_locally_count = 0 }.
    The challenge becomes episode comparison as local will not match if played.
#>
function Get-EpisodesOnline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ ( $null -ne $_.url ) -and ( $null -ne $_.title ) })]
        [hashtable] $Podcast
    )
    $request = @()
    $table = @{}
    try {
        $request = $(Invoke-PodcastFeed -URI $Podcast.url)
        $table = $(ConvertFrom-PodcastWebRequestContent -Request $request)
        $table | ForEach-Object { $_.podcast_title = $Podcast.title }
    } catch {
        throw "Issue upon obtaining online episodes for $($Podcast.title): $($_.ToString())."
    }

    $table
}

<#
.SYNOPSIS
Return a hashtable of ALL podcasts and their respective 'latest' episodes in parrallel.
.NOTES
Get-EpisodesOnline must be visible in module scope for threads to operate unless changed to $using.
.FUNCTIONALITY
DOES NOT CLEANUP JOBS! DO SO WHERE CALLED.
#>
function GetAllEpisodesOnline {
    [CmdletBinding()]
    param (
        [array] $Podcasts = @(Get-Podcasts)
    )
    $i = { Import-Module .\PwShPodcasts }
    foreach ($podcast in $Podcasts) {
        $block = {
            param (
                [parameter(Mandatory)]
                [ValidateScript({ $null -ne $_ })]
                [hashtable] $p
            )
            return @(Get-EpisodesOnline -Podcast $p)
        }
        $n = "episodes for $($podcast.title)"
        Start-ThreadJob -InitializationScript $i -Name $n -ScriptBlock $block -ArgumentList $podcast
    }
}

<#
.SYNOPSIS
Return episodes within the provided published date.
.NOTES
Idea to further simplify into a more PwSh form:
$episodes | Select-Object -Property podcast_title, title, pubDate | Sort-Object -Property pubDate
Updating all date fields to PwSh get-date:
$episodes | ForEach-Object { $_.pubDate = $(Get-Date $_.pubDate) }
Sorting descending (newest at the top):
$sorted = $toSort | Sort-Object -Property pubDate -Descending
#>
function Get-EpisodesWithinDate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [array] $Episodes,
        [Parameter(Mandatory)]
        [ValidateSet('Today', 'Week', 'Month', 'Year')]
        [string] $Published
    )
    $hours = 0
    switch ($Published) {
        'Today' { $hours = 24 }
        'Week' { $hours = 168 }
        'Month' { $hours = 672 }
        'Year' { $hours = 8064 }
        Default { $hours = 168 }
    }
    return @($Episodes | Where-Object { $($(Get-Date) - $(Get-Date $_.pubDate)).TotalHours -le $hours })
}

<#
.SYNOPSIS
Performs all startup formatting podcast tasks.
.DESCRIPTION
This method uses subtle scope 'magic'. Refer to NOTES.
These tasks include:
* gathering all podcast episodes online
* downloading and resizing thumbnails if they don't exist
.NOTES
Jobs are taken from the called functions to report progress.
Their functions names cannot contain a hyphen (-) or it fails interpretation.
It also required "$using". 
Refer to https://stackoverflow.com/questions/68881237/powershell-start-job-scope. 

Both text size of the activity and the status message change how progress is shown.
#>
function Format-PodcastsTasks {
    if ( $(Get-Job).Count -ne 0 ) {
        throw "Jobs already exist! Clear them and try again."
    }
    $names = @{
        local_e    = "local_episodes_00"
        online_e   = "online_episodes_00"
        thumbnails = "thumbnails00"
    }
    $jobs = @()
    # Initialization for all jobs. Necessary for scoping functions in default parameters.
    $i = { Import-Module .\PwShPodcasts } 
    <# LOCAL EPISODES JOB #>
    $block_local_episodes = {
        @(Get-EpisodesLocal -File $(Get-EpisodesFilePath))
    }
    $jobs += ( Start-ThreadJob -InitializationScript $i -ScriptBlock $block_local_episodes -Name $names.local_e )
    <# ONLINE EPISODES JOB #>
    # Access data with {}.keys and {}.indexof({}).
    $block_online_episodes = {
        $function:GAEO = "$using:function:GetAllEpisodesOnline"
        GAEO
    }
    $jobs += ( Start-ThreadJob -InitializationScript $i -ScriptBlock $block_online_episodes -Name $names.online_e )
    <# THUMBNAILS JOB #>
    $block_thumbnails = {
        $function:ConfirmPodcastThumbnail = "$using:function:ConfirmPodcastThumbnail"
        $function:CAPT = "$using:function:ConfirmAllPodcastThumbnails"
        CAPT
    }
    $jobs += ( Start-ThreadJob -InitializationScript $i -ScriptBlock $block_thumbnails -Name $names.thumbnails )
    # Ensure child jobs are initialized and stored before continuing.
    $local_e_job = $null
    $online_e_jobs = $null
    $thumbnailJobs = $null
    while ($null -eq $local_e_job -or $null -eq $online_e_jobs -or $null -eq $thumbnailJobs) {
        $local_e_job = $( Get-Job -Name $names.local_e ) # Exclude children as they may not exist. Wait to receive.
        $online_e_jobs = $( Get-Job -Name $names.online_e -IncludeChildJob | Wait-Job | Receive-Job) # Receiving to have proper job count.
        $thumbnailJobs = $( Get-Job -Name $names.thumbnails -IncludeChildJob | Wait-Job | Receive-Job) # Receiving to have proper job count.
    }
    # Total counts
    $lSteps = $local_e_job.Count
    $eSteps = $online_e_jobs.Count
    $tSteps = $thumbnailJobs.Count
    $allSteps = $eSteps + $tSteps
    # Styling
    $PSStyle.Progress.Style = "$($PSStyle.Background.BrightBlue)"
    $PSStyle.Progress.MaxWidth = 60
    $PSStyle.Progress.View = 'Minimal'
    # Progress 
    $all = "All Tasks"
    $lAct = "Local Episode Gathering"
    $oAct = "Online Episode Gathering"
    $tAct = "Thumbnail Gathering"
    while ((( $local_e_job | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count + `
            ( $online_e_jobs | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count + `
            ( $thumbnailJobs | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'NotStarted' }).Count) -gt 0) {
        Start-Sleep -Milliseconds 100

        $lCompleted = $($local_e_job | Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' } ).Count 
        $oCompleted = $($online_e_jobs | Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' } ).Count 
        $tCompleted = $($thumbnailJobs | Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' } ).Count 
        $allCompleted = $oCompleted + $tCompleted
        
        $allProgress = [string]::Format("{0:N2}", (($allCompleted / $allSteps) * 100))
        $lProgress = [string]::Format("{0:N2}", (($lCompleted / $lSteps) * 100)) 
        $oProgress = [string]::Format("{0:N2}", (($oCompleted / $eSteps) * 100))
        $tProgress = [string]::Format("{0:N2}", (($tCompleted / $tSteps) * 100))

        Write-Progress -Id 0 -Activity $all -Status "$all % $allProgress" -PercentComplete $allProgress
        Write-Progress -Id 1 -ParentId 0 -Activity $lAct -Status "$lAct % $oProgress" -PercentComplete $lProgress
        Write-Progress -Id 2 -ParentId 0 -Activity $oAct -Status "$oAct % $oProgress" -PercentComplete $oProgress
        Write-Progress -Id 3 -ParentId 0 -Activity $tAct -Status "$tAct % $tProgress" -PercentComplete $tProgress
    }
    <#
    Persisting job info (only do so when jobs are complete or incomplete results will be obtained).
    
    Local episodes saved as online if none are found.
    
    Loud thumbnail jobs means a problem occurred.

    Do not save episodes if there are no podcasts found.
    #>
    $episodes = @{
        new = @()
        all = @()
    }
    $local_e_job = $( $local_e_job | Receive-Job )
    $online_e_jobs = $( $online_e_jobs | Receive-Job )
    if (0 -eq $local_e_job.Count -and $(Get-Podcasts).count -ne 0) {
        Save-Episodes -Episodes $online_e_jobs -File $(Get-EpisodesFilePath)
        $episodes.all = @($online_e_jobs)
    } else {
        $episodes = Compare-Episodes -Oldest $local_e_job -Latest $online_e_jobs
    }
    if ( $( $thumbnailJobs | where-object { $_.HasMoreData -eq $true }).count ) {
        Write-Verbose "Issue encountered while obtaining thumbnails: $( $thumbnailJobs | receive-job ) "
    }

    # Cleanup. Impossible to remove ChildJobs so instead remove Parent Jobs.
    Write-Progress -Id 0 -Activity $activity -Completed
    Write-Progress -Id 1 -ParentId 0 -Activity $lActivity -Completed
    Write-Progress -Id 2 -ParentId 0 -Activity $eActivity -Completed
    Write-Progress -Id 3 -ParentId 0 -Activity $tActivity -Completed
    if ($jobs) { $jobs | Remove-Job }

    $episodes
}

<#
.SYNOPSIS
Read information from provided $File and return it.
.DESCRIPTION
Default $File is the path provided by module member Get-RssFilePath.
.NOTES
It is possible for $File content to be $null!
Even though ensuring an array of hashtable elements occurs here it should also be wrapped where called to ensure type, i.e. @(Get-Podcasts).
#>
function Get-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $File = $(Get-RssFilePath)
    )
    $tmp = [array]$(Get-Content -Path $File -Raw | ConvertFrom-Json -AsHashtable)
    if ($null -eq $tmp) {
        $tmp = 'No feeds found.'
    }
    elseif ($tmp.gettype() -eq [System.Management.Automation.OrderedHashtable]) {
        $force = @( $tmp )
        $tmp = $force
    }
    @($tmp)
}

<#
.SYNOPSIS
Return an approved episode file path.
#>
function Get-EpisodeDownloadFileName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Name
    )
    join-path $(Get-DownloadsFolderPath) $( Approve-String $($Name + ".mp3") )
}

<#
.SYNOPSIS
Return a list of episodes provided from $File.
#>
function Get-EpisodesFromFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string] $File
    )
    [array]$(Get-Content -Path $File -Raw | ConvertFrom-Json -AsHashtable);
}

<#
.SYNOPSIS
Return an approved thumbnail file path.
#>
function Get-PodcastThumbnailFileName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Name
    )
    join-path $(Get-ThumbnailFolderPath) $( Approve-String $($Name + ".jpg") )
}

<#
.SYNOPSIS
Invokes VLC with the provided episodes URL.
.NOTES
Multiple instances may be started when enabled in VLC:
https://wiki.videolan.org/VLC_HowTo/Play_multiple_instances/
#>
function Invoke-VlcStream {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript({ $null -ne $_.enclosure.url })]
        [hashtable] $Episode,
        [Parameter()]
        [ValidateScript({ $null -ne $_ -and $_.length -gt 0 })]
        [string] $VLC = $(Get-VlcPath),
        [Parameter()]
        [ValidateRange(0, 3)]
        [float] $Rate = 1.5
    )
    Invoke-Vlc -Stream $($Episode.enclosure.url) -Rate $Rate
}

<#
.SYNOPSIS
Play the provided media (file or stream or both) via VLC.
.NOTES
If both (stream and file) are provided then they may both both to play at the same time depending on VLC's multiple instances setting.
Multiple instances may be started when enabled in VLC:
https://wiki.videolan.org/VLC_HowTo/Play_multiple_instances/
#>
function Invoke-Vlc {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string] $File,
        [Parameter()]
        [ValidateScript({ $null -ne $_ -or "" -ne $_ })]
        [string] $Stream,
        [Parameter()]
        [string] $VLC = $(Get-VlcPath),
        [Parameter()]
        [ValidateRange(0, 3)]
        [Single] $Rate = 1.5
    )
    if ($File) {
        & $VLC --play-and-exit --rate=$Rate $File
    }
    if ($Stream) {
        & $VLC --play-and-exit --rate=$Rate $Stream
    }
}

<#
.SYNOPSIS
Linearly filter podcasts by the provided $Name.
.DESCRIPTION
Changes are only saved when they exist.
#>
function Remove-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ $_.Length -gt 0 })]
        [string]
        $Name
    )
    $rss = @(Get-Podcasts)
    $keep = @()
    foreach ($podcast in $rss) {
        if ($podcast.title -ne $Name) {
            $keep += @($podcast)
        }
    }
    if ($($keep.title | join-string).Length -ne $($rss.title | join-string).Length) {
        Save-Podcasts -Podcasts $keep
    }
    else {
        Write-Verbose "$Name was not found. No podcasts were removed."
    }
}

<#
.SYNOPSIS
Save the episodes list at $file.
.DESCRIPTION
Overwrites $file. Prevents writing to podcast file.
.NOTES
Parenthesis in parameter block are necessary for validate script.
#>
function Save-Episodes {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript({ $null -ne $_.title })]
        [array] $Episodes,
        [Parameter()]
        [ValidateScript({ (Test-Path -Path $_ -IsValid) -and ($_.FullName -ne $(Get-RssFilePath)) })]
        [string] $File
    )
    $Episodes | ConvertTo-Json | Out-File -FilePath $File -Force
}

<#
.SYNOPSIS
Save $Podcasts in the provided $File.
.DESCRIPTION
The default $File path is provided by the module member Get-RssFilePath.
.NOTES
The parenthesis are necessary for allowing empty collection.
#>
function Save-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array] $Podcasts,
        [Parameter(Mandatory = $false)]
        [string] $File = $(Get-RssFilePath)
    )
    $Podcasts | ConvertTo-Json | Out-File -FilePath $File
}

<#
.SYNOPSIS
Obtain podcast search results for the provided $Name.
.NOTES
See Invoke-CastosPodcastSearch for type details.
#>
function Search-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({ $null -ne $_ -and $_.Length -gt 0 })]
        [String] $Name
    )
    $search = Invoke-CastosPodcastSearch -Podcast $Name
    if ($search.data -eq 'No feeds found.') {
        throw $search.data
    }
    $search
}

<#
.SYNOPSIS
Selects the identified podcast from the provided podcasts.
.DESCRIPTION
When only one podcast is provided it is returned without show & selection.
.NOTES
Read-Host puts colon, i.e. ':', at the end.
#>
function Select-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $Podcasts
    )
    if ($Podcasts.Length -eq 1 -or $Podcasts.Count -eq 1) {
        return $Podcasts[0]
    }
    Show-Podcasts -Podcasts $Podcasts
    $choice = Read-Host "Select podcast by number (above)"
    $podcast = @{}
    try {
        $podcast = $Podcasts[[int]::Parse($choice)]
    }
    catch {
        throw "'$choice' failed to identify any podcast."
    }
    $podcast
}

<#
.SYNOPSIS
Display podcast information to the console.
#>
function Show-Podcasts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [ValidateScript({ 
                if ( $_ -eq 'No feeds found.' -or $_.Count -eq 0 -or $_[0] -eq 'No feeds found.') { throw 'No feeds found.' }
                $true # Must provide or will never return a result of $true.
            })]
        [array] $Podcasts = @(Get-Podcasts),
        [Parameter(Mandatory = $false)]
        [Int16] $Pad = 3
    )
    $index_pad = $podcasts.Count.ToString().Length
    $authr_pad = $($($($podcasts) | ForEach-Object { $_.author.length }) | Measure-Object -Maximum).Maximum + $Pad
    $title_pad = $($($($podcasts) | ForEach-Object { $_.title.length }) | Measure-Object -Maximum).Maximum + $Pad
    $url_pad = $($($($podcasts) | ForEach-Object { $_.url.length }) | Measure-Object -Maximum).Maximum + $Pad

    # Alternating foreground color and underscore for visual cue.
    $original = $host.UI.RawUI.ForegroundColor
    $s = "  "
    $u = "__"
    $podcasts | ForEach-Object {
        if ( $podcasts.indexof($_) % 2) {
            $host.UI.RawUI.ForegroundColor = 'DarkGray'
            Write-Host $($([string]$podcasts.indexof($_)).PadLeft($index_pad).Replace($s, $u) +
                " " + $([string]$_.title).PadLeft($title_pad).Replace($s, $u) +
                " " + $([string]$_.author).PadLeft($authr_pad).Replace($s, $u) +
                " " + $([string]$_.url).PadLeft($url_pad).Replace($s, $u))
        }
        else {
            $host.UI.RawUI.ForegroundColor = $original
            Write-Host $($([string]$podcasts.indexof($_)).PadLeft($index_pad) +
                " " + $([string]$_.title).PadLeft($title_pad) +
                " " + $([string]$_.author).PadLeft($authr_pad) +
                " " + $([string]$_.url).PadLeft($url_pad))
        }
    }
    $host.UI.RawUI.ForegroundColor = $original
}

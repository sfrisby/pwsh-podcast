<#
.SYNOPSIS
Main entry point. By default imports PwShPodcasts and, when found, TagLibSharp.
.DESCRIPTION
Environment is always setup in order to access podcast information reliably.
Checks for existance of TagLibSharp DLL.
.PARAMETER GUI
Provide to launch the GUI.
.EXAMPLE
Store a list of all episodes from all podcasts into $episodes.
$episodes = .\main.ps1
.EXAMPLE
Launch the GUI. The episodes within the last week will be displayed by default.
.\main.ps1 -GUI
.EXAMPLE
If something is not working, try using verbose to identify the issue.
.\main.ps1 -Verbose
May also be specified when using the GUI.
.\main.ps1 -Verbose -GUI
.EXAMPLE
To obtain the hashtable of episode list data (all episodes and new as compared to online and episodes file)
with keys 'all' for all episodes and 'new' for newest episodes use the following:

$data = $( .\main.ps1 -ReturnData )

All episodes may be inspected using: $data.all 
New episodes may be inspected using: $data.new

The -ReturnData flag may also be used with the -GUI flag. Data won't be populated until after the GUI is closed.
#>
[CmdletBinding()]
param (
    [Parameter()]
    [switch] $GUI,
    [Parameter()]
    [switch] $ReturnData
)

<# PwShPodcasts Module #>
if (Get-Module -Name PwShPodcasts) {
    Remove-Module -Name PwShPodcasts
}
Import-Module .\PwShPodcasts

<# TagLibSharp DLL #>
$script:LOADED_TAG_LIB_SHARP = $false
if ($HOME) { $script:TagLibSharp_Path = join-path $HOME "bin\TagLibSharp.dll" } else { $script:TagLibSharp_Path = join-path [Environment]::GetFolderPath("UserProfile") "bin\TagLibSharp.dll" }
if (Test-Path -Path $script:TagLibSharp_Path -PathType Leaf) {
    [void] [Reflection.Assembly]::LoadFrom($script:TagLibSharp_Path)
    $script:LOADED_TAG_LIB_SHARP = $true
    <#
    .SYNOPSIS
    Update the provided files tags based on the provided episode.
    .NOTES
    https://github.com/mono/taglib-sharp
    A setfield property should exist but not found as a member for the audio tags.
    ---
    if ($null -eq $tags.Tag.URL) { $tags.Tag += @{'URL' = $episode.enclosure.url} }
    InvalidOperation: Method invocation failed because [TagLib.NonContainer.Tag] does not contain a method named 'op_Addition'.
    ---
    $tags.Tag.Tags += @ {'URL'=$episode.enclosure.url}
    InvalidOperation: 'Tags' is a ReadOnly property.
    ---
    $tags.Tag.Tags.'URL'=$episode.enclosure.url         
    InvalidOperation: The property 'URL' cannot be found on this object. Verify that the property exists and can be set.
    #>
    function Update-PodcastEpisodeTags {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [ValidateScript({ $null -ne $_.title })]
            [hashtable] $Episode,
            [Parameter(Mandatory)]
            [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
            [string] $File
        )
        $tags = [TagLib.File]::Create( $(Get-ChildItem -Path $File) )
        try {    
            # Author is not always published (may not exist) but podcast_title will.
            if ($null -ne $Episode.author -or $Episode.author -eq "") {
                if ($null -eq $tags.Tag.Artists -or $tags.Tag.Artists.Count -eq 0) {
                    $tags.Tag.Artists = "$($Episode.author)"
                }
            }
            else {
                if ($null -eq $tags.Tag.Artists -or $tags.Tag.Artists.Count -eq 0) {
                    $tags.Tag.Artists = "$($Episode.podcast_title)"
                }
            }
            # Comment - description or encoding.
            if ($null -eq $tags.Tag.Description -or $tags.Tag.Description -eq "") {
                if ($Episode.encoded) {
                    $tags.Tag.Comment = "$($Episode.description)"
                }
                elseif ($Episode.encoded) {
                    $tags.Tag.Comment = "$($Episode.encoded)"
                }
            }
            # Title - episode not podcast.
            if ($null -eq $tags.Tag.Title -or $tags.Tag.Title -eq "") {
                $tags.Tag.Title = "$($Episode.title)"
            }
            # URL saved in Publisher tag.
            if ($null -eq $tags.Tag.Publisher -or $tags.Tag.Publisher -eq "") {
                <#
            
            #>
                $tags.Tag.Publisher = "$($Episode.enclosure.url)"
            }
    
            # Album set to podcast_title
            if ($null -eq $tags.Tag.Album -or $tags.Tag.Album -eq "") {
                $tags.Tag.Album = "$($Episode.podcast_title)"
            }
    
            # Track number set to Year-Month-Day
            if ($null -eq $tags.Tag.Track -or $tags.Tag.Track -eq "") {
                $tags.Tag.Track = "$($([datetime]$Episode.pubDate).ToString('yyMMdd'))"
            }
    
            # Year set to pubDate. Discovered some posted years were incorrect ~ couple years behind.
            $year = "$(([datetime]($Episode.pubDate)).Year)"
            if ($null -eq $tags.Tag.Year -or $tags.Tag.Year -eq "" -or $tags.Tag.Year -ne $year) {
                $tags.Tag.Year = $year
            }
        }
        catch {
            throw "Exception thrown when updating tags: $_"
        }

        # Save and exit
        try {
            $tags.Save()
        }
        catch {
            throw "Exception thrown when saving tags: $_"
        }
    }
    Write-Verbose "TagLibSharp library found."
}
else {
    Write-Warning "TagLibSharp library    N O T    found."
}

# Always providing podcasts and a list of episodes from all podcasts.
$script:SELECTED_THUMBNAIL = ""
$PODCASTS = @(Get-Podcasts)
$EPISODES = Format-PodcastsTasks

<#
.SYNOPSIS
Simple GUI for podcast episode browsing.
.DESCRIPTION
The GUI is displayed on the first screen detected.
All episodes listed by default, ordered by release date.
Select a podcast thumbnail to only list those episodes.
.NOTES
Credits and thanks:
    https://learn.microsoft.com/en-us/powershell/module/threadjob/start-threadjob?view=powershell-7.4

    https://stackoverflow.com/questions/32014711/how-do-you-call-windows-explorer-with-a-file-selected-from-powershell

    https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox?view=windowsdesktop-8.0
        https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.flatstyle?view=windowsdesktop-8.0#system-windows-forms-combobox-flatstyle
        https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.drawitem?view=windowsdesktop-8.0#system-windows-forms-combobox-drawitem

    https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.listview.ownerdraw?view=windowsdesktop-8.0&redirectedfrom=MSDN#System_Windows_Forms_ListView_OwnerDraw

    https://colorkit.co/
#>
if ($GUI) {
    <# GUI SETUP - LAUNCHING HAPPENS AFTER THESE DEFINITIONS #>
    Write-Verbose "GUI was requested. Loading . . ."
    try {
        Add-Type -assembly System.Windows.Forms
    }
    catch {
        Write-Verbose "Failed to load windows forms assembly: $($_.ToString())"
        throw $_
    }
    
    if (!$PTITLE_COL_WIDTH) { Set-Variable PTITLE_COL_WIDTH -Option Constant -Value 125 }
    if (!$ETITLE_COL_WIDTH) { Set-Variable ETITLE_COL_WIDTH -Option Constant -Value 300 }
    if (!$LENGTH_COL_WIDTH) { Set-Variable LENGTH_COL_WIDTH -Option Constant -Value 80 }
    if (!$DATE_COL_WIDTH) { Set-Variable DATE_COL_WIDTH -Option Constant -Value 100 }

    if (!$SCREEN) { Set-Variable SCREEN -Option Constant -Value $([System.Windows.Forms.Screen]::AllScreens) }
    if (!$MAX_SCREEN_WIDTH) { Set-Variable MAX_SCREEN_WIDTH -Option Constant -Value $($SCREEN[0].Bounds.Size.Width) }
    if (!$MAX_SCREEN_HEIGHT) { Set-Variable MAX_SCREEN_HEIGHT -Option Constant -Value $($SCREEN[0].Bounds.Size.Height) }

    if (!$SCREEN_WIDTH_25P) { Set-Variable SCREEN_WIDTH_25P -Option Constant -Value $([UInt16]($MAX_SCREEN_WIDTH / 4)) }
    if (!$SCREEN_WIDTH_50P) { Set-Variable SCREEN_WIDTH_50P -Option Constant -Value $([UInt16]($MAX_SCREEN_WIDTH / 2)) }
    if (!$SCREEN_WIDTH_75P) { Set-Variable SCREEN_WIDTH_75P -Option Constant -Value $([UInt16]($SCREEN_WIDTH_25P * 3)) }
    if (!$SCREEN_WIDTH_05P) { Set-Variable SCREEN_WIDTH_05P -Option Constant -Value $([UInt16]($SCREEN_WIDTH_25P / 5)) }
    if (!$SCREEN_WIDTH_10P) { Set-Variable SCREEN_WIDTH_10P -Option Constant -Value $([UInt16]($SCREEN_WIDTH_05P * 2)) }


    if (!$SCREEN_HEIGHT_25P) { Set-Variable SCREEN_HEIGHT_25P -Option Constant -Value $([UInt16]($MAX_SCREEN_HEIGHT / 4)) }
    if (!$SCREEN_HEIGHT_50P) { Set-Variable SCREEN_HEIGHT_50P -Option Constant -Value $([UInt16]($MAX_SCREEN_HEIGHT / 2)) }
    if (!$SCREEN_HEIGHT_75P) { Set-Variable SCREEN_HEIGHT_75P -Option Constant -Value $([UInt16]($SCREEN_HEIGHT_25P * 3)) }

    if (!$ICON_SIZE_SQUARE) { Set-Variable ICON_SIZE_SQUARE -Option Constant -Value 35 }

    if (!$BACK_DARKEST) { Set-Variable BACK_DARKEST -Option Constant -Value "#151718" }
    if (!$FORE_LIGHTEST) { Set-Variable FORE_LIGHTEST -Option Constant -Value "#C8C3BC" }

    if (!$BACK_DARK) { Set-Variable BACK_DARK -Option Constant -Value "#1E2021" }
    if (!$FORE_LIGHT) { Set-Variable FORE_LIGHT -Option Constant -Value "#CFE3EC" }

    if (!$BACK_LIGHTBLUE) { Set-Variable BACK_LIGHTBLUE -Option Constant -Value "#007FD3" }
    if (!$FORE_DARKBLUE) { Set-Variable FORE_DARKBLUE -Option Constant -Value "#001929" }

    if (!$BACK_LIGHTGREEN) { Set-Variable BACK_LIGHTGREEN -Option Constant -Value "#00D377" }
    if (!$FORE_DARKGREEN) { Set-Variable FORE_DARKGREEN -Option Constant -Value "#002917" }

    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = 'None' # Disables default menubar. Must override or use alt+F4 to close.
    $form.Size = New-Object System.Drawing.Size($SCREEN_WIDTH_75P, $SCREEN_HEIGHT_75P)
    $form.BackColor = $BACK_DARKEST
    $form.ForeColor = $FORE_LIGHTEST
    $form.Text = "Podcasts"
    $form.Icon = [System.Drawing.Icon]::FromHandle([System.Drawing.Bitmap]::FromStream(`
                [System.IO.MemoryStream]::new($([System.IO.File]::ReadAllBytes(`
                        $(Get-IconPath))))).GetHicon())

    $titleIcon = New-Object System.Windows.Forms.PictureBox
    $titleIcon.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
    $titleIcon.Margin = 0
    $titleIcon.Padding = 0
    $titleIcon.Width = $ICON_SIZE_SQUARE
    $titleIcon.Height = $ICON_SIZE_SQUARE
    $titleIcon.SizeMode = 'Zoom'
    $titleIcon.Image = [System.Drawing.Image]::FromFile($(Get-IconPath))

    $newEpisodesButton = New-Object System.Windows.Forms.Button
    $newEpisodesButton.FlatStyle = 'Flat'
    $newEpisodesButton.FlatAppearance.BorderSize = 0
    $newEpisodesButton.Text = "Newest Episodes"
    $newEpisodesButton.TextAlign = 'MiddleCenter'
    $newEpisodesButton.BackColor = $BACK_LIGHTBLUE
    $newEpisodesButton.ForeColor = $FORE_DARKBLUE
    $newEpisodesButton.Padding = 0
    $newEpisodesButton.Margin = 0
    $newEpisodesButton.Size = New-Object System.Drawing.Size($SCREEN_WIDTH_10P, $titleIcon.Size.Height)
    $newEpisodesButtonToolTip = New-Object System.Windows.Forms.ToolTip
    $newEpisodesButtonToolTip.SetToolTip($newEpisodesButton, "Lists all episodes not found locally, or 'new' episodes.")
    $newEpisodesButton.Add_Click({
            if ($null -eq $EPISODES.new -or 0 -eq $EPISODES.new.Count) {
                Show-InfoMessage -Title "No new episodes" -Message "There aren't any new episodes."
            } else {
                Reset-PodcastsThumbnailBorder
                Update-ListViewWithPodcastTitleEpisodes -Handle $episodesListView -Episode $EPISODES.new
            }
        })
    
    $weekEpisodesButton = New-Object System.Windows.Forms.Button
    $weekEpisodesButton.FlatStyle = 'Flat'
    $weekEpisodesButton.FlatAppearance.BorderSize = 0
    $weekEpisodesButton.Text = "Weeks Episodes"
    $weekEpisodesButton.TextAlign = 'MiddleCenter'
    $weekEpisodesButton.BackColor = $BACK_LIGHTBLUE
    $weekEpisodesButton.ForeColor = $FORE_DARKBLUE
    $weekEpisodesButton.Padding = 0
    $weekEpisodesButton.Margin = 0
    $weekEpisodesButton.Size = New-Object System.Drawing.Size($SCREEN_WIDTH_10P, $titleIcon.Size.Height)
    $weekEpisodesButtonToolTip = New-Object System.Windows.Forms.ToolTip
    $weekEpisodesButtonToolTip.SetToolTip($weekEpisodesButton, "Lists all episodes published within the last week.")
    $weekEpisodesButton.Add_Click({
            if ($null -eq $WEEKS_EPISODES -or 0 -eq $WEEKS_EPISODES.Count) {
                Show-InfoMessage -Title "No weekly episodes" -Message "There aren't any episodes from the last week."
            } else {
                Reset-PodcastsThumbnailBorder
                Update-ListViewWithPodcastTitleEpisodes -Handle $episodesListView -Episode $WEEKS_EPISODES
            }
        })

    $saveEpisodesButton = New-Object System.Windows.Forms.Button
    $saveEpisodesButton.FlatStyle = 'Flat'
    $saveEpisodesButton.FlatAppearance.BorderSize = 0
    $saveEpisodesButton.Text = "Save Episodes"
    $saveEpisodesButton.TextAlign = 'MiddleCenter'
    $saveEpisodesButton.BackColor = $BACK_LIGHTBLUE
    $saveEpisodesButton.ForeColor = $FORE_DARKBLUE
    $saveEpisodesButton.Padding = 0
    $saveEpisodesButton.Margin = 0
    $saveEpisodesButton.Size = New-Object System.Drawing.Size($SCREEN_WIDTH_10P, $titleIcon.Size.Height)
    $saveEpisodesButtonToolTip = New-Object System.Windows.Forms.ToolTip
    $saveEpisodesButtonToolTip.SetToolTip($saveEpisodesButton, "Saves all episodes. Used for new episode comparison upon next application launch.")
    $saveEpisodesButton.Add_Click({
            $form.Enabled = $false
            Save-Episodes -Episodes $EPISODES.all -File $(Get-EpisodesFilePath)
            $form.Enabled = $true
        })

    $menuButtonsFlowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $menuButtonsFlowPanel.Dock = 'Fill'
    $menuButtonsFlowPanel.FlowDirection = 'LeftToRight'
    $menuButtonsFlowPanel.Margin = 0
    $menuButtonsFlowPanel.Padding = 0
    [void] $menuButtonsFlowPanel.Controls.Add($titleIcon)
    [void] $menuButtonsFlowPanel.Controls.Add($newEpisodesButton)
    [void] $menuButtonsFlowPanel.Controls.Add($weekEpisodesButton)
    [void] $menuButtonsFlowPanel.Controls.Add($saveEpisodesButton)

    <#
    Minimize menu bottom.
    .NOTES
    Set the margin and padding to 0 to ensure multiple buttons are touching each other and no menu gap.
    Setting dock for one button has no effect. Setting on both they disappear.
    #>
    $minmizeButton = New-Object System.Windows.Forms.Button
    $minmizeButton.FlatStyle = 'Flat'
    $minmizeButton.FlatAppearance.BorderSize = 0
    $minmizeButton.Text = "―"
    $minmizeButton.TextAlign = 'MiddleCenter'
    $minmizeButton.BackColor = $BACK_LIGHTBLUE
    $minmizeButton.ForeColor = $FORE_DARKBLUE
    $minmizeButton.Padding = 0
    $minmizeButton.Margin = 0
    $minmizeButton.Height = $titleIcon.Size.Height
    $minmizeButtonToolTip = New-Object System.Windows.Forms.ToolTip
    $minmizeButtonToolTip.SetToolTip($minmizeButton, "Minimize")
    $minmizeButton.Add_Click({
            $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
        })

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.FlatStyle = 'Flat'
    $closeButton.FlatAppearance.BorderSize = 0
    $closeButton.Text = "X"
    $closeButton.TextAlign = 'MiddleCenter'
    $closeButton.BackColor = $BACK_LIGHTBLUE
    $closeButton.ForeColor = $FORE_DARKBLUE
    $closeButton.Padding = 0
    $closeButton.Margin = 0
    $closeButton.Height = $titleIcon.Size.Height
    $closeButtonTooltip = New-Object System.Windows.Forms.ToolTip
    $closeButtonTooltip.SetToolTip($closeButton, "Close")
    $closeButton.Add_Click({
            Write-Verbose "Requested GUI to close . . ."
            $form.Close()
        })

    <#
    Panel containing top right menu bottoms.
    .NOTES
    Anchor didn't matter until specifying the flow direction. 
    The flow direction reverses the items order.
    Set the margin and padding to 0 to ensure same height as the title icon.    
    #>
    $closeAndMinimizeButtonsFlowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $closeAndMinimizeButtonsFlowPanel.Anchor = 'Right'
    $closeAndMinimizeButtonsFlowPanel.FlowDirection = 'RightToLeft'
    $closeAndMinimizeButtonsFlowPanel.Margin = 0
    $closeAndMinimizeButtonsFlowPanel.Padding = 0
    [void] $closeAndMinimizeButtonsFlowPanel.Controls.Add($closeButton)
    [void] $closeAndMinimizeButtonsFlowPanel.Controls.Add($minmizeButton)

    # Overriding default menu appearance, and controls.
    $menu = new-object System.Windows.Forms.TableLayoutPanel
    $menu.ColumnCount = 3
    [void] $menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
    [void] $menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
    $menu.BackColor = $BACK_DARKEST
    $menu.Size = New-Object System.Drawing.Size($form.Size.Width, $titleIcon.Height)
    $menu.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
    $menu.Dock = [System.Windows.Forms.DockStyle]::Top
    # [void] $menu.Controls.Add($titleIcon, 0, 0) 
    [void] $menu.Controls.Add($menuButtonsFlowPanel, 0, 0) # ($Control, $ColumnIndex, $RowIndex)
    [void] $menu.Controls.Add($closeAndMinimizeButtonsFlowPanel, 1, 0)
    $menu.Add_MouseDown({
            param($s, $e)
            if ($e.Button -eq [Windows.Forms.MouseButtons]::Left) {
                $script:mouseDownOnMenu = $true
                $script:lastLocationMenu = $form.PointToScreen($e.Location)
            }
        })
    $menu.Add_MouseMove({
            param($s, $e)
            if ($script:mouseDownOnMenu) {
                $currentLocation = $form.PointToScreen($e.Location)
                $offset = New-Object Drawing.Point(
                ($currentLocation.X - $script:lastLocationMenu.X),
                ($currentLocation.Y - $script:lastLocationMenu.Y)
                )
                $form.Location = New-Object Drawing.Point(
                ($form.Location.X + $offset.X),
                ($form.Location.Y + $offset.Y)
                )
                $script:lastLocationMenu = $currentLocation
            }
        })
    $menu.Add_MouseUp({
            param($s, $e)
            $script:mouseDownOnMenu = $false
        })
    $script:mouseDownOnMenu = $false # Used for moving window.
    $script:lastLocationMenu = New-Object Drawing.Point # Used for moving window.

    <# Thumbnails #>
    if (!$THUMB_SIZE_SQUARE) { Set-Variable THUMB_SIZE_SQUARE -Option Constant -Value 100 }
    if (!$THUMB_SPACER) { Set-Variable THUMB_SPACER -Option Constant -Value 70 } # Manually determined.
    if (!$THUMB_TO_SHOW_AT_START) { Set-Variable THUMB_TO_SHOW_AT_START -Option Constant -Value 4 }
    $podcastsThumbnailFlowPanelWidth = (($THUMB_TO_SHOW_AT_START * $THUMB_SIZE_SQUARE) + $THUMB_SPACER)
    $podcastsThumbnailFlowPanelHeight = ($form.Height - $menu.Size.Height)
    $podcastsThumbnailFlowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $podcastsThumbnailFlowPanel.AutoScroll = $true
    $podcastsThumbnailFlowPanel.Size = New-Object System.Drawing.Size($podcastsThumbnailFlowPanelWidth, $podcastsThumbnailFlowPanelHeight)
    $podcastsThumbnailFlowPanel.BackColor = $BACK_DARK
    $podcastsThumbnailFlowPanel.ForeColor = $FORE_LIGHT
    $podcastsThumbnailFlowPanel.Margin = 0
    $podcastsThumbnailFlowPanel.Padding = 0
    $podcastsThumbnailFlowPanel.Dock = 'Fill'
    $podcastsThumbnailFlowPanel.FlowDirection = 'LeftToRight'
    $podcastsThumbnailFlowPanel.TabIndex = 1

    <# Episode #>
    $episodeInfoSytle = @"
<style>
    body {
        background-color: #1E2021;
        font-family: verdana;
        font-size: 100%;
        color: #CFE3EC;
    }
    h1, h2, h3, h5, h6    {
        font-family: Helvetica;
        color: #007FD3;
    }
    p    {
        font-family: verdana;
        font-size: 100%;
        color: #CFE3EC;
    }
    a {
        font-family: Monaco;
        font-weight: bold;
        font-size: 80%;
        color: #00D377;
    }
</style>
"@
    $episodeInfoDefaultDocumentText = ($episodeInfoSytle + `
            "<p>When the application loads, the episode list will contain the newest episodes for all podcasts. " + `
            "If no new episodes are found then those published within the last week will be listed.</p>" + `
            "<p>To show all episodes for a specific podcast, simply click on the podcast's thumbnail (left).</p> " + `
            "<p>If no episodes are listed follow instructions provided in the README for adding a podcast. " + `
            "Relaunch the application for changes to take affect.</p>")
    $episodeInfo = New-Object System.Windows.Forms.WebBrowser
    $episodeInfo.Dock = 'Fill'
    $episodeInfo.DocumentText = $episodeInfoDefaultDocumentText
    $episodeInfo.TabIndex = 1

    $episodesListView = New-Object System.Windows.Forms.ListView
    $episodesListView.Dock = 'Fill'
    $episodesListView.BorderStyle = 'None'
    $episodesListView.BackColor = $BACK_DARK
    $episodesListView.ForeColor = $FORE_LIGHT
    $episodesListView.HeaderStyle = 'Nonclickable'
    $episodesListView.View = 'Details'
    $episodesListView.FullRowSelect = $true
    $episodesListView.MultiSelect = $false
    $episodesListView.TabIndex = 0
    $episodesListView.Add_SelectedIndexChanged({
            # Displaying episode information for selected episode.
            param($s, $e)
            # Do nothing when the event fires due to de-selecting previous
            if (0 -eq $s.SelectedItems.Count) {
                return
            }
            # Obtain the specific episode information and display it.
            $episode = @{}
            if ("" -ne $script:SELECTED_THUMBNAIL) {
                $episode = $EPISODES.all | Where-Object { ($_.podcast_title -eq $script:SELECTED_THUMBNAIL) -and ($_.title -eq $s.SelectedItems.subItems[0].Text) }
            }
            else {
                $episode = $EPISODES.all | Where-Object { ($_.podcast_title -eq $s.SelectedItems.subItems[0].Text) -and ($_.title -eq $s.SelectedItems.subItems[1].Text) }
            }
            $author = $(($episode.author) ? "<h3>$($episode.author)</h3>" : "" )
            $info = "<h2>$($episode.title)</h2>$author<h4>$($episode.podcast_title)</h4>" + `
                "<p><a href='$($episode.enclosure.url)'>Navigate to Episode URL</a></p>"
            if ($episode.encoded) {
                $episodeInfo.DocumentText = $episodeInfoSytle + $info + $episode.encoded
            }
            else {
                $episodeInfo.DocumentText = $episodeInfoSytle + $info + $episode.description
            }
        })

    <# Bottom Panel #>
    $episodePlayButtonBackColor = "#ffa800"
    $episodePlayButtonForeColor = "#212121"
    $episodeStreamInVlcButton = New-Object System.Windows.Forms.Button
    $episodeStreamInVlcButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $episodeStreamInVlcButton.Text = " Stream in VLC "
    $episodeStreamInVlcButton.FlatStyle = 'Flat'
    $episodeStreamInVlcButton.FlatAppearance.BorderSize = 1
    $episodeStreamInVlcButton.FlatAppearance.BorderColor = "#222222"
    $episodeStreamInVlcButton.BackColor = $episodePlayButtonBackColor
    $episodeStreamInVlcButton.ForeColor = $episodePlayButtonForeColor
    $episodeStreamInVlcButton.AutoSize = $true
    $episodeStreamInVlcButton.Add_Click({
            param($s, $e)
            # Report when no episode is selected.
            if (-1 -eq $episodesListView.SelectedItems) {
                $t = “Select an episode”
                $m = "An episode must be selected in order to stream it."
                Show-InfoMessage -Title $t -Message $m
                return
            }
            try {
                $to_stream = Get-SelectedEpisode
                if ($null -ne $to_stream -and $null -ne $to_stream.enclosure.url) {
                    Write-Verbose "Requested to stream '$($to_stream.title)' . . . "
                    $rate = [Single]$(Get-RateSlider)
                    Invoke-VlcStream -Rate $rate -Episode $to_stream
                }
                else {
                    Show-InfoMessage -Title "Unknown Episode" -Message "The episode data provided was incomplete. Restart the application and try again."
                }
            }
            catch {
                Show-InfoMessage -Title "Unable to Stream" -Message "Failed to stream episode using VLC. $($_.ToString())"
            }
        })

    $episodeDownloadPlayButtonBackColor = "#ffa800"
    $episodeDownloadPlayButtonForeColor = "#212121"
    $episodeDownloadPlayButton = New-Object System.Windows.Forms.Button
    $episodeDownloadPlayButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $episodeDownloadPlayButton.Text = " Download and play in VLC "
    $episodeDownloadPlayButton.FlatStyle = 'Flat'
    $episodeDownloadPlayButton.FlatAppearance.BorderSize = 1
    $episodeDownloadPlayButton.FlatAppearance.BorderColor = "#222222"
    $episodeDownloadPlayButton.BackColor = $episodeDownloadPlayButtonBackColor
    $episodeDownloadPlayButton.ForeColor = $episodeDownloadPlayButtonForeColor
    $episodeDownloadPlayButton.AutoSize = $true
    $episodeDownloadPlayButton.Add_Click({
            param($s, $e)
            # Report when no episode is selected.
            if (-1 -eq $episodesListView.SelectedItems) {
                $t = “Select an episode”
                $m = "An episode must be selected in order to download and then play it."
                Show-InfoMessage -Title $t -Message $m
                return
            }
            # Download
            try {
                $to_download = Get-SelectedEpisode
                if ($null -ne $to_download -and $null -ne $to_download.enclosure.url) {
                    Write-Verbose "Requested to download and play '$($to_download.title)' . . ."
                    $file = Get-EpisodeDownloadFileName -Name $to_download.title
                    $download = ""
                    if (Test-Path -Path $file -PathType Leaf) {
                        Write-Verbose "$file already exists."
                        $download = $file
                    }
                    else {
                        $download = Invoke-Download -URI $to_download.enclosure.url -File $file
                        if ( $script:LOADED_TAG_LIB_SHARP ) {
                            Update-PodcastEpisodeTags -Episode $to_download -File $download
                        }
                    }
                }
                else {
                    Show-InfoMessage -Title "Unknown URL" -Message "The episode selected doesn't contain an URL at the expected location. Try accessing it through the console."
                    return
                }
            }
            catch {
                Show-InfoMessage -Title "Download Failed" -Message "Unable to download the episode. $($_.ToString())"
                return
            }
            # VLC
            try {
                $rate = [Single]$(Get-RateSlider)
                Invoke-Vlc -Rate $rate -File $download
            }
            catch {
                Show-InfoMessage -Title "VLC Failed" -Message "Unable to play media with VLC. $($_.ToString())"
            }
        })

    $episodeDownloadButtonBackColor = "#323232"
    $episodeDownloadButtonForeColor = "#bebebe"
    $episodeDownloadButton = New-Object System.Windows.Forms.Button
    $episodeDownloadButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $episodeDownloadButton.Text = " Download "
    $episodeDownloadButton.FlatStyle = 'Flat'
    $episodeDownloadButton.FlatAppearance.BorderSize = 1
    $episodeDownloadButton.FlatAppearance.BorderColor = "#222222"
    $episodeDownloadButton.BackColor = $episodeDownloadButtonBackColor
    $episodeDownloadButton.ForeColor = $episodeDownloadButtonForeColor
    $episodeDownloadButton.AutoSize = $true
    $episodeDownloadButton.Add_Click({
            param($s, $e)
            # Report when no episode is selected.
            if (-1 -eq $episodesListView.SelectedItems) {
                $t = “Select an episode”
                $m = "An episode must be selected in order to download it."
                Show-InfoMessage -Title $t -Message $m
                return
            }
            try {
                $to_download = Get-SelectedEpisode
                if ($null -ne $to_download -and $null -ne $to_download.enclosure.url) {
                    Write-Verbose "Requested to download '$($to_download.title)' . . ."
                    $file = Get-EpisodeDownloadFileName -Name $to_download.title
                    $download = ""
                    if (Test-Path -Path $file -PathType Leaf) {
                        Write-Verbose "$file already exists."
                        return
                    }
                    $download = Invoke-Download -URI $to_download.enclosure.url -File $file
                    if ( $script:LOADED_TAG_LIB_SHARP ) {
                        Update-PodcastEpisodeTags -Episode $to_download -File $download
                    }
                }
                else {
                    Show-InfoMessage -Title "Unknown URL" -Message "The episode selected doesn't contain an URL at the expected location. Try accessing it through the console."
                }
            }
            catch {
                Show-InfoMessage -Title "Download Failed" "Unable to download the episode. $($_.ToString())"
            }
        })

    $episodeRevealInFileExplorerButtonBackColor = "#323232"
    $episodeRevealInFileExplorerButtonForeColor = "#bebebe"
    $episodeRevealInFileExplorerButton = New-Object System.Windows.Forms.Button
    $episodeRevealInFileExplorerButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $episodeRevealInFileExplorerButton.Text = " Reveal in File Explorer "
    $episodeRevealInFileExplorerButton.FlatStyle = 'Flat'
    $episodeRevealInFileExplorerButton.FlatAppearance.BorderSize = 1
    $episodeRevealInFileExplorerButton.FlatAppearance.BorderColor = "#222222"
    $episodeRevealInFileExplorerButton.BackColor = $episodeRevealInFileExplorerButtonBackColor
    $episodeRevealInFileExplorerButton.ForeColor = $episodeRevealInFileExplorerButtonForeColor
    $episodeRevealInFileExplorerButton.AutoSize = $true
    $episodeRevealInFileExplorerButton.Add_Click({
            param($s, $e)
            # Report when no episode is selected.
            if (-1 -eq $episodesListView.SelectedItems) {
                $t = “Select an episode”
                $m = "An episode must be selected in order to reveal it in file explorer."
                Show-InfoMessage -Title $t -Message $m
                return
            }
            $file = Get-EpisodeDownloadFileName -Name $(Get-SelectedEpisode).title
            if ($file.Contains('Microsoft.PowerShell.Core\FileSystem::')) {
                $file = $file.Replace('Microsoft.PowerShell.Core\FileSystem::', '')
            }
            if ( Test-Path -PathType Leaf -Path $file ) {
                Write-Verbose "Requested to reveal '$file' . . ."
                Start-Process explorer.exe -ArgumentList "/select, ""$file"""
            }
            else {
                $t = “Episode not found”
                $m = "A file for the selected episode was not found. Try downloading it first."
                Show-InfoMessage -Title $t -Message $m
                return
            }
        })

    $playButtonsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $playButtonsPanel.Margin = 0
    $playButtonsPanel.Padding = 0
    $playButtonsPanel.Dock = 'Bottom'
    $playButtonsPanel.Size = New-Object Drawing.Size @(250, 37)
    [void] $playButtonsPanel.Controls.Add($episodeStreamInVlcButton)
    [void] $playButtonsPanel.Controls.Add($episodeDownloadPlayButton)
    [void] $playButtonsPanel.Controls.Add($episodeDownloadButton)
    [void] $playButtonsPanel.Controls.Add($episodeRevealInFileExplorerButton)

    <# Slider ~ playback rate #>
    if (!$PLAYBACK_RATE_SLIDER_DEFAULT) { Set-Variable PLAYBACK_RATE_SLIDER_DEFAULT -Option Constant -Value 150 } # 150 / 100 ~ 1.5 x
    if (!$PLAYBACK_RATE_SLIDER_DENOMINATOR) { Set-Variable PLAYBACK_RATE_SLIDER_DENOMINATOR -Option Constant -Value 100 }
    if (!$PLAYBACK_RATE_SLIDER_MIN) { Set-Variable PLAYBACK_RATE_SLIDER_MIN -Option Constant -Value 50 }
    if (!$PLAYBACK_RATE_SLIDER_MAX) { Set-Variable PLAYBACK_RATE_SLIDER_MAX -Option Constant -Value 300 }
    if (!$PLAYBACK_RATE_SLIDER_TICK) { Set-Variable PLAYBACK_RATE_SLIDER_TICK -Option Constant -Value 5 }

    $playbackRateFasterButtonBackColor = $BACK_LIGHTBLUE
    $playbackRateFasterButtonForeColor = $FORE_DARKBLUE
    $playbackRateFasterButton = New-Object System.Windows.Forms.Button
    $playbackRateFasterButton.Text = "+"
    $playbackRateFasterButton.FlatStyle = 'Flat'
    $playbackRateFasterButton.FlatAppearance.BorderSize = 0
    $playbackRateFasterButton.BackColor = $playbackRateFasterButtonBackColor
    $playbackRateFasterButton.ForeColor = $playbackRateFasterButtonForeColor
    $playbackRateFasterButton.AutoSize = $true
    $playbackRateFasterButton.Margin = 0
    $playbackRateFasterButton.Padding = 0
    $playbackRateFasterButton.Width = 50
    $playbackRateFasterButton.TextAlign = 'MiddleCenter'
    $playbackRateFasterButton.Font = New-Object Drawing.Font("Arial", 16)
    $playbackRateFasterButton.Add_Click({
            param($s, $e)
            try {
                $playbackRateSlider.Value += 25
            }
            catch {
                $playbackRateSlider.Value = $PLAYBACK_RATE_SLIDER_MAX
            }
            $playbackRateLabelValue.Text = "$(Get-RateSlider)"
        })

    $playbackRateSlowerButtonBackColor = $BACK_LIGHTBLUE
    $playbackRateSlowerButtonForeColor = $FORE_DARKBLUE
    $playbackRateSlowerButton = New-Object System.Windows.Forms.Button
    $playbackRateSlowerButton.Text = "-"
    $playbackRateSlowerButton.FlatStyle = 'Flat'
    $playbackRateSlowerButton.FlatAppearance.BorderSize = 0
    $playbackRateSlowerButton.BackColor = $playbackRateSlowerButtonBackColor
    $playbackRateSlowerButton.ForeColor = $playbackRateSlowerButtonForeColor
    $playbackRateSlowerButton.AutoSize = $true
    $playbackRateSlowerButton.Margin = 0
    $playbackRateSlowerButton.Padding = 0
    $playbackRateSlowerButton.Width = 50
    $playbackRateSlowerButton.TextAlign = 'MiddleCenter'
    $playbackRateSlowerButton.Font = New-Object Drawing.Font("Arial", 16)
    $playbackRateSlowerButton.Add_Click({
            param($s, $e)
            try {
                $playbackRateSlider.Value -= 25
            }
            catch {
                $playbackRateSlider.Value = $PLAYBACK_RATE_SLIDER_MIN
            }
            $playbackRateLabelValue.Text = "$(Get-RateSlider)"
        })

    $playbackRateLabel = New-Object System.Windows.Forms.Label
    $playbackRateLabel.Height = $playbackRateSlider.Height # !!! These definitions are placement dependent !!!
    $playbackRateLabel.Text = "Playback Rate Multiplier"
    $playbackRateLabel.TextAlign = 'MiddleCenter'
    $playbackRateLabel.Size = New-Object System.Drawing.Size(100, 45);
    $playbackRateLabel.Font = New-Object Drawing.Font("Arial", 8)

    $playbackRateSlider = New-Object System.Windows.Forms.TrackBar
    $playbackRateSlider.SetRange($PLAYBACK_RATE_SLIDER_MIN, $PLAYBACK_RATE_SLIDER_MAX)
    $playbackRateSlider.TickFrequency = $PLAYBACK_RATE_SLIDER_TICK
    $playbackRateSlider.Value = $PLAYBACK_RATE_SLIDER_DEFAULT
    $playbackRateSlider.Margin = 0
    $playbackRateSlider.Padding = 0
    $playbackRateSlider.Width = 150
    $playbackRateSlider.AutoSize = $true
    $playbackRateSlider.TickStyle = 'Both'
    $playbackRateSlider.Add_ValueChanged({
            param($s, $e)
            $playbackRateLabelValue.Text = "$(Get-RateSlider)"
        })

    $playbackRateLabelValue = New-Object System.Windows.Forms.TextBox
    $playbackRateLabelValue.BackColor = "#111111"
    $playbackRateLabelValue.ForeColor = "#bebebe"
    $playbackRateLabelValue.BorderStyle = 'None'
    $playbackRateLabelValue.TextAlign = 'center'
    $playbackRateLabelValue.Multiline = $false
    $playbackRateLabelValue.Margin = New-Object Windows.Forms.Padding(0, $($playbackRateSlider.Height / 4), 0, 0) # Centering label
    $playbackRateLabelValue.Font = New-Object Drawing.Font("Arial", 14)
    $playbackRateLabelValue.Width = 50
    $playbackRateLabelValue.MaxLength = 4
    $playbackRateLabelValue.Add_KeyDown({
            param($s, $e)
            if ($e.KeyCode -eq 'Enter') {
                try {
                    $v = [double]($s.Text)
                    if ($v -ge [double]($PLAYBACK_RATE_SLIDER_MAX / $PLAYBACK_RATE_SLIDER_DENOMINATOR)) {
                        $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($PLAYBACK_RATE_SLIDER_MAX / $PLAYBACK_RATE_SLIDER_DENOMINATOR))"
                        $playbackRateSlider.Value = $PLAYBACK_RATE_SLIDER_MAX
                    }
                    elseif ($v -le [double]($PLAYBACK_RATE_SLIDER_MIN / $PLAYBACK_RATE_SLIDER_DENOMINATOR)) {
                        $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($PLAYBACK_RATE_SLIDER_MIN / $PLAYBACK_RATE_SLIDER_DENOMINATOR))"
                        $playbackRateSlider.Value = $PLAYBACK_RATE_SLIDER_MIN
                    }
                    else {
                        $playbackRateLabelValue.Text = "$( "{0:0.00}" -f $v )"
                        $playbackRateSlider.Value = [double]( $v * $PLAYBACK_RATE_SLIDER_DENOMINATOR )
                    }
                }
                catch {
                    $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($PLAYBACK_RATE_SLIDER_DEFAULT / $PLAYBACK_RATE_SLIDER_DENOMINATOR))"
                    $playbackRateSlider.Value = $PLAYBACK_RATE_SLIDER_DEFAULT
                }
            }
        })

    $sliderPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $sliderPanel.Margin = 0
    $sliderPanel.Padding = 0
    $sliderPanel.Dock = 'Bottom'
    $sliderPanel.BackColor = "#1d1d1d"
    $sliderPanel.Size = New-Object Drawing.Size @(250, $playbackRateSlider.Height)
    [void] $sliderPanel.Controls.Add($playbackRateLabel)
    [void] $sliderPanel.Controls.Add($playbackRateSlowerButton)
    [void] $sliderPanel.Controls.Add($playbackRateLabelValue)
    [void] $sliderPanel.Controls.Add($playbackRateSlider)
    [void] $sliderPanel.Controls.Add($playbackRateFasterButton)

    $splitWidth = 9
    $split_spacer = 137 # 79 + 40 + 9 + 9 ~ manually determined.
    $podcastDisplayVsFormWidthRatio = (($podcastsThumbnailFlowPanel.Size.Width + $split_spacer) / $form.Size.Width) * 100
    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Location = New-Object System.Drawing.Point(0, 0);
    $split.Padding = 0
    $split.Margin = 0
    $split.BorderStyle = 'None'
    $split.Dock = 'Fill'
    $split.BackColor = $FORE_DARKBLUE # Color of the vertical bar.
    $split.SplitterWidth = $splitWidth
    $split.SplitterIncrement = 1
    $split.SplitterDistance = $podcastDisplayVsFormWidthRatio
    $split.Panel1.BackColor = $BACK_DARK # Behind the podcast list.
    $split.Panel1.Name = "Podcasts"
    $split.Panel1.Controls.Add($podcastsThumbnailFlowPanel)

    $splitEpisodes = New-Object System.Windows.Forms.SplitContainer
    $splitEpisodes.Dock = 'Fill'
    $splitEpisodes.Orientation = [System.Windows.Forms.Orientation]::Horizontal
    $splitEpisodes.BackColor = $FORE_DARKBLUE
    $splitEpisodes.SplitterDistance = 35
    $splitEpisodes.SplitterWidth = $splitWidth
    $splitEpisodes.Location = New-Object System.Drawing.Point(0, 0);
    $splitEpisodesWidth = ($form.Size.Width - $podcastsThumbnailFlowPanelWidth - $splitWidth) 
    $splitEpisodesHeight = ($form.Size.Height - $menu.Size.Height)
    $splitEpisodes.Size = New-Object System.Drawing.Size ($splitEpisodesWidth, $splitEpisodesHeight)

    $splitEpisodes.Panel1.Controls.Add($episodeInfo)
    $splitEpisodes.Panel1.Name = "Episodes List View"

    $splitEpisodes.Panel2.Controls.Add($episodesListView)
    $splitEpisodes.Panel2.Controls.Add($playButtonsPanel)
    $splitEpisodes.Panel2.Controls.Add($sliderPanel)
    $splitEpisodes.Panel2.Name = "Episode Information"

    $split.Panel2.Controls.Add($splitEpisodes)
    $split.Panel2.BackColor = $FORE_DARKBLUE
    $split.Panel2.Name = "Episodes"

    $form.Controls.Add($split) # Adding split first prevents it from being tucked under the menu.
    $form.Controls.Add($menu)

    $split.ResumeLayout($false);
    $splitEpisodes.ResumeLayout($false);

    <# GUI HELPER METHODS - LAUNCHING HAPPENS AFTER THESE DEFINITIONS #>
    
    function Get-RateSlider {
        "{0:0.00}" -f $([double]([double] $playbackRateSlider.Value / [double]$PLAYBACK_RATE_SLIDER_DENOMINATOR))
    }
    <#
    .SYNOPSIS
    Removes border from all controls of podcast thumbnail flow panel.
    #>
    function Reset-PodcastsThumbnailBorder {
        $podcastsThumbnailFlowPanel.Controls | ForEach-Object { $_.BorderStyle = 'None' }
        $script:SELECTED_THUMBNAIL = ""
    }
    <#
    .SYNOPSIS
    Display information within a MessageBox containing an okay button.
    #>
    function Show-InfoMessage {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [ValidateScript({ $null -ne $_ -and $_.Length -gt 0 })]
            [string] $Title,
            [Parameter(Mandatory)]
            [ValidateScript({ $null -ne $_ -and $_.Length -gt 0 })]
            [string] $Message
        )
        $b = [System.Windows.Forms.MessageBoxButtons]::OK
        $i = [System.Windows.Forms.MessageBoxIcon]::Information
        [System.Windows.Forms.MessageBox]::Show($Message, $Title, $b, $i)
    }
    <#
    .SYNOPSIS
    Return the selected episode no matter what is displayed.
    #>
    function Get-SelectedEpisode() {
        $episode = @{}
        if ("" -ne $script:SELECTED_THUMBNAIL) {
            $et = $episodesListView.SelectedItems.subItems[0].Text
            $episode = $EPISODES.all | Where-Object { ($_.podcast_title -eq $script:SELECTED_THUMBNAIL ) -and ($_.title -eq $et) }
        }
        else {
            $pt = $episodesListView.SelectedItems.subItems[0].Text
            $et = $episodesListView.SelectedItems.subItems[1].Text
            $episode = $EPISODES.all | Where-Object { ($_.podcast_title -eq $pt) -and ($_.title -eq $et) }
        }
        $episode
    }
    <#
    .SYNOPSIS
    Adding podcast thumbnail picture box controls to layout flow panel.
    .NOTES
    Clears flow panel before adding.
    PictureBox Click event added here.
    #>
    function Update-PodcastsThumbnailFlowPanel {
        $podcastsThumbnailFlowPanel.Controls.Clear()
        Foreach ($podcast in $PODCASTS) {
            $pic = New-Object System.Windows.Forms.PictureBox
            $pic.Margin = 0
            $pic.Padding = 0
            $pic.BorderStyle = 'None'
            $pic.Width = $THUMB_SIZE_SQUARE
            $pic.Height = $THUMB_SIZE_SQUARE
            $pic.SizeMode = 'Zoom'
            $path = Get-PodcastThumbnailFileName -Name $podcast.title
            if (Test-Path -Path $path -PathType Leaf) {
                $pic.Image = [System.Drawing.Image]::FromFile($path)
                $pic.Tag = $podcast.title
                $pic.Text = $podcast.title
            }
            else {
                $pic.Tag = $podcast.title
                $pic.Text = $podcast.title
            }
            $pic.Add_Click({
                    param ($s, $e)
                    if ("" -ne $script:SELECTED_THUMBNAIL -and $s.Tag -eq $script:SELECTED_THUMBNAIL) {
                        return
                    }
                    # thumbnails
                    Reset-PodcastsThumbnailBorder -Handle $s.Parent
                    $s.BorderStyle = 'FixedSingle'
                    $script:SELECTED_THUMBNAIL = $s.Tag
                    # episodes
                    $selected_podcast = $EPISODES.all | Where-Object { $_.podcast_title -eq $s.Tag }
                    $episodeInfo.DocumentText = $episodeInfoDefaultDocumentText
                    $episodesListView.Hide()
                    $episodesListView.Clear()
                    [void]$episodesListView.Columns.Add("Episode", $ETITLE_COL_WIDTH)
                    [void]$episodesListView.Columns.Add("Length", $LENGTH_COL_WIDTH)
                    [void]$episodesListView.Columns.Add("Date", $DATE_COL_WIDTH)
                    Foreach ($episode in $selected_podcast) {
                        $item = New-Object system.Windows.Forms.ListViewItem
                        # column 1 - Episode title
                        $item.Text = (($null -eq $episode.title) ? "n/a" : $episode.title)
                        # column 2 - length HH:MM:SS
                        [void] $item.SubItems.Add( ($null -eq $episode.duration) ? "n/a" : $episode.duration)
                        # column 3 - date
                        [void] $item.SubItems.Add( ($null -eq $episode.pubDate) ? "n/a" : "$($episode.pubDate)")
                        [void] $episodesListView.Items.Add($item)
                    }
                    $episodesListView.Items[0].Selected = $true # Selects the first item in the list.
                    $episodesListView.Show()
                })
            [void] $podcastsThumbnailFlowPanel.Controls.Add($pic)
        }
    }
    <#
    .SYNOPSIS
    Update the provided listview handle with episodes from the last week.
    .PARAMETER Episodes
    List expected to contain episode information.
    .NOTES
    The provided listview is cleared before adding items.
    #>
    function Update-ListViewWithPodcastTitleEpisodes {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [System.Windows.Forms.ListView] $Handle,
            [Parameter(Mandatory)]
            [ValidateScript({ 
                    if (-not $_.ContainsKey("podcast_title")) { throw "Missing podcast title key." }
                    if (-not $_.ContainsKey("title")) { throw "Missing episode title key." }
                    $true
                })]
            [array] $Episodes
        )
        $Handle.Clear()
        [void]$Handle.Columns.Add("Podcast", $PTITLE_COL_WIDTH)
        [void]$Handle.Columns.Add("Episode", $ETITLE_COL_WIDTH)
        [void]$Handle.Columns.Add("Length", $LENGTH_COL_WIDTH)
        [void]$Handle.Columns.Add("Date", $DATE_COL_WIDTH)
        foreach ($episode in $Episodes) {
            $item = New-Object system.Windows.Forms.ListViewItem
            # column 1 - Podcast title
            $item.Text = $episode.podcast_title
            # column 2 - Episode title
            [void] $item.SubItems.Add($episode.title)
            # column 3 - Length of episode
            [void] $item.SubItems.Add($null -ne $episode.duration ? "$($episode.duration)" : "n/a")
            # column 4 - date
            [void] $item.SubItems.Add( $null -ne $episode.pubDate ? "$($episode.pubDate)" : "n/a" )
            [void] $Handle.Items.Add($item)
        }
    }

    <# SETUP & LAUNCHING THE GUI #>
    try {
        $WEEKS_EPISODES = @(Get-EpisodesWithinDate -Episodes $EPISODES.all -Published Week)
        if (0 -ne $EPISODES.new.Count) {
            Update-ListViewWithPodcastTitleEpisodes -Handle $episodesListView -Episode $EPISODES.new
        }
        else {
            Update-ListViewWithPodcastTitleEpisodes -Handle $episodesListView -Episode $WEEKS_EPISODES
        }
        Update-PodcastsThumbnailFlowPanel
        $playbackRateLabelValue.Text = "$(Get-RateSlider)"  
        [void] $form.ShowDialog()
    }
    finally {
        Write-Verbose "Disposing of GUI . . ."
        $form.Dispose()
    }
}

# Return data depending of flags provided
if ($ReturnData) {
    return $EPISODES
}

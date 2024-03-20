<#
.SYNOPSIS
GUI script for podcasts. 

.DESCRIPTION
Pulls feeds from 'feeds.json'. 

Once a feed is selected, its respective episodes are saved and listed. 

An episode may be played by selecting it and then clicking on the desired play button.

The rate of playback may also be modified PRIOR to clicking on a play button.

.NOTES
Thanks given to the following:
    https://stackoverflow.com/questions/32014711/how-do-you-call-windows-explorer-with-a-file-selected-from-powershell

    https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox?view=windowsdesktop-8.0
        https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.flatstyle?view=windowsdesktop-8.0#system-windows-forms-combobox-flatstyle
        https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.drawitem?view=windowsdesktop-8.0#system-windows-forms-combobox-drawitem

    https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.listview.ownerdraw?view=windowsdesktop-8.0&redirectedfrom=MSDN#System_Windows_Forms_ListView_OwnerDraw

    https://htmlcolorcodes.com/color-picker/

#>

Add-Type -assembly System.Windows.Forms

. '.\include.ps1' # .\utils.ps1

$script:podcasts = [array]$(Get-Content -Path $FEEDS_FILE -Raw | ConvertFrom-Json -AsHashtable);
$script:episodes = @()
$script:episode = @{}

$screen = [System.Windows.Forms.Screen]::AllScreens
$script:screenWidth = $screen[0].Bounds.Size.Width
$script:screenHeight = $screen[0].Bounds.Size.Height
$screenHeight25p = [int]($script:screenHeight / 4)
$screenHeight50p = [int]($screenHeight25p + $screenHeight25p)
$screenHeight75p = [int]($screenHeight25p + $screenHeight50p)
$screenWidth50p = [int]($script:screenWidth / 2)

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None' # Will prevent minimize and close from appearing; Must override or use alt+F4 to close.
$form.Size = New-Object System.Drawing.Size($screenWidth50p, $screenHeight75p)
$form.BackColor = "#232323"
$form.ForeColor = "#aeaeae"
$form.Text = "Podcasts"

$guiWidth50p = [int]($form.Size.Width / 2)
$menuButtonBColor = "#007FD3"
$menuButtonFColor = "#002035"

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Podcasts"
$titleLabel.Font = New-Object Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = 'MiddleCenter'
$titleLabel.ForeColor = "#cdcdcd"

$minmizeButton = New-Object System.Windows.Forms.Button
$minmizeButton.FlatStyle = 'Flat'
$minmizeButton.FlatAppearance.BorderSize = 0
$minmizeButton.Text = "―"
$minmizeButton.TextAlign = 'MiddleCenter'
$minmizeButton.BackColor = $menuButtonBColor
$minmizeButton.ForeColor = $menuButtonFColor
$minmizeButton.Padding = 0
$minmizeButton.Margin = 0
$minmizeButton.AutoSize = $true
$minmizeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Right
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
$closeButton.BackColor = $menuButtonBColor
$closeButton.ForeColor = $menuButtonFColor
$closeButton.Padding = 0
$closeButton.Margin = 0
$closeButton.AutoSize = $true
$closeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Right
$closeButtonTooltip = New-Object System.Windows.Forms.ToolTip
$closeButtonTooltip.SetToolTip($closeButton, "Close")
$closeButton.Add_Click({ $form.Close() })

# Overriding default menu appearance, and controls.
$menu = new-object System.Windows.Forms.TableLayoutPanel
$menu.ColumnCount = 2
[void] $menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, $guiWidth50p)))
[void] $menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, $guiWidth50p)))
$menu.BackColor = "#343434"
$menu.Size = New-Object System.Drawing.Size($script:screenWidth, ($closeButton.Size.Height + 4))
$menu.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
$menu.Dock = [System.Windows.Forms.DockStyle]::Top

$menuButtonsFlowPlanel = New-Object System.Windows.Forms.FlowLayoutPanel
$menuButtonsFlowPlanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$menuButtonsFlowPlanel.Size = New-Object System.Drawing.Size(($closeButton.Size.Width + $minmizeButton.Size.Width), $menu.Height)
$menuButtonsFlowPlanel.Margin = 0
$menuButtonsFlowPlanel.Padding = 0
[void] $menuButtonsFlowPlanel.Controls.Add($minmizeButton)
[void] $menuButtonsFlowPlanel.Controls.Add($closeButton)

[void] $menu.Controls.Add($titleLabel, 0, 0) # ($Control, $ColumnIndex, $RowIndex)
[void] $menu.Controls.Add($menuButtonsFlowPlanel, 1, 0)

$script:mouseDown = $false
$script:lastLocation = New-Object Drawing.Point
$menu.Add_MouseDown({
        param($s, $e)
        if ($e.Button -eq [Windows.Forms.MouseButtons]::Left) {
            $script:mouseDown = $true
            $script:lastLocation = $form.PointToScreen($e.Location)
        }
    })
$menu.Add_MouseMove({
        param($s, $e)
        if ($script:mouseDown) {
            $currentLocation = $form.PointToScreen($e.Location)
            $offset = New-Object Drawing.Point(
                ($currentLocation.X - $script:lastLocation.X),
                ($currentLocation.Y - $script:lastLocation.Y)
            )

            $form.Location = New-Object Drawing.Point(
                ($form.Location.X + $offset.X),
                ($form.Location.Y + $offset.Y)
            )

            $script:lastLocation = $currentLocation
        }
    })
$menu.Add_MouseUp({
        param($s, $e)
        $script:mouseDown = $false
    })

$podcastsListBoxBackColor = $menuButtonBColor
$podcastsListBoxForeColor = "#1A0B00"
$podcastsListBoxBackColorSelected = "#003253"
$podcastsListBoxForeColorSelected = "#D3BD00"
$podcastsListBox = New-Object System.Windows.Forms.ListBox
$podcastsListBox.Padding = 0
$podcastsListBox.Margin = 0
$podcastsListBox.Dock = 'Fill' # Covering episode refresh button
$podcastsListBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$podcastsListBox.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
$podcastsListBox.Size = New-Object Drawing.Size @(315, ($form.Height - $menu.Size.Height - $episodeCheckButton.Size.Height - 200))
$podcastsListBox.BackColor = $form.BackColor
$podcastsListBox.BorderStyle = 'None'
$podcastsListBox.DrawMode = 'OwnerDrawVariable' # Requires handling MeasureItem and DrawItem.
$podcastsListBox.Add_MeasureItem({
        param($s, $e)
        $e.ItemHeight = 40
        $e.ItemWidth = 150
    })
if ( $script:podcasts.Count -eq 0 ) {
    [void] $podcastsListBox.Items.Add("No Podcasts Found. Update Feeds (feeds.json).")
}
else {
    Foreach ($podcast in $script:podcasts) {
        [void] $podcastsListBox.Items.Add($podcast.title)
    }
}
$podcastsListBox.Add_DrawItem({
        param([Object]$s, [System.Windows.Forms.DrawItemEventArgs]$e)
        # PODCAST LIST UPDATE
        $txt = ""
        if ($e.Index -ge 0) {
            $txt = $podcastsListBox.GetItemText($podcastsListBox.Items[$e.Index])
        }
        else {
            $e.Handled = $true
        }
        if (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected) {
            $font = New-Object System.Drawing.Font("Arial", 10, [Drawing.FontStyle]::Bold)
            $bgBrush = [system.drawing.SolidBrush]::new($podcastsListBoxBackColorSelected)
            try { 
                $e.Graphics.FillRectangle($bgBrush, $e.Bounds)
                [system.windows.forms.TextRenderer]::DrawText($e.Graphics, $txt, $font,
                    $e.Bounds, $podcastsListBoxForeColorSelected, $podcastsListBoxBackColorSelected, 
                        ([System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter))
            }
            finally {
                $bgBrush.Dispose()
            }
        }
        else {
            $bgBrush = [system.drawing.SolidBrush]::new($podcastsListBoxBackColor)
            $font = New-Object System.Drawing.Font("Arial", 10, [Drawing.FontStyle]::Regular)
            try { 
                $e.Graphics.FillRectangle($bgBrush, $e.Bounds)
                [system.windows.forms.TextRenderer]::DrawText($e.Graphics, $txt, $font,
                    $e.Bounds, $podcastsListBoxForeColor, $podcastsListBoxBackColor, 
                        ([System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter))
            }
            finally {
                $bgBrush.Dispose()
            }
        }
    })

$episodeInfoSytle = @"
<style>
    body {
        background-color: #1f1f1f;
        font-family: helvetica;
        font-size: 80%;
        color: #637699;
    }
    p    {
        font-family: verdana;
        font-size: 100%;
        color: #637699;
    }
    a {
        font-weight: bold;
        color: #6E4485;
    }
</style>
"@


$podcastsListBox.Add_SelectedIndexChanged({
        param($s, $e)
        $episodeInfo.DocumentText = ($episodeInfoSytle + `
                "<p>First, select a podcast (left) then select an episode from the generated list (below). " + `
                "If podcasts aren't listed, run the setup.ps1 script followed by the create-update-feeds.ps1 script. " + `
                "</p>")
        $episodesListView.Clear() # Removes all headers & items.
        $podcast = $script:podcasts[$script:podcasts.title.IndexOf($s.Text)]
        $script:episodes = Update-Episodes -Podcast $podcast
        [void]$episodesListView.Columns.Add("Episode", 350)
        [void]$episodesListView.Columns.Add("Date", 150)
        Foreach ($episode in $script:episodes) {
            $item = New-Object system.Windows.Forms.ListViewItem
            $item.Text = $episode.title # Column 1
            $item.SubItems.Add($episode.pubDate) # column 2
            $episodesListView.Items.Add($item)
        }
    })

$episodeCheckButton = New-Object System.Windows.Forms.Button
$episodeCheckButton.Margin = 0
$episodeCheckButton.Padding = 0
$episodeCheckButton.Dock = 'top'
$episodeCheckButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$episodeCheckButton.Text = " Check for new Episodes "
$episodeCheckButton.FlatStyle = 'Flat'
$episodeCheckButton.FlatAppearance.BorderSize = 0
$episodeCheckButton.BackColor = $menuButtonBColor
$episodeCheckButton.ForeColor = $menuButtonFColor
$episodeCheckButton.Font = New-Object Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
$episodeCheckButton.AutoSize = $true
$episodeCheckButtonToolTip = New-Object System.Windows.Forms.ToolTip
$episodeCheckButtonToolTip.SetToolTip($episodeCheckButton, "Using the selected podcast (below), search for new episodes")
$episodeCheckButton.Add_Click({
        param($s, $e)
        if ($null -ne $podcastsListBox.SelectedItem) {
            if ( !$script:episodesRefreshing ) {
                $script:episodesRefreshing = $true
                $episodesListView.Clear() # Removes all headers & items.
                $podcast = $script:podcasts[$script:podcasts.title.IndexOf($podcastsListBox.SelectedItem)]
                write-host "$([char]27 + '[3m')Searching for all episodes of '$($podcast.title)' (as of $(Get-Date)) . . . $([char]27 + '[0m')" -ForegroundColor Gray
                $podcastEpisodesTitle = Approve-String -ToSanitize $podcast.title
                $podcastEpisodesFile = "$EPISODE_PREFIX$podcastEpisodesTitle.json"
                Write-Episodes-To-Json -Episodes $(ConvertFrom-PodcastWebRequestContent -Request $(Get-Podcast-Feed -URI $Podcast.url)) -File $podcastEpisodesFile
                $script:episodes = Get-Podcast-Episode-List -File $podcastEpisodesFile
                [void]$episodesListView.Columns.Add("Episode", 350)
                [void]$episodesListView.Columns.Add("Date", 150)
                Foreach ($episode in $script:episodes) {
                    $item = New-Object system.Windows.Forms.ListViewItem
                    $item.Text = $episode.title # Column 1
                    $item.SubItems.Add($episode.pubDate) # column 2
                    $episodesListView.Items.Add($item)
                }
                $script:episodesRefreshing = $false
            }
            else {
                Write-Host "Please wait while episodes are being gathered."
            }
        }
        else {
            $b = [System.Windows.Forms.MessageBoxButtons]::OK
            $i = [System.Windows.Forms.MessageBoxIcon]::Information
            $m = "Select a podcast (left) in order to check for new episodes."
            $t = “No Podcast Selected”
            [System.Windows.Forms.MessageBox]::Show($m, $t, $b, $i)
        }
    })

$episodeFeedsButton = New-Object System.Windows.Forms.Button
$episodeFeedsButton.Margin = 0
$episodeFeedsButton.Padding = 0
$episodeFeedsButton.Dock = 'top'
$episodeFeedsButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$episodeFeedsButton.Text = " Latest Episodes for All Podcast  "
$episodeFeedsButton.FlatStyle = 'Flat'
$episodeFeedsButton.FlatAppearance.BorderSize = 0
$episodeFeedsButton.BackColor = $menuButtonBColor
$episodeFeedsButton.ForeColor = $menuButtonFColor
$episodeFeedsButton.Font = New-Object Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
$episodeFeedsButton.AutoSize = $true
$episodeFeedsButtonToolTip = New-Object System.Windows.Forms.ToolTip
$episodeFeedsButtonToolTip.SetToolTip($episodeFeedsButton, "List the latest episodes for all podcasts")
$episodeFeedsButton.Add_Click({
        param($s, $e)
        # TODO: list the latest episodes ~ like 10 latest sorted by date; newest first
    })

$podcastsGroup = new-object System.Windows.Forms.GroupBox
$podcastsGroup.Dock = 'fill'
$podcastsGroup.FlatStyle = 'Flat'
$podcastsGroup.Padding = 10
$podcastsGroup.Margin = 0
# $podcastsGroup.Text = "Options"
[void] $podcastsGroup.Controls.Add($podcastsListBox)
[void] $podcastsGroup.Controls.Add($episodeCheckButton)
[void] $podcastsGroup.Controls.Add($episodeFeedsButton)

$episodesListViewBackColor = "#323232"
$episodesListViewForeColor = "#bebebe"
$episodesListView = New-Object System.Windows.Forms.ListView
$episodesListView.Dock = 'Fill'
$episodesListView.BorderStyle = 'None'
$episodesListView.BackColor = $episodesListViewBackColor
$episodesListView.ForeColor = $episodesListViewForeColor
$episodesListView.HeaderStyle = 'Nonclickable'
$episodesListView.View = 'Details'
$episodesListView.FullRowSelect = $true
$episodesListView.MultiSelect = $false
$episodesListView.Add_SelectedIndexChanged({
        param($s, $e)
        $script:episode = $script:episodes[$script:episodes.title.indexof($s.SelectedItems.text)]      
        $info = "<h1>$($script:episode.title)</h1>" + `
        $(($script:episode.author) ? "<h2>$($script:episode.author)</h2>" : "" ) + `
            "<p><a href='$($script:episode.enclosure.url)'>Navigate to Episode URL</a></p>"
        if ($script:episode.encoded) {
            $episodeInfo.DocumentText = $episodeInfoSytle + $info + $script:episode.encoded
        }
        else {
            $episodeInfo.DocumentText = $episodeInfoSytle + $info + $script:episode.description
        }
    })

$episodeInfo = New-Object System.Windows.Forms.WebBrowser
$episodeInfo.Dock = 'Fill'
$episodeInfo.DocumentText = ($episodeInfoSytle + `
        "<p>" + `
        "First, select a podcast (left) then select an episode from the generated list (below). " + `
        "If podcasts aren't listed, run the setup.ps1 script followed by the create-update-feeds.ps1 script. " + `
        "</p>")

$episodePlayButtonBackColor = "#ffa800"
$episodePlayButtonForeColor = "#212121"
$episodePlayButton = New-Object System.Windows.Forms.Button
$episodePlayButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$episodePlayButton.Text = " Stream in VLC "
$episodePlayButton.FlatStyle = 'Flat'
$episodePlayButton.FlatAppearance.BorderSize = 1
$episodePlayButton.FlatAppearance.BorderColor = "#222222"
$episodePlayButton.BackColor = $episodePlayButtonBackColor
$episodePlayButton.ForeColor = $episodePlayButtonForeColor
$episodePlayButton.AutoSize = $true
$episodePlayButton.Add_Click({
        param($s, $e)
        if ($episodesListView.SelectedItems.Count -ne 0) {
            Write-Host "Requested to stream '$($episodesListView.SelectedItems.Text)' ..."
            $url = $script:episode.enclosure.url
            if ( -1 -ne (get-process).ProcessName.indexof('vlc')) {
                Stop-Process -Name 'vlc'
            }
            # --qt-start-minimized `
            & "C:\Program Files\VideoLAN\VLC\vlc.exe" `
                --play-and-exit `
                --rate=$($playbackRateSlider.Value / $playbackRateSliderDenomintator) `
                $url
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
        if ($episodesListView.SelectedItems.Count -ne 0) {
            Write-Host "Requested to download and play '$($episodesListView.SelectedItems.Text)' ..."
            $title = Approve-String -ToSanitize $script:episode.title # TODO: title and file are repeated in three methods
            $file = join-path (Get-location) "${title}.mp3"
            if ($file.Contains('Microsoft.PowerShell.Core\FileSystem::')) {
                $file = $file.Replace('Microsoft.PowerShell.Core\FileSystem::', '')
            }
            if ( !(Test-Path -PathType Leaf -Path $file) ) {
                $url = $script:episode.enclosure.url
                Get-Episode -URI $url -Path $file
            }
            if ( -1 -ne (get-process).ProcessName.indexof('vlc')) {
                Stop-Process -Name 'vlc'
            }
            # --qt-start-minimized `
            & "C:\Program Files\VideoLAN\VLC\vlc.exe" `
                --play-and-exit `
                --rate=$($playbackRateSlider.Value / $playbackRateSliderDenomintator) `
                $file
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
        if ($episodesListView.SelectedItems.Count -ne 0) {
            Write-Host "Requested to download '$($episodesListView.SelectedItems.Text)' ..."
            $title = Approve-String -ToSanitize $script:episode.title
            $file = join-path (Get-location) "${title}.mp3"
            if ( !(Test-Path -PathType Leaf -Path $file) ) {
                $url = $script:episode.enclosure.url
                Get-Episode -URI $url -Path $file
            }
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
        if ($episodesListView.SelectedItems.Count -ne 0) {
            $file = join-path $(Get-location) $($(Approve-String -ToSanitize $script:episode.title) + ".mp3")
            if ($file.Contains('Microsoft.PowerShell.Core\FileSystem::')) {
                $file = $file.Replace('Microsoft.PowerShell.Core\FileSystem::', '')
            }
            if ( Test-Path -PathType Leaf -Path $file ) {
                Write-Host "Requested to reveal '$file' ..."
                Start-Process explorer.exe -ArgumentList "/select, ""$file"""
            }
            else {
                $b = [System.Windows.Forms.MessageBoxButtons]::OK
                $i = [System.Windows.Forms.MessageBoxIcon]::Information
                $m = "A local file for the episode was not found. Ensure it was downloaded and try again."
                $t = “Episode not found”
                [System.Windows.Forms.MessageBox]::Show($m, $t, $b, $i)
            }
        }
    })

$playButtonsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$playButtonsPanel.Margin = 0
$playButtonsPanel.Padding = 0
$playButtonsPanel.Dock = 'Bottom'
$playButtonsPanel.Size = New-Object Drawing.Size @(250, 37)
[void] $playButtonsPanel.Controls.Add($episodePlayButton)
[void] $playButtonsPanel.Controls.Add($episodeDownloadPlayButton)
[void] $playButtonsPanel.Controls.Add($episodeDownloadButton)
[void] $playButtonsPanel.Controls.Add($episodeRevealInFileExplorerButton)


$playbackRateFasterButtonBackColor = $menuButtonBColor
$playbackRateFasterButtonForeColor = $menuButtonFColor
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
            $playbackRateSlider.Value = $playbackRateSliderMax
        }
        $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($playbackRateSlider.Value / $playbackRateSliderDenomintator))"
    })

$playbackRateSlowerButtonBackColor = $menuButtonBColor
$playbackRateSlowerButtonForeColor = $menuButtonFColor
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
            $playbackRateSlider.Value = $playbackRateSliderMin
        }
        $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($playbackRateSlider.Value / $playbackRateSliderDenomintator))"
    })

$playbackRateSliderDefault = 150 # 150/100 == 1.5 x
$playbackRateSliderDenomintator = 100
$playbackRateSliderMin = 50
$playbackRateSliderMax = 300
$playbackRateSliderTick = 5
function getPlaybackRateSliderValue {
    "{0:0.00}" -f $([double]( [double]$playbackRateSlider.Value / [double]$playbackRateSliderDenomintator ))
}

$playbackRateLabel = New-Object System.Windows.Forms.Label
$playbackRateLabel.Height = $playbackRateSlider.Height # !!! These definitions are placement dependent !!!
$playbackRateLabel.Text = "Playback Rate Multiplier"
$playbackRateLabel.TextAlign = 'MiddleCenter'
$playbackRateLabel.Size = New-Object System.Drawing.Size(100, 45);
$playbackRateLabel.Font = New-Object Drawing.Font("Arial", 8)

$playbackRateSlider = New-Object System.Windows.Forms.TrackBar
$playbackRateSlider.SetRange($playbackRateSliderMin, $playbackRateSliderMax)
$playbackRateSlider.TickFrequency = $playbackRateSliderTick
$playbackRateSlider.Value = $playbackRateSliderDefault
$playbackRateSlider.Margin = 0
$playbackRateSlider.Padding = 0
$playbackRateSlider.Width = 150
$playbackRateSlider.AutoSize = $true
$playbackRateSlider.TickStyle = 'Both'
$playbackRateSlider.Add_ValueChanged({
        param($s, $e)
        $playbackRateLabelValue.Text = "$(getPlaybackRateSliderValue)"
    })

$playbackRateLabelValue = New-Object System.Windows.Forms.TextBox
$playbackRateLabelValue.Text = "$(getPlaybackRateSliderValue)"
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
                if ($v -ge [double]($playbackRateSliderMax / $playbackRateSliderDenomintator)) {
                    $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($playbackRateSliderMax / $playbackRateSliderDenomintator))"
                    $playbackRateSlider.Value = $playbackRateSliderMax
                }
                elseif ($v -le [double]($playbackRateSliderMin / $playbackRateSliderDenomintator)) {
                    $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($playbackRateSliderMin / $playbackRateSliderDenomintator))"
                    $playbackRateSlider.Value = $playbackRateSliderMin
                }
                else {
                    $playbackRateLabelValue.Text = "$( "{0:0.00}" -f $v )"
                    $playbackRateSlider.Value = [double]( $v * $playbackRateSliderDenomintator )
                }
            }
            catch {
                $playbackRateLabelValue.Text = "$( "{0:0.00}" -f ($playbackRateSliderDefault / $playbackRateSliderDenomintator))"
                $playbackRateSlider.Value = $playbackRateSliderDefault
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


$split = New-Object System.Windows.Forms.SplitContainer
$split.Location = New-Object System.Drawing.Point(0, 0);
$split.Dock = 'Fill'
$split.BackColor = "#222222" # Color of the vertical bar.
$split.TabIndex = 0
$split.SplitterWidth = 9

$split.Panel1.BackColor = "#323232" # Behind the podcast list.
$split.Panel1.Name = "Podcasts"
$split.Panel1.Controls.Add($podcastsGroup)
$podcastsListBox.TabIndex = 1

$splitEpisodes = New-Object System.Windows.Forms.SplitContainer
$splitEpisodes.Dock = 'Fill'
$splitEpisodes.Orientation = [System.Windows.Forms.Orientation]::Horizontal
$splitEpisodes.SplitterDistance = 35
$splitEpisodes.TabIndex = 2
$splitEpisodes.SplitterWidth = 3 
$splitEpisodes.Location = New-Object System.Drawing.Point(0, 0);
$splitEpisodes.Size = New-Object System.Drawing.Size(500, 500);

$splitEpisodes.Panel1.Controls.Add($episodeInfo)
$splitEpisodes.Panel1.Name = "Episodes List View"
$episodesListView.TabIndex = 3

$splitEpisodes.Panel2.Controls.Add($episodesListView)
$splitEpisodes.Panel2.Controls.Add($playButtonsPanel)
$splitEpisodes.Panel2.Controls.Add($sliderPanel)

$splitEpisodes.Panel2.Name = "Episode Information"

$split.Panel2.Controls.Add($splitEpisodes)
$split.Panel2.BackColor = "#222222" # Color of the horizontal bar.
$split.Panel2.Name = "Episodes"

$form.Controls.Add($split) # Adding split first prevents it from being tucked under the menu.
$form.Controls.Add($menu)

$split.ResumeLayout($false);
$splitEpisodes.ResumeLayout($false);

try {
    [void] $form.ShowDialog()
}
finally {
    $form.Dispose()
}

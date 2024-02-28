# https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.listview.ownerdraw?view=windowsdesktop-8.0&redirectedfrom=MSDN#System_Windows_Forms_ListView_OwnerDraw

# https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox?view=windowsdesktop-8.0
#  * https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.flatstyle?view=windowsdesktop-8.0#system-windows-forms-combobox-flatstyle
#  * https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.drawitem?view=windowsdesktop-8.0#system-windows-forms-combobox-drawitem

Add-Type -assembly System.Windows.Forms

$settings_file = 'conf.json'
$settings = $(get-content -Path $settings_file -Raw | ConvertFrom-Json)

. .\utils.ps1

$script:podcasts = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable);
$script:episodes = @()
$script:episode = @{}


$screen = [System.Windows.Forms.Screen]::AllScreens
$script:screenWidth = $screen[0].Bounds.Size.Width  
$script:screenHeight = $screen[0].Bounds.Size.Height
$screenHeight50p = [int]($script:screenHeight / 2)
$screenWidth50p = [int]($script:screenWidth / 2)

# https://stackoverflow.com/questions/72988434/how-to-make-winform-use-the-system-dark-mode-theme
# int trueValue = 0x01, falseValue = 0x00;
# SetWindowTheme(this.Handle, "DarkMode_Explorer", null);
# DwmSetWindowAttribute(this.Handle, DwmWindowAttribute.DWMWA_USE_IMMERSIVE_DARK_MODE, $true, Marshal.SizeOf(typeof(int)));
# DwmSetWindowAttribute(this.Handle, DwmWindowAttribute.DWMWA_MICA_EFFECT, $true, Marshal.SizeOf(typeof(int)));

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None' # Will prevent minimize and close from appearing; Must override or use alt+F4 to close.
$form.Size = New-Object System.Drawing.Size($screenWidth50p, $screenHeight50p)
$form.BackColor = "#232323"
$form.ForeColor = "#aeaeae"
$form.Text = "Podcasts"

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Podcasts"
$titleLabel.Font = New-Object Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = 'MiddleCenter'
$titleLabel.ForeColor = "#cdcdcd"
# $titleLabel.Anchor = ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left)
$titleLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left
$titleLabel.AutoSize = $true

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.FlatStyle = 'Flat'
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Text = " X "
$closeButton.TextAlign = 'MiddleCenter'
$closeButton.Add_Click({ $form.Close() })
$closeButton.BackColor = "#990000"
$closeButton.ForeColor = "#efefef"
$closeButton.Padding = 0
$closeButton.Margin = 0
# $closeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$closeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Right
$closeButton.AutoSize = $true
$closeButtonTooltip = New-Object System.Windows.Forms.ToolTip
$closeButtonTooltip.SetToolTip($closeButton, "Close")

# Overriding default menu appearance, and controls.
$menu = new-object System.Windows.Forms.TableLayoutPanel
$menu.BackColor = "#343434"
$menu.Size = New-Object System.Drawing.Size($script:screenWidth, ($closeButton.Size.Height + 4))
$menu.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
$menu.Dock = [System.Windows.Forms.DockStyle]::Top
# $TableLayoutPanel.Controls.Add($Control, $ColumnIndex, $RowIndex)
[void]$menu.Controls.Add($titleLabel, 0, 0)
[void]$menu.Controls.Add($closeButton, 1, 0)

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

$bColor = "#323232"
$fColor = "#bebebe"

$podcastsListBox = New-Object System.Windows.Forms.ListBox
$podcastsListBox.Dock = 'Fill' # Covering episode refresh button
$podcastsListBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$podcastsListBox.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
$podcastsListBox.Size = New-Object Drawing.Size @(315, ($form.Height - $menu.Size.Height - $episodeRefreshButton.Size.Height - 200))
$podcastsListBox.BackColor = $bColor
$podcastsListBox.ForeColor = $fColor
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
            $font = New-Object System.Drawing.Font("Arial", 10, [Drawing.FontStyle]::Italic)
            $bgColor = [System.Drawing.Color]::Indigo
            $fColor = [System.Drawing.Color]::Beige
            $bgBrush = [system.drawing.SolidBrush]::new($bgColor)
            try { 
                $e.Graphics.FillRectangle($bgBrush, $e.Bounds)
                [system.windows.forms.TextRenderer]::DrawText($e.Graphics, $txt, $font,
                    $e.Bounds, $fColor, $bgColor, 
                        ([System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter))
            }
            finally {
                $bgBrush.Dispose()
            }
        }
        else {
            $bgColor = [System.Drawing.Color]::DarkSlateBlue
            $fColor = "#cdcdcd"
            $bgBrush = [system.drawing.SolidBrush]::new($bgColor)
            $font = New-Object System.Drawing.Font("Arial", 10, [Drawing.FontStyle]::Regular)
            try { 
                $e.Graphics.FillRectangle($bgBrush, $e.Bounds)
                [system.windows.forms.TextRenderer]::DrawText($e.Graphics, $txt, $font,
                    $e.Bounds, $fColor, $bgColor, 
                        ([System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter))
            }
            finally {
                $bgBrush.Dispose()
            }
        }
    })
$script:episodesRefreshing = $false
$podcastsListBox.Add_SelectedIndexChanged({
        param($s, $e)
        if ( !$script:episodesRefreshing ) {
            $script:episodesRefreshing = $true
            $episodesListView.Clear() # Removes all headers & items.
            $podcast = $script:podcasts[$script:podcasts.title.IndexOf($s.Text)]
            $script:episodes = Update-Episodes -Podcast $podcast
            [void]$episodesListView.Columns.Add("Episode", 350)
            [void]$episodesListView.Columns.Add("Date", 150)
            Foreach ($episode in $script:episodes) {
                $item = New-Object system.Windows.Forms.ListViewItem
                $item.Text = $episode.title # Column 1
                $item.SubItems.Add( ($episode.pubDate.Values | Join-String) ) # column 2
                $episodesListView.Items.Add($item)
            }
            $script:episodesRefreshing = $false
        }
        else {
            Write-Host "Please wait while episodes are being gathered."
        }
    })
$episodeRefreshButton = New-Object System.Windows.Forms.Button
$episodeRefreshButton.Dock = 'top'
$episodeRefreshButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$episodeRefreshButton.Text = " Refresh Episodes List "
$episodeRefreshButton.FlatStyle = 'Flat'
$episodeRefreshButton.FlatAppearance.BorderSize = 1
$episodeRefreshButton.FlatAppearance.BorderColor = "#222222"
$episodeRefreshButton.BackColor = [System.Drawing.Color]::MidnightBlue
$episodeRefreshButton.ForeColor = $fColor
$episodeRefreshButton.AutoSize = $true
$episodeRefreshButton.Add_Click({
        param($s, $e)
        if ($null -ne $podcastsListBox.SelectedItem) {
            if ( !$script:episodesRefreshing ) {
                $script:episodesRefreshing = $true
                # TODO the logic here is duplicated in update-episodes method and may be simplified.
                $episodesListView.Clear() # Removes all headers & items.
                $podcast = $script:podcasts[$script:podcasts.title.IndexOf($podcastsListBox.SelectedItem)]
                write-host "Gathering all episodes for '$($podcast.title)', as of $(Get-Date) ..."
                $podcastEpisodesTitle = Approve-String -ToSanitize $podcast.title
                $podcastEpisodesFile = "$podcastEpisodesTitle.json"
                $(Format-Episodes -Episodes $(Get-Episodes -URI $podcast.url)) | ConvertTo-Json -depth 10 | Out-File -FilePath $podcastEpisodesFile
                $script:episodes = [array]$(Get-Content -Path $podcastEpisodesFile | ConvertFrom-Json -AsHashtable)
                [void]$episodesListView.Columns.Add("Episode", 350)
                [void]$episodesListView.Columns.Add("Date", 150)
                Foreach ($episode in $script:episodes) {
                    $item = New-Object system.Windows.Forms.ListViewItem
                    $item.Text = $episode.title # Column 1
                    $item.SubItems.Add( ($episode.pubDate.Values | Join-String) ) # column 2
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
            $m = "A podcast must first be selected in order to refresh its episodes."
            $t = “Select a Podcast”
            [System.Windows.Forms.MessageBox]::Show($m,$t,$b,$i)
        }
    })

$podcastsGroup = new-object System.Windows.Forms.GroupBox
$podcastsGroup.Dock = 'fill'
$podcastsGroup.Text = "Podcasts"
[void] $podcastsGroup.Controls.Add($podcastsListBox)
[void] $podcastsGroup.Controls.Add($episodeRefreshButton)


$episodesListView = New-Object System.Windows.Forms.ListView
$episodesListView.Dock = 'Fill'
$episodesListView.BorderStyle = 'None'
$episodesListView.BackColor = $bColor
$episodesListView.ForeColor = $fColor
$episodesListView.HeaderStyle = 'Nonclickable'
$episodesListView.View = 'Details'
$episodesListView.FullRowSelect = $true
$episodesListView.MultiSelect = $false
$episodesListView.Add_SelectedIndexChanged({
        param($s, $e)
        $script:episode = $script:episodes[$script:episodes.title.indexof($s.SelectedItems.text)]
        $episodeInfo.ResetText()
        $episodeInfo.Text = "Title: $($episode.title)`n" + `
            "Description: $($episode.description.'#text')`n" + `
            "Author: $($episode.author.'#text')`n" + `
            "Link: $($episode.enclosure.url)`n"
    })

$episodeInfo = New-Object System.Windows.Forms.RichTextBox
$episodeInfo.Dock = 'Fill'
$episodeInfo.Text = ""
$episodeInfo.Text = " `n" + `
    "   First, select a podcast (left) then select an episode from the generated list (above).`n" + `
    "   If podcasts aren't listed, run the setup.ps1 script followed by the create-update-feeds.ps1 script."
$episodeInfo.Multiline = $true
$episodeInfo.ReadOnly = $true
$episodeInfo.BorderStyle = 'None'
$episodeInfo.BackColor = $bColor
$episodeInfo.ForeColor = $fColor
# $episodeInfo.AutoSize = $true

$episodePlayButton = New-Object System.Windows.Forms.Button
$episodePlayButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$episodePlayButton.Text = " Stream in VLC "
$episodePlayButton.FlatStyle = 'Flat'
$episodePlayButton.FlatAppearance.BorderSize = 1
$episodePlayButton.FlatAppearance.BorderColor = "#222222"
$episodePlayButton.BackColor = $bColor
$episodePlayButton.ForeColor = $fColor
$episodePlayButton.AutoSize = $true
$episodePlayButton.Add_Click({
        if ($script:episode.Count -ne 0) {
            Write-Host "Requested to play '$($episodes_ListView.SelectedItems.Text)' ..."
            $url = $script:episode.enclosure.url
            if ( -1 -ne (get-process).ProcessName.indexof('vlc')) {
                Stop-Process -Name 'vlc'
            }
            # --qt-start-minimized `
            & "C:\Program Files\VideoLAN\VLC\vlc.exe" `
                --play-and-exit `
                --rate=1.5 `
                $url
        }
    })

$episodeDownloadPlayButton = New-Object System.Windows.Forms.Button
$episodeDownloadPlayButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$episodeDownloadPlayButton.Text = " Download and play in VLC "
$episodeDownloadPlayButton.FlatStyle = 'Flat'
$episodeDownloadPlayButton.FlatAppearance.BorderSize = 1
$episodeDownloadPlayButton.FlatAppearance.BorderColor = "#222222"
$episodeDownloadPlayButton.BackColor = $bColor
$episodeDownloadPlayButton.ForeColor = $fColor
$episodeDownloadPlayButton.AutoSize = $true
$episodeDownloadPlayButton.Add_Click({
        if ($script:episode.Count -ne 0) {
            Write-Host "Requested to download and play '$($episodes_ListView.SelectedItems.Text)' ..."
            $title = Approve-String -ToSanitize $script:episode.title
            $file = join-path (Get-location) "${title}.mp3"
            if ( !(Test-Path -PathType Leaf -Path $file) ) {
                $url = $script:episode.enclosure.url
                Find-Episode -URI $url -Path $file
            }
            if ( -1 -ne (get-process).ProcessName.indexof('vlc')) {
                Stop-Process -Name 'vlc'
            }
            # --qt-start-minimized `
            & "C:\Program Files\VideoLAN\VLC\vlc.exe" `
                --play-and-exit `
                --rate=1.5 `
                $file
        }
    })

$episodeDownloadButton = New-Object System.Windows.Forms.Button
$episodeDownloadButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$episodeDownloadButton.Text = " Download "
$episodeDownloadButton.FlatStyle = 'Flat'
$episodeDownloadButton.FlatAppearance.BorderSize = 1
$episodeDownloadButton.FlatAppearance.BorderColor = "#222222"
$episodeDownloadButton.BackColor = $bColor
$episodeDownloadButton.ForeColor = $fColor
$episodeDownloadButton.AutoSize = $true
$episodeDownloadButton.Add_Click({
        if ($script:episode.Count -ne 0) {
            Write-Host "Requested to download and play '$($episodes_ListView.SelectedItems.Text)' ..."
            $title = Approve-String -ToSanitize $script:episode.title
            $file = join-path (Get-location) "${title}.mp3"
            if ( !(Test-Path -PathType Leaf -Path $file) ) {
                $url = $script:episode.enclosure.url
                Find-Episode -URI $url -Path $file
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
$splitEpisodes.SplitterDistance = 65
$splitEpisodes.TabIndex = 2
$splitEpisodes.SplitterWidth = 3 
$splitEpisodes.Location = New-Object System.Drawing.Point(0, 0);
$splitEpisodes.Size = New-Object System.Drawing.Size(500, 500);

$splitEpisodes.Panel1.Controls.Add($episodesListView)
$splitEpisodes.Panel1.Name = "Episodes List View"
$episodesListView.TabIndex = 3

$splitEpisodes.Panel2.Controls.Add($episodeInfo)
$splitEpisodes.Panel2.Controls.Add($playButtonsPanel)

$splitEpisodes.Panel2.Name = "Episode Information"
$episodeInfo.TabIndex = 4

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

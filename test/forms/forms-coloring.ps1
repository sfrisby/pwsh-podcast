# https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.listview.ownerdraw?view=windowsdesktop-8.0&redirectedfrom=MSDN#System_Windows_Forms_ListView_OwnerDraw

# https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox?view=windowsdesktop-8.0
#  * https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.flatstyle?view=windowsdesktop-8.0#system-windows-forms-combobox-flatstyle
#  * https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.combobox.drawitem?view=windowsdesktop-8.0#system-windows-forms-combobox-drawitem

Add-Type -assembly System.Windows.Forms

$settings_file = 'conf.json'
$settings = $(get-content -Path $settings_file -Raw | ConvertFrom-Json)
$script:podcasts = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable);
$script:episodes = @()

$screen = [System.Windows.Forms.Screen]::AllScreens
$script:screenWidth = $screen[0].Bounds.Size.Width  
$script:screenHeight = $screen[0].Bounds.Size.Height
$screenHeight50p = [int]($script:screenHeight / 2)
$screenWidth50p = [int]($script:screenWidth / 2)

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

$bColor = "#454545"
$fColor = "#bebebe"

$podcastsListBox = New-Object System.Windows.Forms.ListBox
$podcastsListBox.Dock = 'Fill' # Cut off the top of the list ...
$podcastsListBox.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
$podcastsListBox.Size = New-Object Drawing.Size @(250, ($form.Height - $menu.Size.Height))
$podcastsListBox.BackColor = $bColor
$podcastsListBox.ForeColor = $fColor
# $podcastsListBox.View = 'Details'
# $podcastsListBox.MultiSelect = $false
# $podcastsListBox.OwnerDraw = $true
# $podcastsListBox.FlatStyle = 'flat'
# $podcastsListBox.DropDownStyle = 'Simple'
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
        $txt = ""
        if ($e.Index -ge 0) {
            $txt = $podcastsListBox.GetItemText($podcastsListBox.Items[$e.Index])
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
$podcastsListBox.Add_SelectedIndexChanged({
    param($s, $e)
    Write-Host "Selected: $($s.Text)"

})



$episodesListView = New-Object System.Windows.Forms.ListView
$episodesListView.Dock = 'Fill'
$episodesListView.BorderStyle = 'None'
$episodesListView.BackColor = $bColor
$episodesListView.ForeColor = $fColor
$episodesListView.MultiSelect = $false
$episodesListView.FullRowSelect = $true

$episodeInfo = New-Object System.Windows.Forms.TextBox
$episodeInfo.Dock = 'Fill'
$episodeInfo.Text = ""
$episodeInfo.PlaceholderText = " `n"+`
    "   First, select a podcast (left) then select an episode from the generated list (above).`n" + `
    "   If podcasts aren't listed, run the setup.ps1 script followed by the create-update-feeds.ps1 script."
$episodeInfo.Multiline = $true
$episodeInfo.ReadOnly = $true
$episodeInfo.BorderStyle = 'None'
$episodeInfo.BackColor = $bColor
$episodeInfo.ForeColor = $fColor
# $episodeInfo.AutoSize = $true

$episodePlayButton = New-Object System.Windows.Forms.Button
$episodePlayButton.Dock = 'Bottom'
$episodePlayButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$episodePlayButton.Text = " Play in VLC "
$episodePlayButton.FlatStyle = 'Flat'
$episodePlayButton.FlatAppearance.BorderSize = 1
$episodePlayButton.FlatAppearance.BorderColor = "#222222"
$episodePlayButton.BackColor = $bColor
$episodePlayButton.ForeColor = $fColor

$split = New-Object System.Windows.Forms.SplitContainer
$split.Location = New-Object System.Drawing.Point(0, 0);
$split.Dock = 'Fill'
$split.BackColor = "#222222" # Color of the vertical bar.
$split.TabIndex = 0
$split.SplitterWidth = 9

$split.Panel1.BackColor = "#323232" # Behind the podcast list.
$split.Panel1.Name = "Podcasts"

$split.Panel1.Controls.Add($podcastsListBox)
$podcastsListBox.TabIndex = 1

$splitEpisodes = New-Object System.Windows.Forms.SplitContainer
$splitEpisodes.Dock = 'Fill'
$splitEpisodes.Orientation = [System.Windows.Forms.Orientation]::Horizontal
$splitEpisodes.SplitterDistance = 85
$splitEpisodes.TabIndex = 2
$splitEpisodes.SplitterWidth = 3 
$splitEpisodes.Location = New-Object System.Drawing.Point(0, 0);
$splitEpisodes.Size = New-Object System.Drawing.Size(500, 500);

$splitEpisodes.Panel1.Controls.Add($episodesListView)
$splitEpisodes.Panel1.Name = "Episodes List View"
$episodesListView.TabIndex = 3

$splitEpisodes.Panel2.Controls.Add($episodeInfo)
$splitEpisodes.Panel2.Controls.Add($episodePlayButton)
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

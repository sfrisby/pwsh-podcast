# https://theitbros.com/powershell-gui-for-scripts
# https://info.sapien.com/index.php/guis/gui-controls/spotlight-on-the-listview-control

$settings_file = 'conf.json'
$settings = $(get-content -Path $settings_file -Raw | ConvertFrom-Json)

. .\utils.ps1

Add-Type -assembly System.Windows.Forms

$colors = @{
    background = "#222222"
    text = "#aeaeae"
}

$guiWidth = 800
$guiHeight = 600

$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = 'Podcasts'
$main_form.Width = $guiWidth
$main_form.Height = $guiHeight
$main_form.AutoSize = $true
# $main_form.BackColor = $colors.background
# $main_form.ForeColor = $colors.text

$podcasts_lable_x = 0
$podcasts_label_y = 10
$podcasts_Label = New-Object System.Windows.Forms.Label
$podcasts_Label.Text = "Podcast"
$podcasts_Label.Location = New-Object System.Drawing.Point($podcasts_lable_x, $podcasts_label_y)
$podcasts_Label.AutoSize = $true
$main_form.Controls.Add($podcasts_Label)

$script:jobName = "MyPodcastPlayer_v0.0.0.a"
$script:podcasts = [array]$(Get-Content -Path $settings.file.feeds -Raw | ConvertFrom-Json -AsHashtable);
$script:episodes = @()

$podcasts_combobox_x = $podcasts_Label.size.Width
$podcasts_combobox_width = ( $guiWidth - $podcasts_Label.Size.Width )
$podcasts_ComboBox = New-Object System.Windows.Forms.ComboBox
$podcasts_ComboBox.Width = $podcasts_combobox_width
$podcasts_ComboBox.DropDownStyle = 'DropDownList'
# $podcasts_ComboBox.BackColor = $colors.background
# $podcasts_ComboBox.ForeColor = $colors.text
$podcasts_ComboBox.Location = New-Object System.Drawing.Point($podcasts_combobox_x, $podcasts_label_y)
Foreach ($podcast in $script:podcasts) {
    [void] $podcasts_ComboBox.Items.Add($podcast.title)
}
$podcasts_ComboBox.Add_SelectedIndexChanged({
        # Write-Host "selected '$($this.selectedItem)'."
        $episodes_ListView.Enabled = $false
        $episodes_ListView.Clear() # Removing everything
        $podcast = $script:podcasts[$script:podcasts.title.IndexOf($this.SelectedItem)]
        $script:episodes = Update-Episodes -Podcast $podcast
        [void]$episodes_ListView.Columns.Add("Episode", $episodes_listview_75percentwidth)
        [void]$episodes_ListView.Columns.Add("Date", $episodes_listview_25percentwidth)
        # $episodes_ListView.DrawColumnHeader
        # $episodes_ListView.Columns.BackColor = $colors.background
        # $episodes_ListView.Columns.ForeColor = $colors.text
        Foreach ($episode in $script:episodes) {
            $item = New-Object system.Windows.Forms.ListViewItem
            $item.Text = $episode.title # Column 1
            # $item.BackColor = $colors.background
            # $item.ForeColor = $colors.text
            $item.SubItems.Add( ($episode.pubDate.Values | Join-String) ) # column 2
            $episodes_ListView.Items.Add($item)
        }
        $episodes_ListView.Enabled = $true
    }
)
$main_form.Controls.Add($podcasts_ComboBox)

$episodes_listbox_x = 0
$episodes_listbox_y = $podcasts_Label.Size.Height + 10
$episodes_listview_width = $guiWidth
$episodes_listview_height = [int]( $guiHeight - $podcasts_ComboBox.Size.Height - 100 )
$episodes_listview_25percentwidth = [int]($episodes_listview_width / 4)
$episodes_listview_75percentwidth = [int]($episodes_listview_width - $episodes_listview_25percentwidth)
$episodes_ListView = New-Object System.Windows.Forms.ListView
# $episodes_ListView.BackColor = $colors.background
# $episodes_ListView.ForeColor = $colors.text
$episodes_ListView.Width = $episodes_listview_width
$episodes_ListView.Height = $episodes_listview_height
$episodes_ListView.HeaderStyle = 'Nonclickable'
$episodes_ListView.Location = New-Object System.Drawing.Point($episodes_listbox_x, $episodes_listbox_y)
$episodes_ListView.HeaderStyle = 'Nonclickable'
$episodes_ListView.MultiSelect = $false
$episodes_ListView.FullRowSelect = $true
$episodes_ListView.Enabled = $false
$episodes_ListView.View = 'Details'
$episodes_ListView.Add_SelectedIndexChanged({
        if ( $null -eq $episodes_ListView.SelectedItems ) {
            $play_Button.Enabled = $false
        }
        else {
            $play_Button.Enabled = $true
        }
    }
)
$main_form.Controls.Add($episodes_ListView)


$play_button_x = 0
$play_button_y = $episodes_listview_height + $podcasts_ComboBox.Size.Height + 10
$play_Button = New-Object System.Windows.Forms.Button
$play_Button.AutoSize = $true
$play_Button.Location = New-Object System.Drawing.Point($play_button_x, $play_button_y)
$play_Button.Enabled = $false
$play_Button.Text = "Play in VLC"
$play_Button.Add_Click({
        if ( $null -eq $episodes_ListView.SelectedItems ) {
            $play_Button.Enabled = $false
        }
        else {
            # Kill any previous VLC instances, and play newly selected item.
            $play_Button.Enabled = $true
            
            $url = $script:episodes[$script:episodes.title.indexOf($episodes_ListView.SelectedItems.Text)].enclosure.url

            Write-Host "Requested to play '$($episodes_ListView.SelectedItems.Text)' ..."

            if ( -1 -ne (get-process).ProcessName.indexof('vlc')) {
                Stop-Process -Name 'vlc'
            }
            # --qt-start-minimized `
            # --play-and-exit `
            & "C:\Program Files\VideoLAN\VLC\vlc.exe" `
                --rate=1.5 `
                $url
        }
    }
)
$main_form.Controls.Add($play_Button)

[void]$main_form.ShowDialog()

Write-Host "Dialog has been shown."

$main_form.Dispose();

Write-Host "Dialog has been disposed."


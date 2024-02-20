Add-Type -assembly System.Windows.Forms

$screen = [System.Windows.Forms.Screen]::AllScreens
$script:screenWidth = $screen[0].Bounds.Size.Width  
$script:screenHeight = $screen[0].Bounds.Size.Height
$screenHeight50p = [int]($script:screenHeight / 2)
$screenWidth50p = [int]($script:screenWidth / 2)

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None' # Will prevent minimize and close from appearing; use alt+F4 to close.
# $form.FormBorderStyle = 'SizableToolWindow' # only displays close button - still white
# $form.FormBorderStyle = 'sizable' # shows all three expected buttons - still white
$form.Size = New-Object System.Drawing.Size($screenWidth50p, $screenHeight50p)
$form.BackColor = "#232323"
$form.ForeColor = "#aeaeae"

<#
    CUSTOM MENU

    Set the forms 'FormBorderStyle' to 'None' or it will be displayed. However, it will not have
    the expected controls unless specifically set which is what we do below.

    Using TableLayoutPanel has the best results with the column index and row index.
#>

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Podcasts"
$titleLabel.Font = New-Object Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = 'MiddleCenter'
$titleLabel.ForeColor = "#121212"
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

$menu = new-object System.Windows.Forms.TableLayoutPanel
$menu.BackColor = "#343434"
$menu.Size = New-Object System.Drawing.Size($script:screenWidth, $closeButton.Size.Height)
$menu.Location = New-Object System.Drawing.Point(0, $menu.Size.Height)
$menu.Dock = [System.Windows.Forms.DockStyle]::Top
# $TableLayoutPanel.Controls.Add($Control, $ColumnIndex, $RowIndex)
[void]$menu.Controls.Add($titleLabel, 0, 0)
[void]$menu.Controls.Add($closeButton, 1, 0)
$menu.Add_Click({
        Write-Host "clicked menu"
    })
$menu.Add_DoubleClick({
        Write-Host "double clicked menu"
    })
# Handle curstor changing
$menu.Add_MouseEnter({
        param($s, $e)
        $form.Cursor = [Windows.Forms.Cursors]::Hand
    })
$menu.Add_MouseLeave({
        param($s, $e)
        $form.Cursor = [Windows.Forms.Cursors]::Default
    })
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


$content = New-Object System.Windows.Forms.TableLayoutPanel
$content.BackColor = "#565656"
$content.Dock = 'Fill'
$content.Add_Click({
        Write-Host "clicked content"
    })
$content.Add_DoubleClick({
        Write-Host "double clicked content"
    })


$form.Controls.Add($menu)
$form.Controls.Add($content)

[void]$form.ShowDialog()
$form.Dispose()

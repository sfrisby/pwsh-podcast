Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = "Custom Menu"
$form.Size = New-Object Drawing.Size @(600, 200)
$form.StartPosition = "CenterScreen"

# Create a TableLayoutPanel
$tableLayoutPanel = New-Object Windows.Forms.TableLayoutPanel
$tableLayoutPanel.Dock = 'top'
$tableLayoutPanel.BackColor = '#898989'
$form.Controls.Add($tableLayoutPanel)

# Create a left-aligned label
$labelLeft = New-Object Windows.Forms.Label
$labelLeft.Text = "Left Label"
# $labelRight.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left
$labelRight.Anchor = [Windows.Forms.AnchorStyles]::Left
$labelLeft.AutoSize = $true


# Create a right-aligned label
$labelRight = New-Object Windows.Forms.Label
$labelRight.Text = "Right Label"
$labelRight.AutoSize = $true
$labelRight.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right
# $labelRight.Dock = 'Top'
# $labelRight = 'Right'


# $tableLayoutPanel.Controls.Add($labelRight, 1, 0)
$tableLayoutPanel.Controls.Add($labelLeft, 0, 0)


$button = New-Object Windows.Forms.Button
$button.Text = "Im a button"
$button.BackColor = "#ee99ee"
$button.FlatStyle = 'Flat'
$button.FlatAppearance.BorderSize = 0
$button.AutoSize = $true
$button.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right
# $button.Dock = 'bottom'
# $button.Anchor = 'left'

$group = New-Object System.Windows.Forms.TableLayoutPanel
$group.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right
$group.BackColor = "#eeee99"
$group.Controls.Add($button)
$group.Controls.Add($labelRight)

# $tableLayoutPanel.Controls.Add($button, 2, 0)
$tableLayoutPanel.Controls.Add($group, 1, 0)


$tableLayoutPanel2 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel2.BackColor = "#00ee00"
$tableLayoutPanel2.Dock = 'fill'
$form.Controls.Add($tableLayoutPanel2)

# Show the form
[void]$form.ShowDialog()
$form.Dispose()

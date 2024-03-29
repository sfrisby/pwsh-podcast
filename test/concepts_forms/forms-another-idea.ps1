# Add-Type -AssemblyName System.Windows.Forms

# # Create a form
# $form = New-Object Windows.Forms.Form
# $form.Text = "Custom Menu"
# $form.Size = New-Object Drawing.Size @(600, 200)
# $form.StartPosition = "CenterScreen"

# # Create a TableLayoutPanel
# $tableLayoutPanel = New-Object Windows.Forms.TableLayoutPanel
# $tableLayoutPanel.Dock = 'top'
# $tableLayoutPanel.BackColor = '#898989'
# $form.Controls.Add($tableLayoutPanel)

# # Create a left-aligned label
# $labelLeft = New-Object Windows.Forms.Label
# $labelLeft.Text = "Left Label"
# # $labelRight.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Left
# $labelRight.Anchor = [Windows.Forms.AnchorStyles]::Left
# $labelLeft.AutoSize = $true


# # Create a right-aligned label
# $labelRight = New-Object Windows.Forms.Label
# $labelRight.Text = "Right Label"
# $labelRight.AutoSize = $true
# $labelRight.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right
# # $labelRight.Dock = 'Top'
# # $labelRight = 'Right'


# # $tableLayoutPanel.Controls.Add($labelRight, 1, 0)
# $tableLayoutPanel.Controls.Add($labelLeft, 0, 0)


# $button = New-Object Windows.Forms.Button
# $button.Text = "Im a button"
# $button.BackColor = "#ee99ee"
# $button.FlatStyle = 'Flat'
# $button.FlatAppearance.BorderSize = 0
# $button.AutoSize = $true
# $button.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right
# # $button.Dock = 'bottom'
# # $button.Anchor = 'left'

# $group = New-Object System.Windows.Forms.TableLayoutPanel
# $group.Anchor = [Windows.Forms.AnchorStyles]::Top -bor [Windows.Forms.AnchorStyles]::Right
# $group.BackColor = "#eeee99"
# $group.Controls.Add($button)
# $group.Controls.Add($labelRight)

# # $tableLayoutPanel.Controls.Add($button, 2, 0)
# $tableLayoutPanel.Controls.Add($group, 1, 0)


# $tableLayoutPanel2 = New-Object System.Windows.Forms.TableLayoutPanel
# $tableLayoutPanel2.BackColor = "#00ee00"
# $tableLayoutPanel2.Dock = 'fill'
# $form.Controls.Add($tableLayoutPanel2)

# # Show the form
# [void]$form.ShowDialog()
# $form.Dispose()

# REQUIRED TO PREVENT ERRORING OUT! I'd rather just specify the namespace for clarity.
# using namespace System.Windows.Forms
# using namespace System.Drawing
# using namespace System

# https://stackoverflow.com/questions/75491531/powershell-and-winforms-trying-to-change-the-selection-color-of-a-combobox-set

Add-Type -assembly System.Windows.Forms

#Enable visual styles
[System.Windows.Forms.Application]::EnableVisualStyles()

#Enable DPI awareness
$code = @"
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
"@
$Win32Helpers = Add-Type -MemberDefinition $code -Name "Win32Helpers" -PassThru
$null = $Win32Helpers::SetProcessDPIAware()

$form = [System.Windows.Forms.Form] @{
    ClientSize = [Drawing.Point]::new(500, 200);
    StartPosition = "CenterScreen";
    Text = "Test";
    AutoScaleDimensions = [Drawing.SizeF]::new(6, 13);
    AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font;
}
$comboBox1 = [System.Windows.Forms.ComboBox] @{
    Location = [Drawing.Point]::new(8,8);
    Width = 300;
    DataSource = ("Lorem", "Ipsum", "Dolor", "Sit", "Amet");
    DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;
    DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed;
}
$comboBox1.Add_DrawItem({param([Object]$s, [System.Windows.Forms.DrawItemEventArgs]$e)
    $txt = ""
    if($e.Index -ge 0)
    {
        $txt = $comboBox1.GetItemText($comboBox1.Items[$e.Index])
    }
    $bgColor = [Color]::White
    if(($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected) 
    {
        $bgColor = [Color]::Tomato
    }
    $fColor = [Color]::Black
    if(($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected)
    {
        $fColor = [Color]::White
    }
    $bgBrush = [system.drawing.SolidBrush]::new($bgColor)
    try
    { 
        $e.Graphics.FillRectangle($bgBrush, $e.Bounds)
        [TextRenderer]::DrawText($e.Graphics,$txt, $e.Font,
            $e.Bounds, $fColor, $bgColor, 
            ([System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter))
    }
    finally
    {
        $bgBrush.Dispose()
    }
});
$form.Controls.Add($comboBox1)
[void] $form.ShowDialog()
$form.Dispose()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Size = New-Object Drawing.Size(300, 200)

$comboBox = New-Object Windows.Forms.ComboBox
$comboBox.Location = New-Object Drawing.Point(50, 50)
$comboBox.Size = New-Object Drawing.Size(200, 300)

# Populate ComboBox with items
$comboBox.Items.Add("Item 1")
$comboBox.Items.Add("Item 2")
$comboBox.Items.Add("Item 3")
$comboBox.DropDownStyle = 'Simple'
$comboBox.DrawMode = 'OwnerDrawVariable'

# Add DrawItem event handler
$comboBox_DrawItem = {
    param(
        [Object]$s,
        [Windows.Forms.DrawItemEventArgs]$e
    )

    # Custom font settings
    $font = New-Object Drawing.Font("Arial", 12, [Drawing.FontStyle]::Regular)

    # Draw the item text using custom font
    $point = New-Object Drawing.PointF($e.Bounds.X, $e.Bounds.Y)
    $e.Graphics.DrawString(
        $s.Items[$e.Index],
        $font,
        [Drawing.Brushes]::Black,
        $point
    )

    # Customize the focus rectangle
    $focusRectangleColor = [Drawing.Color]::Red
    $focusRectangleSize = 2

    # Check if the item is selected
    $isSelected = $s.SelectedIndex -eq $e.Index

    # Draw focus rectangle if item is selected
    if ($isSelected) {
        $e.DrawFocusRectangle()

        # Modify the focus rectangle appearance
        $focusRectangle = $e.Bounds
        $focusRectangle.Inflate(-$focusRectangleSize, -$focusRectangleSize)
        $e.Graphics.DrawString(
        $s.Items[$e.Index],
        $font,
        [Drawing.Brushes]::Red,
        $point
    )
    }
}

# Attach DrawItem event handler
$comboBox.Add_DrawItem($comboBox_DrawItem)

$form.Controls.Add($comboBox)

$form.ShowDialog()

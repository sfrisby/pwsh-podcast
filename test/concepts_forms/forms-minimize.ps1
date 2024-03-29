Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Minimize Form Example"
$form.Size = New-Object System.Drawing.Size(300, 200)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Minimize Form"
$button.Location = New-Object System.Drawing.Point(100, 50)
$button.Size = New-Object System.Drawing.Size(100, 30)

# Define button click event handler
$button.Add_Click({
    # Minimize the form when button is clicked
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
})

# Add the button to the form
$form.Controls.Add($button)

# Show the form
$form.ShowDialog() | Out-Null
Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = "Draggable Form Example"
$form.Size = New-Object Drawing.Size @(400, 200)
$form.StartPosition = "CenterScreen"

# Handle the MouseDown event to track initial click position
$script:mouseDown = $false
$script:lastLocation = New-Object Drawing.Point

$form.Add_MouseDown({
        param($s, $e)
        if ($e.Button -eq [Windows.Forms.MouseButtons]::Left) {
            $script:mouseDown = $true
            $script:lastLocation = $form.PointToScreen($e.Location)
        }
    })

# Handle the MouseMove event to update form position
$form.Add_MouseMove({
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

# Handle the MouseUp event to stop dragging
$form.Add_MouseUp({
        param($s, $e)
        $script:mouseDown = $false
    })

# Show the form
$form.ShowDialog()

[CmdletBinding()]
param (
    
)

begin {
    try {
        # Import the necessary .NET assemblies
        Add-Type -assembly System.Windows.Forms
    }
    catch {
        Write-Error "Exception occurred during the addition of System.Windows.Forms"
        throw $_
    }
    $color = @{
        'darkblue'    = [System.Drawing.Color]::FromArgb(13, 27, 92) # rgb(13, 27, 92);
        'lightpurple' = [System.Drawing.Color]::FromArgb(192, 157, 221) # rgb(192, 157, 221)
        'orange'      = [System.Drawing.Color]::FromArgb(201, 168, 24) # rgb(201, 168, 24)
    }
    function rgbtohex {
        param(
            [parameter(Mandatory, Position = 0)]
            [System.Drawing.Color]$C
        )
        return "#$($C.Name)"
    }
    function message_box {
        param(
            [parameter(Mandatory, Position = 0)]
            [string]$Message,
            [parameter(Position = 1)]
            [string]$Title = "Message",
            [System.Drawing.Size] $Size = [System.Drawing.Size]::new(150, 200)
        )
        $form = New-Object System.Windows.Forms.Form
        $form.Text = $Title
        $form.Size = $Size
        $form.StartPosition = "CenterScreen"
        $form.BackColor = rgbtohex $color.darkblue
        $form.ForeColor = rgbtohex $color.orange
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.ControlBox = $false
        $form.TopMost = $true
        # message label
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $Message
        $label.AutoSize = $true
        $label.Location = New-Object System.Drawing.Point(($Size.Width * 0.1), ($Size.Height * 0.5))
        $form.Controls.Add($label)
        # ok button
        $button = New-Object System.Windows.Forms.Button
        $button.Text = "OK"
        $button.Location = New-Object System.Drawing.Point(($Size.Width * 0.1), ($Size.Height * 0.75))
        $button.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Controls.Add($button)
        # show
        $form.ShowDialog()
    }
}

process {

    try {
        # Get the screen size ~ set to 75%
        $screen = $([System.Windows.Forms.Screen]::AllScreens) | Where-Object { $_.Primary -eq $true }

        # application window
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "PowerShell Podcasts"
        $form.Size = New-Object System.Drawing.Size(($screen.WorkingArea.Width * 0.75), ($screen.WorkingArea.Height * 0.75))
        $form.StartPosition = "CenterScreen"
        $form.BackColor = rgbtohex $color.darkblue
        $form.ForeColor = rgbtohex $color.lightpurple
        # todo provide line at bottom with version number

        # Create a button and add it to the form
        $button = New-Object System.Windows.Forms.Button
        $button.Text = "Click Me"
        $button.Location = New-Object System.Drawing.Point(100, 80)
        $button.Add_Click({
                message_box "Hello world!"
            })
        $form.Controls.Add($button)

        # Display the form
        $form.Add_Shown({ $form.Activate() })
        [void] $form.ShowDialog()
    }
    catch {
        Write-Host $_
    }
    finally {
        $form.Dispose()
    }
}

end {
    
}

<#

https://www.itprotoday.com/powershell/building-wpf-guis-in-powershell-beginner-s-guide

.NOTES

adding grid children outputs the number so use [void] in front to hide it

the window showdialog() was returning false upon close so just [void] it as well

#>

try {
    Add-Type -AssemblyName PresentationFramework
}
catch {
    Write-Error "Exception occurred during the addition of Windows Presentaion Framework."
    throw $_
}
try {
    Add-Type -AssemblyName System.Windows.Forms
}
catch {
    Write-Error "Exception occurred during the addition of Windows Forms."
    throw $_
}

$screen = $([System.Windows.Forms.Screen]::AllScreens) | Where-Object { $_.Primary -eq $true }

# Create the application window from xaml
$xaml = [xml](Get-Content "$PSScriptRoot\presentation.xaml")
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$stage = [Windows.Markup.XamlReader]::Load($reader)

$stage.Width = $screen.WorkingArea.Width * 0.25
$stage.Height = $screen.WorkingArea.Height * 0.75
$stage.WindowStartupLocation = 'CenterScreen'
# $stage.Title = 'PowerShell Podcast Manager'
$stage.WindowStyle = 'None' # requires creating my own menu bar; ALT+F4 to exit
$stage.AllowsTransparency = $true # removes window edge curves

$n = $stage.FindName("navbar")

$b = $stage.FindName("navbar_close")
$b.ToolTip = "Close"
$b.Add_Click({ $stage.Close() })




# $stage_background_brush = [System.Windows.Media.LinearGradientBrush]::new()
# $stage_background_brush.StartPoint = [system.windows.point]::new(0, 0) # start at top-left
# $stage_background_brush.EndPoint = [system.windows.point]::new(1, 1) # end at the bottom-right
# $gradient_stops = [System.Windows.Media.GradientStopCollection]::new()
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(10, 50, 150, 150), 0)) # rgb(50,150,150)
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(20, 250, 150, 150), 0.1)) # rgb(250,150,150)
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(40, 50, 250, 150), 0.3)) # rgb(50,250,150)
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(80, 10, 50, 150), 0.7)) # rgb(10,50,150)
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(100, 135, 55, 50), 1)) # rgb(135,55,50)
##0077ff
# $stage_background_brush.GradientStops = $gradient_stops
# # $stage.Background = $stage_background_brush
# $stage.Foreground = [System.Windows.Media.Brushes]::White


# # Create the grid
# $grid = [System.Windows.Controls.Grid]::new()

# $gridsize = [System.Drawing.Size]::new(3, 3) # row x col

# # 3 rows
# for ($r = 0; $r -lt $gridsize.Width; $r++) {
#     $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
# }

# # 3 columns
# for ($c = 0; $c -lt $gridsize.Width; $c++) {
#     $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
# }

# # text in each grid
# for ($r = 0; $r -lt $gridsize.Width; $r++) {
#     for ($c = 0; $c -lt $gridsize.Width; $c++) {
#         # Add a label to Row 0, Column 0
#         $Label = New-Object System.Windows.Controls.Label
#         $Label.Content = "This is location: $r (row) x $c (col)"
#         [System.Windows.Controls.Grid]::SetRow($Label, $r)
#         [System.Windows.Controls.Grid]::SetColumn($Label, $c)
#         [void] $grid.Children.Add($Label)
#     }
# }

# $bluegreenbrush = [System.Windows.Media.LinearGradientBrush]::new()
# $bluegreenbrush.StartPoint = [system.windows.point]::new(0, 0) # start at top-left
# $bluegreenbrush.EndPoint = [system.windows.point]::new(1, 1) # end at the bottom-right
# $gradient_stops = [System.Windows.Media.GradientStopCollection]::new()
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(75, 50, 150, 150), 0)) # rgb(50,150,150)
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(80, 35, 255, 150), 1)) # rgb(35,255,150)
# $bluegreenbrush.GradientStops = $gradient_stops

# $top_row_fill = [System.Windows.Shapes.Rectangle]::new()
# $top_row_fill.Fill = $bluegreenbrush

# [System.Windows.Controls.Grid]::SetRow($top_row_fill, 0)
# @(1 .. 3) | ForEach-Object { [System.Windows.Controls.Grid]::SetColumnSpan($top_row_fill, $_) } # set 1, 2, 3 grid cols ~ span affects index, seems offset by 1
# [void] $grid.Children.Add($top_row_fill)

# $greenorangebrush = [System.Windows.Media.LinearGradientBrush]::new()
# $greenorangebrush.StartPoint = [system.windows.point]::new(0, 0) # start at top-left
# $greenorangebrush.EndPoint = [system.windows.point]::new(1, 1) # end at the bottom-right
# $gradient_stops = [System.Windows.Media.GradientStopCollection]::new()
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(95, 12, 160, 18), 0)) # rgb(12, 160, 18)
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(5, 12, 160, 18), 0.5)) # rgb(212, 60, 18) ~ mid points are just between start and end
# $gradient_stops.Add([System.Windows.Media.GradientStop]::new([System.windows.media.Color]::FromArgb(95, 235, 155, 50), 1)) # rgb(235, 155, 50)
# $greenorangebrush.GradientStops = $gradient_stops
# $top_mid_fill = New-Object System.Windows.Shapes.Rectangle
# $top_mid_fill.Fill = $greenorangebrush
# [System.Windows.Controls.Grid]::SetRow($top_mid_fill, 0)
# [System.Windows.Controls.Grid]::SetColumn($top_mid_fill, 1)
# [void] $grid.Children.Add($top_mid_fill)

# # close button in top right grid
# # $navbar_close = New-Object Windows.Controls.Button
# # $navbar_close.Content = " X "
# # $navbar_close.HorizontalAlignment = "Right"
# # $navbar_close.VerticalAlignment = "Top"
# # $navbar_close.Add_Click({
# #         $stage.Close()
# #     })
# # [System.Windows.Controls.Grid]::SetRow($navbar_close, 0)
# # [System.Windows.Controls.Grid]::SetColumn($navbar_close, 2)
# # [void] $grid.Children.Add($navbar_close)
# # Attach the event handler to the button's MouseLeftButtonDown event

# $stage_grid = [System.Windows.Controls.Grid]::new()
# $stage_grid_navbar_row = [System.Windows.Controls.RowDefinition]::new()
# $stage_grid.RowDefinitions.Add($stage_grid_navbar_row)

# $navbar = [System.Windows.Controls.DockPanel]::new()
# $navbar.VerticalAlignment = 'Top'
# $navbar.HorizontalAlignment = 'Stretch'
# $navbar.Background = [System.Windows.Media.Brushes]::BlueViolet
# # $navbar.Cursor = [System.Windows.Input.Cursors]::Hand
# $navbar_title = [System.Windows.Controls.Label]::new()
# $navbar_title.Content = "PowerShell Podcast Manager"
# $navbar_title.HorizontalAlignment = "Left"
# $navbar_title.VerticalAlignment = "Center"
# $navbar_title.FontFamily = 'consolas'
# $navbar_title.FontSize = 10
# $navbar_title.Foreground = [System.Windows.Media.Brushes]::WhiteSmoke
# $navbar_title.BorderBrush = [System.Windows.Media.Brushes]::Black
# $navbar_close = New-Object Windows.Controls.Button
# $navbar_close.Content = " X "
# $navbar_close.FontFamily = 'consolas'
# $navbar_close.FontSize = 14
# $navbar_close.Padding = 7
# $navbar_close.Background = [System.Windows.Media.Brushes]::Crimson
# $navbar_close.Foreground = [System.Windows.Media.Brushes]::White
# $navbar_close.ToolTip = "Close"
# $navbar_close.HorizontalAlignment = "Right"
# $navbar_close.VerticalAlignment = "Center"
# $navbar_close.Add_Click({
#         $stage.Close()
#     })
# $stage_grid_navbar_row.Height = $navbar_close.Height
# [void] $navbar.Children.Add($navbar_title)
# [void] $navbar.Children.Add($navbar_close)
# [System.Windows.Controls.Grid]::SetRow($navbar, 0)
# [System.Windows.Controls.Grid]::SetColumn($navbar, 0)
# [void] $stage_grid.Children.Add($navbar)

# $stage_grid_content_row = [System.Windows.Controls.RowDefinition]::new()
# $stage_grid.RowDefinitions.Add($stage_grid_content_row)
# [System.Windows.Controls.Grid]::SetRow($grid, 1)
# [System.Windows.Controls.Grid]::SetColumn($grid, 0)
# [void] $stage_grid.Children.Add($grid)













# $stage.Content = $stage_grid
[void] $stage.ShowDialog()

# [System.Windows.Window]::new() | Get-Member -name "c*" -Force ~ .close() method 

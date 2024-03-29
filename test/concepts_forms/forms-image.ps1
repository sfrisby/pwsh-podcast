
# # https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.pictureboxsizemode?view=windowsdesktop-8.0

# # Failed to load svg, webp
# $imageUrl = "https://www.gstatic.com/webp/gallery/1.jpg"
# $imagePath = Join-Path $env:TEMP "image"
# if ( -not (Test-Path -Path $imagePath -PathType Leaf) ) {
#     Write-Host "Downloading $imageUrl to $imagePath"
#     Invoke-WebRequest -Uri $imageUrl -OutFile $imagePath
# }

# $form = New-Object System.Windows.Forms.Form

# $pictureBox.BorderStyle = 'FixedSingle'

# $pictureBox = New-Object System.Windows.Forms.PictureBox
# # $pictureBox.SizeMode = 'AutoSize' # The PictureBox is sized equal to the size of the image that it contains.
# # $pictureBox.SizeMode = 'CenterImage' # The image is displayed in the center if the PictureBox is larger than the image. If the image is larger than the PictureBox, the picture is placed in the center of the PictureBox and the outside edges are clipped.
# # $pictureBox.SizeMode = 'Normal' # The image is placed in the upper-left corner of the PictureBox. The image is clipped if it is larger than the PictureBox it is contained in.
# $pictureBox.SizeMode = 'StretchImage' # The image within the PictureBox is stretched or shrunk to fit the size of the PictureBox.
# # $pictureBox.SizeMode = 'Zoom' # The size of the image is increased or decreased maintaining the size ratio.
# $form.Controls.Add($pictureBox)

# $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)

# try {
#     $form.ShowDialog()
# } finally {
#     $form.Dispose()
#     $pictureBox.Dispose()
# }



# https://stackoverflow.com/questions/19193745/display-an-image-into-windows-forms

# Failed to load svg, webp
$imageUrl = "https://www.gstatic.com/webp/gallery/1.jpg"
# $imagePath = Join-Path $env:TEMP "image"
# if ( -not (Test-Path -Path $imagePath -PathType Leaf) ) {
#     Write-Host "Downloading $imageUrl to $imagePath"
#     Invoke-WebRequest -Uri $imageUrl -OutFile $imagePath
# }

$form = New-Object System.Windows.Forms.Form
$pictureBox = New-Object System.Windows.Forms.PictureBox
# $pictureBox.SizeMode = 'AutoSize' # The PictureBox is sized equal to the size of the image that it contains.
# $pictureBox.SizeMode = 'CenterImage' # The image is displayed in the center if the PictureBox is larger than the image. If the image is larger than the PictureBox, the picture is placed in the center of the PictureBox and the outside edges are clipped.
# $pictureBox.SizeMode = 'Normal' # The image is placed in the upper-left corner of the PictureBox. The image is clipped if it is larger than the PictureBox it is contained in.
$pictureBox.SizeMode = 'StretchImage' # The image within the PictureBox is stretched or shrunk to fit the size of the PictureBox.
# $pictureBox.SizeMode = 'Zoom' # The size of the image is increased or decreased maintaining the size ratio.
$form.Controls.Add($pictureBox)

$pictureBox.ImageLocation = $imageUrl

try {
    $form.ShowDialog()
} finally {
    $form.Dispose()
    $pictureBox.Dispose()
}
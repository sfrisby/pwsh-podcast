[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $null -ne $_ -and ![string]::IsNullOrEmpty($_.title) -and ![string]::IsNullOrEmpty($_.image) })]
    [pscustomobject]
    $Podcast,
    [Parameter()]
    [switch]
    $Download
)
begin {

    <#
        
        .SYNOPSIS
        
        Download URL to specified or generated temporary path.
        
        .DESCRIPTION
        
        When no path is provided the download file will go to a temporary file.

        The file path is returned.
        
    #>
    function Invoke-PodcastThumbnail {
        param (
            [Parameter(Mandatory)]
            [ValidateScript({ $null -ne $_.title -and $null -ne $_.image })]
            [pscustomobject] $Podcast,
            [Parameter()]
            [ValidateScript({ (Test-Path -Path $_ -PathType Leaf -IsValid) -and ($_.Name -notmatch [System.IO.Path]::GetInvalidFileNameChars()) })]
            [string] $File = (Join-Path $([System.IO.Path]::GetTempPath()) $(Split-Path -Path $Podcast.image -Leaf))
        ) 
        Invoke-WebRequest -Uri $Podcast.image -OutFile $File
        $File
    }

    function Format-Thumbnail {
        param(
            [Parameter(Mandatory)]
            [ValidateScript({ (Test-Path -Path $_ -PathType Leaf -IsValid) -and ($_.Name -notmatch [System.IO.Path]::GetInvalidFileNameChars()) })]
            [string] $Path,
            [Parameter()]
            [string]
            $Text = ($Path | Split-Path -LeafBase),
            [Parameter()]
            [ValidateRange(10, 3840)]
            [Int16] $Resolution = 250
        )
        try {
            $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(17, 17, 17))
            $foreground = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(157, 157, 157))
            $font = [System.Drawing.Font]::new("Consolas", 0.1 * $Resolution)
            $bitmap = [System.Drawing.Bitmap]::new($Resolution, $Resolution)
            $draw = [System.Drawing.Graphics]::FromImage($bitmap)
            $draw.FillRectangle($brush, 0, 0, $bitmap.Width, $bitmap.Height)
            $format = [System.Drawing.StringFormat]::new()
            $format.Alignment = [System.Drawing.StringAlignment]::Center
            $bounds = $draw.MeasureString($Text, $font)
            $widthoffset = $bitmap.Width * 0.5
            $heightoffset = ($bitmap.Height - $bounds.Height) * 0.5
            $draw.DrawString($Text, $font, $foreground, $widthoffset, $heightoffset, $format)
            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        }
        finally {
            if ($brush) { $brush.Dispose() }
            if ($font) { $font.Dispose() }
            if ($draw) { $draw.Dispose() }
        }
    }
}
process {
    $config = Get-Content -Path (join-path $PSScriptRoot '..' 'config.json') | ConvertFrom-Json
    $thumbnail = $Podcast.title + '.jpg'
    $destination = (Join-Path $config.podcasts $Podcast.title $thumbnail)
    if (!(Test-Path -Path $destination -PathType Leaf)) {
        if ($Download) {
            $tmp = Invoke-PodcastThumbnail -Podcast $Podcast
            Move-Item -Path $tmp -Destination $destination
        } else {
            Format-Thumbnail -Path $destination
        }
    }
}
end {
    return $destination
}
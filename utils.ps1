function Write-Host-Welcome() {
    param(
        # Parameter help description.
        [Parameter(Mandatory = $true)]
        [string] $Message,
        # Delimiter to encase around message.
        [ValidateScript( {$_.length -eq 1} )]
        [string] $delimiter = '~'
    )
    $ruler = $delimiter*[Console]::BufferWidth
    $split = ($ruler.Length - $Message.Length)/2
    $spacer = $delimiter*$split
    $title = $($spacer + $Message + $spacer)
    if ($title.length -gt [Console]::BufferWidth) {
        $title = $title[0..([Console]::BufferWidth - 1)] | join-string
    }
    Write-Host $ruler
    Write-Host $title
    Write-Host $ruler
}
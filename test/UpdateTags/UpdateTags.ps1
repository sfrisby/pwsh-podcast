[Reflection.Assembly]::LoadFrom((Resolve-Path "~\bin\TagLibSharp.dll"));

<#
    Update file tags

    $0: Episode information
    $1: File path
#>

$episode = $args[0]
$file = $args[1]

if ($null -eq $episode) {
    throw "Episode information not provided."
    if ([hashtable] -ne $episode.gettype()) {
        throw "Unexpected format for episode information provided."
    }
} elseif ($null -eq $file) {
    throw "File name not provided."
}

$pad = 3

$file = $(Get-ChildItem -Path "$file")
write-host "Inspecting $($file.BaseName) tags.".PadLeft($pad)

$tags = [TagLib.File]::Create( $file )
if ($null -eq $tags.Tag.Description -or $tags.Tag.Description -eq "") {
    $tags.Tag.Description = $episode.description
    Write-Host "Updated description.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Artists -or $tags.Tag.Artists.Count -eq 0) {
    foreach ($author in $episode.author.'#text') {
        $tags.Tag.Artists += $author
    }
    Write-Host "Updated artists.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Title -or $tags.Tag.Title -eq "") {
    $tags.Tag.Title = $episode.title
    Write-Host "Updated title.".PadLeft($pad)
}

# TODO create URL or Website tag instead of using Publisher
if ($null -eq $tags.Tag.Publisher -or $tags.Tag.Publisher -eq "") {
    
    # There should be a setfield property but it is not found as a member for the audio tags ...
    # https://github.com/mono/taglib-sharp
    #---
    # if ($null -eq $tags.Tag.URL) { $tags.Tag += @{'URL' = $episode.enclosure.url} }
    # InvalidOperation: Method invocation failed because [TagLib.NonContainer.Tag] does not contain a method named 'op_Addition'.
    #---
    # $tags.Tag.Tags += @ {'URL'=$episode.enclosure.url}
    # InvalidOperation: 'Tags' is a ReadOnly property.
    #---
    # $tags.Tag.Tags.'URL'=$episode.enclosure.url         
    # InvalidOperation: The property 'URL' cannot be found on this object. Verify that the property exists and can be set.

    $tags.Tag.Publisher = $episode.enclosure.url
    Write-Host "Updated publisher.".PadLeft($pad)
}


if ($null -eq $tags.Tag.Album -or $tags.Tag.Album -eq "") {
    $tags.Tag.Album = $episode.title
    Write-Host "Updated album.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Track -or $tags.Tag.Track -eq "") {
    $tags.Tag.Track = [int]([datetime]$episode.pubDate).ToString('yyMMdd')
    Write-Host "Updated track.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Year -or $tags.Tag.Year -eq "") {
    $tags.Tag.Year = ([datetime]($episode.pubDate)).Year
    Write-Host "Updated track.".PadLeft($pad)
}

$tags.Save()
write-host "Tag inspection complete.".PadLeft($pad)
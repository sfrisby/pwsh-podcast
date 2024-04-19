<#
.SYNOPSIS
Update tags to the provided information for the provided mp3.
.EXAMPLE
$info contains tag information which will be inserted into $mp3.
    .\test\UpdateTags\UpdateTags.ps1 $info $mp3
.EXAMPLE
$info contains tag information which will be inserted into $mp3 and prints what is updated.
    .\test\UpdateTags\UpdateTags.ps1 $info $mp3 -Information
#>

if ($HOME) {
    [void] [Reflection.Assembly]::LoadFrom((join-path $HOME "bin\TagLibSharp.dll"))
} else {
    [void] [Reflection.Assembly]::LoadFrom((join-path [Environment]::GetFolderPath("UserProfile") "bin\TagLibSharp.dll"))
}

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
Write-Information "Inspecting $($file.BaseName) tags.".PadLeft($pad)

$tags = [TagLib.File]::Create( $file )
if ($null -eq $tags.Tag.Description -or $tags.Tag.Description -eq "") {
    $tags.Tag.Description = $episode.description
    Write-Information "Updated description.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Artists -or $tags.Tag.Artists.Count -eq 0) {
    foreach ($author in $episode.author.'#text') {
        $tags.Tag.Artists += $author
    }
    Write-Information "Updated artists.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Title -or $tags.Tag.Title -eq "") {
    $tags.Tag.Title = $episode.title
    Write-Information "Updated title.".PadLeft($pad)
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
    Write-Information "Updated publisher.".PadLeft($pad)
}


if ($null -eq $tags.Tag.Album -or $tags.Tag.Album -eq "") {
    $tags.Tag.Album = $episode.title
    Write-Information "Updated album.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Track -or $tags.Tag.Track -eq "") {
    $tags.Tag.Track = [int]([datetime]$episode.pubDate).ToString('yyMMdd')
    Write-Information "Updated track.".PadLeft($pad)
}
if ($null -eq $tags.Tag.Year -or $tags.Tag.Year -eq "") {
    $tags.Tag.Year = ([datetime]($episode.pubDate)).Year
    Write-Information "Updated track.".PadLeft($pad)
}

try {
    $tags.Save()
} catch {
    Write-Host "Exception thrown while updating tags!"
    throw $_
}

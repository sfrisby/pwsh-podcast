<#

DEPRECATED

TODO far too complicated; use defaults and add any desired extras prior save for only podcast
TODO episodes should have their own file
TODO $config.podcasts <TITLE> provides the path ... but should enforce a special rule to ensure filesystem compatibility for title name

.SYNOPSIS

Convert podcast web response information to latest storage scheme.

.NOTES

By default the web request provides the following podcast keys:
    > title       ~ name of the podcast
    > url         ~ link to RSS 
    > description ~ description of the podcast
    > author      ~ podcast author; company or individual
    > image       ~ link to podcast image

The scheme used is outlined as follows (* indicate value comes from default keys (above)):
    {
        *title = {
            about = *description
            added = date in year month day format
            author = *author
            download = folder where downloads are stored locally (directoy path)
            episodes = { 
                episodes array
            }
            image = {
                local = where the podcast's thumbnail image is stored locally (file path)
                url = *image
            }
            pull = date when last episode search was performed in year month day hour(24) minute second millisecond format
            rss = *url
        }
    }

    given variable $v:
        > title is: 
            $v.keys[0]
        > all other info is: 
            $v[$v.keys[0]]

    ~~~

    TODO - got to ensure podcast title is good enough to be on the filesystem, no bad characters and what not and what about cases that it isnt?

    ~~~

    saving via config

    $m | ConvertTo-Json -Depth 6 | Out-String | Out-File -Path (join-path $config.podcasts $m.Keys[0] "$($m.keys[0]).json")

    better if just using downloads

    $m | ConvertTo-Json -Depth 6 | Out-String | Out-File -Path (join-path $m[$m.Keys[0]].downloads "$($m.keys[0]).json")

    ~~~

    The pull date isn't truly representative of new episodes; and probably only update upon success episode gathering?
    -> 
    Episodes indexing upon assignment is problematic ~ needs more robust analysis in process block, then pull may be corrected as well

    Reading back in is easy but indexing is different since it is no longer keyable and is pscustomobject
        > $t2 = Get-Content -Path .\test.json | ConvertFrom-Json -Depth 6
        > $t2.'Madigan''s Pubcast' | get-member -MemberType NoteProperty
    But this is easily resolved using '-ashashtable' switch.
        > $t2 = Get-Content -Path .\test.json | ConvertFrom-Json -Depth 6 -AsHashtable
        > $t2.keys
        > $t2[$t2.keys[0]]
        > $t2[$t2.keys[0]].keys


#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $null -ne $_.title -and $null -ne $_.url -and $null -ne $_.description -and $null -ne $_.author -and $null -ne $_.image })]
    [pscustomobject]
    $Data,
    [Parameter()]
    [pscustomobject]
    $Episodes = (. $PSScriptRoot\get_episodes.ps1 -Podcast $Data)[0].episodes,
    [Parameter()]
    [string]
    $Downloads = (. $PSScriptRoot\get_downloads.ps1 -Podcast $Data),
    [Parameter()]
    [string]
    $LocalImage = (. $PSScriptRoot\get_thumbnail.ps1 -Podcast $Data -Download),
    [Parameter()]
    [string]
    $Pull = $(if ($Episodes.count -gt 0) { (Get-Date -Format "yyMMddHHmmssfff") } else { "" })
)
begin { }
process { }
end {
    return @{
        $Data.title = @{
            'about'     = $Data.description
            'added'     = $(Get-Date -Format "yyMMdd")
            'author'    = $Data.author
            'downloads' = $Downloads
            'episodes'  = $Episodes
            'image'     = @{
                'local' = $LocalImage
                'url'   = $Data.image
            }
            'pull'      = $Pull
            'rss'       = $Data.url
        }
    }
}

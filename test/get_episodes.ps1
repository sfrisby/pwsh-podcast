<#
    
    .SYNOPSIS

    Obtain episodes for podcast via RSS / URI.

    .PARAMETER Podcast

    Podcast data array, containing the URI for its RSS feed.

    .EXAMPLE

    via result '#' from list view:

        > $podcasts = .\test\podcastsearch.ps1 -Title "the foreign report"
        > .\test\converttolistformat.ps1 -Hash $podcasts # (get the index, i.e. '#')
        > $episodes = .\test\getepisodes.ps1 -Podcast $($podcasts.data[#])

    or index directly via title:

        case sensitive:

            > [array]::IndexOf($nprpods.data.title, "TED Radio Hour")

        case insensitive:
            
            > [array]::indexof($nprpods.data, $($nprpods.data | Where-Object { $_.title -imatch "ted radio hour" }))

            in cases where two or more titles are the same:

                > [array]::indexof($nprpods.data, $($nprpods.data | Where-Object { $_.title -imatch "npr news" -and $_.author -imatch "npr" }))

    .EXAMPLE

    Saving the first index to JSON:
        > $episodes = .\getepisodes -Podcast $podcast.data[#]
        > $episodes[0] | ConvertTo-Json -Depth 6 | Out-String | Out-File -Path "path.json"

    .EXAMPLE

    Reading the data back into memory [pscustomobject]:
        > Get-Content -Path $path -Raw | ConvertFrom-Json

    Not using '-ashashtable' flag due to v7.3 forcing type to be 'orderedhashtable', (https://github.com/MicrosoftDocs/PowerShell-Docs/issues/9039)

    .OUTPUTS

    Array where the first index (0) is a ordered hashtable of podcast & episodes info while the second index (1) is the episode web request response.

    why not just have it be a pscustomobject? no need for -ashashtable really ... config file would have to incorporate it as well ... just doesn't seem necessary...
    
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $_.count -gt 0 -and ![string]::IsNullOrEmpty($_.url) })]
    [pscustomobject]
    $Podcast
)
begin {
    <#

        .SYNOPSIS
        
        Parse XML for relevant podcast episode information.

        .NOTES
        
        Overwrites any duplicate keys to the latest identified value. 
    
        Inspired from https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1

        Attributes found within the childnodes, instead of embedded childnodes:

        $tmp.rss.channel.item | ForEach-Object { $_.childnodes | foreach-object { write-host "$($_.localname): $($_.innertext) | $($_.childnodes.count) | $($_.attributes.count) " }}
                                                                                                                                    \
                                                                                                                                     `- the counts of childnodes in a childnode 
                                                                                                                                        have shown to be 0 while attributes may 
                                                                                                                                        be greater than 0.

        .OUTPUTS

        Array containing hashtable elements of podcast episode information or an empty array.

    #>
    function ConvertFrom-PodcastXML {
        param
        (
            [Parameter(Mandatory)]
            [ValidateScript({ $null -ne $_ -and $null -ne $_.rss.channel.item })]
            [XML] $XML
        )
        $episodes = @()
        $XML.rss.channel.item | ForEach-Object {
            $tmp = @{}
            $_.ChildNodes | ForEach-Object {
                # Check ChildNodes Existance; Overwrites duplicate keys!
                if ($_.ChildNodes.Count) {
                    if ($_.InnerText -match "’") {
                        $_.innertext = ($_.innertext -replace "`’", "`'")
                    }
                    $tmp[$_.LocalName] = [System.Web.HttpUtility]::HtmlDecode($_.InnerText)
                }
                # Checks Attributes Existance; Overwrites duplicate keys!
                if ($_.Attributes.Count) { 
                    $att = @{}
                    $_.Attributes | ForEach-Object {
                        if ($_.'#text' -match "’") {
                            $_.'#text' = ($_.'#text' -replace "`’", "`'")
                        }
                        $att[$_.LocalName] = [System.Web.HttpUtility]::HtmlDecode($_.'#text')
                    }
                    $tmp[$_.LocalName] = $att
                }
            }
            $episodes += @($tmp)
        }
        $episodes
    }
}
process {
    # TODO url was set to rss in setup
    $raw = Invoke-WebRequest -Uri $Podcast.url -Method Get -ContentType "application/json"
    $xml = $raw.Content
    if ($xml -imatch "\&rsquo\;") {
        $xml = ($raw.Content -replace "\&rsquo\;" , "`'")
    }
    $episodes = ConvertFrom-PodcastXML -XML $([xml] $xml)
}
end {
    return @(@{ podcast = $Podcast; episodes = $episodes }, @($raw))
}
<#

.SYNOPSIS

Obtain episodes for each podcast in parallel. Format XML to custom object element.

.OUTPUTS

All episodes for all podcasts in a single array.

Only interested in podcast title, episode title, episode date, episode url, episode or podcast author, and episode description.

Measured roughly 3 seconds for 14637 episodes from 24 podcasts.

.NOTES

Progress shown as a percentage of per Podcast episodes gathered.

XML cast will insert fat quotes into title '’', as well as '&#8211;'. Replacing upon assignment.

Using '-parallel' for each XML item negatively impacts performance.

.EXAMPLE

Showing the 10 most recent episodes and download the latest:

$podcasts = .\src\invoke_then_format_podcasts_episodes.ps1 $configuration[0]

$e = $podcasts | Select-Object -Property @{n = "date"; e = { [datetime] $_.date }}, title, podcast | Sort-Object -Property date -Descending | select -First 10

.\test\invoke_brave_download.ps1 ($podcasts | where-Object { $_.title -eq $e[0].title })

#>
[CmdletBinding()]
param (
    [parameter(Mandatory, Position = 0)]
    [ValidateScript({
            $_ | ForEach-Object {
                if ([string]::IsNullOrEmpty($_.title)) {
                    throw [System.Management.Automation.PropertyNotFoundException] "Podcast title missing."
                }
                if ([string]::IsNullOrEmpty($_.url)) {
                    throw [System.Management.Automation.PropertyNotFoundException] "Podcast url missing."
                }
            }
            $true
        })]
    [object[]] $Podcasts
)
$total = $Podcasts.Count
$index = @{i = 0 }
$progress = [System.Collections.Hashtable]::Synchronized($index)
$e = $Podcasts | ForEach-Object -Parallel {
    $p = $using:progress
    $podcast_title = $_.title
    $podcast_author = $_.author
    try {
        $tmp = $([xml]$(Invoke-WebRequest -Uri $_.url -Method Get -ContentType "application/json").Content)
        $tmp.rss.channel.item | ForEach-Object {
            $title = "Unknown episode title"
            if ($null -ne $_.title) {
                $titletype = $_.title.gettype()
                if ($titletype -eq [System.Xml.XmlElement]) {
                    $title = $_.title.innertext
                }
                elseif ($titletype -eq [string]) {
                    $title = $_.title
                }
                elseif ($titletype -eq [object[]]) {
                    $title = $_.title[0]
                }
            }
            $author = $podcast_author
            if ($null -ne $_.author) {
                $authortype = $_.author.gettype()
                if ($authortype -eq [System.Xml.XmlElement]) {
                    $author = $_.author.innertext
                }
                elseif ($authortype -eq [string]) {
                    $author = $_.author
                }
                elseif ($authortype -eq [object[]]) {
                    $author = $_.author[0]
                }
            }
            $description = [System.Web.HttpUtility]::HtmlDecode($_.encoded)
            if ($null -ne $_.description) {
                $descriptiontype = $_.description.gettype()
                if ($descriptiontype -eq [System.Xml.XmlElement]) {
                    $description = [System.Web.HttpUtility]::HtmlDecode($_.description.innertext)
                }
                elseif ($descriptiontype -eq [string]) {
                    $description = [System.Web.HttpUtility]::HtmlDecode($_.description)
                }
                elseif ($descriptiontype -eq [object[]]) {
                    $description = [System.Web.HttpUtility]::HtmlDecode($_.description[0])
                }
            }
            [PSCustomObject]@{
                author      = $author
                date        = $_.pubDate
                description = $description
                podcast     = $podcast_title
                title       = ($title -replace '&#8211;', "-" -replace "’", "'")
                url         = $_.enclosure.url
            }
        }
    }
    catch {
        [PSCustomObject]@{
            podcast = $podcast_title
            error   = $_
        }
    }
    $p.i++
    Write-Host "`rLoading all podcast episodes: $(100 * ($p.i / $using:total))%" -NoNewLine
}
Write-Host ""

$e

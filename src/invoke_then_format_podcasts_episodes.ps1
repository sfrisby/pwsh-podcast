<#

.SYNOPSIS

Obtain episodes for each podcast in parallel. Format xml items to hashtable element.

.OUTPUTS

New 'episodes' member is a [object[]]  where each element is a single episode [hashtable].

~ 5 seconds for 24 podcasts.

.NOTES

Inspired from https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1

[System.Web.HttpUtility]::HtmlDecode
- replaces &rsquo; with fat quote; '’'
- replaces &#8211; with fat hyphen; '–'
`- so replacing findings within string content directly, i.e. [-replace '&rsquo;', "'" -replace '&#8211;', "-"]

#>
[CmdletBinding()]
param (
    [parameter(Mandatory, Position = 0)]
    [ValidateScript({
            $_ | ForEach-Object {
                if ($null -ne $_.episodes) {
                    throw [System.Management.Automation.PropertyNotFoundException] "Episodes member for '$($_.title)' already exist."
                }
            }
            $true
        })]
    [object[]] $Podcasts
)
$total = $Podcasts.Count
$index = @{i = 0 }
$progress = [System.Collections.Hashtable]::Synchronized($index)
$Podcasts | ForEach-Object -Parallel {
    try {
        $progress_item = $using:progress
        $e = @()
        $tmp = [xml] $($(Invoke-WebRequest -Uri $_.url -Method Get -ContentType "application/json").Content -replace '&rsquo;', "'" -replace '&#8211;', "-")
        $tmp.rss.channel.item | ForEach-Object {
            $item = @{}
            $_.get_childnodes() | ForEach-Object {
                if ($_.get_attributes().count -gt 0) {
                    $a = @{}
                    $_.get_attributes() | ForEach-Object {
                        $a[$_.get_localname()] = $_.get_innertext()
                    }
                    $item[$_.get_localname()] = $a
                }
                else {
                    $item[$_.get_localname()] = $_.get_innertext()
                }
            }
            $e += @($item)
        }
    }
    catch {
        $e = $_
    }
    $_ | Add-Member -MemberType NoteProperty -Name "episodes" -Value $e
    $progress_item.i++
    Write-Host "`rLoading all podcast episodes: $(100 * ($progress_item.i / $using:total))%" -NoNewLine
}
Write-Host ""
$Podcasts

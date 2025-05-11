<#

.SYNOPSIS

Format xml items to hashtable element.

.NOTES

Inspired from https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1

TIME EATER! ~ 4.7 seconds for 24 podcats

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
                if ([string]::IsNullOrEmpty($_.episodes.Content)) {
                    throw [System.Management.Automation.PropertyNotFoundException] "Episodes for '$($_.title)' appear to already be formatted."
                }
            }
            $true
        })]
    [object[]] $Podcasts
)
$Podcasts | ForEach-Object -parallel { # keep -parallel
    $e = @()
    $tmp = $_.episodes.Content -replace '&rsquo;', "'" -replace '&#8211;', "-"
    $tmp = [xml] $tmp
    $tmp.rss.channel.item | ForEach-Object { # -parallel makes it much slower here
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
    # overwrites web response content
    $_.episodes = $e
}
$Podcasts
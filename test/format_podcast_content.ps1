<#

.SYNOPSIS

Parse web response content from podcast url feed.

.PARAMETER Content

The episodes content from the web request; type cast to [xml].

.DESCRIPTION

If a local name for the child node is found then a search for the inner text is performed. If there is no inner text then attributes are searched for. If no attributes or inner text are found then the local name child node is ignored.

Inner text is formatted to prevent appearance of unwanted characters.

Overwrites any duplicate local name members to the last provided. 

Inspired from https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1

.OUTPUTS

Array of hashtables for each podcast episode (if any).

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ ![string]::IsNullOrEmpty($_) })]
    [string] $Content
)
begin {
    function format {
        param( 
            [Parameter(Mandatory, Position = 0)] 
            [ValidateScript({ $null -ne $_ })]
            [string] $Text
        )
        $tmp = $Text -replace "`’", "`'"
        $tmp = [System.Web.HttpUtility]::HtmlDecode($tmp)
        return $tmp
    }
}
process {
    $episodes = @()
    ([xml] $Content).rss.channel.item | ForEach-Object {
        $item = @{}
        $_.get_childnodes() | ForEach-Object {
            if (![string]::IsNullOrEmpty($_.get_localname())) {
                if (![string]::IsNullOrEmpty($_.get_innertext())) {
                    $item[$_.get_localname()] = $(format $($_.get_innertext()))
                }
                elseif ($_.get_attributes().count -gt 0) {
                    $a = @{}
                    $_.get_attributes() | ForEach-Object {
                        $a[$_.get_localname()] = $(format $($_.get_innertext()))
                    }
                    $item[$_.get_localname()] = $a
                }
            }
        }
        $episodes += @($item)
    }
}
end {
    return $episodes
}
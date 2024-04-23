<#
.DESCRIPTION
Using content response data, convert it from XML to a hashtable.
.NOTES
Overwrites any duplicate keys to the latest identified value. 
Inspired from https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/ConvertFrom-XML/ConvertFrom-XML.ps1
#>
function ConvertFrom-PodcastWebRequestContent {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateScript({ $null -ne $_ })]
		[Microsoft.PowerShell.Commands.WebResponseObject] $Request
	)
	$episodes = @()
	$C = [XML] $Request.Content
	$C.rss.channel.item | ForEach-Object {
		$tmp = @{}
		$_.ChildNodes | ForEach-Object {
			# Check ChildNodes Existance; Overwrites duplicate keys!
			if ($_.ChildNodes.Count) {
				$tmp[$_.LocalName] = $_.InnerText
			}
			# Checks Attributes Existance; Overwrites duplicate keys!
			if ($_.Attributes.Count) { 
				$att = @{}
				$_.Attributes | ForEach-Object {
					$att[$_.LocalName] = $_.'#text'
				}
				$tmp[$_.LocalName] = $att
			}
		}
		$episodes += @($tmp)
	}
	$episodes
}
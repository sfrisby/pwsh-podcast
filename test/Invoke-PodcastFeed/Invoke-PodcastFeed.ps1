<#
.SYNOPSIS 
Perform a web request for the provided URI.

.NOTES
Attempted 'catch [System.Net.Http.HttpRequestException] {' but was unreliable.

Would be best to Convert System.Net.Http.HttpResponseMessage (via exception) to 
Microsoft.PowerShell.Commands.WebResponseObject (for XML) but unable to find a 
viable solution. If necessary, wrap method call within custom try-catch block.
#>
function Invoke-PodcastFeed {
    param(
        [Parameter(Mandatory = $true)]
        [string] $URI
    )
    $(Invoke-WebRequest -Uri $URI -Method Get -ContentType "application/json")
}
. .\ConvertFrom-XML.ps1

<#

Podcast feeds obtained via https://castos.com/tools/find-podcast-rss-feed/.

Also see @script{working-with-podcast-search-forms.ps1} which performs an identical search and displays the results.


https://stackoverflow.com/questions/26706941/convert-xml-to-specific-json-structure-with-powershell
https://stackoverflow.com/questions/11074341/how-do-i-get-a-list-of-child-nodes-from-xml
https://adamtheautomator.com/powershell-parse-xml/

https://learn.microsoft.com/en-us/powershell/scripting/samples/using-format-commands-to-change-output-view


https://feeds.simplecast.com/dCXMIpJz - LPOTL

https://www.red-gate.com/simple-talk/blogs/convert-from-xml/

Then, borrowing from the generousity of https://www.red-gate.com/simple-talk/blogs/convert-from-xml/ we can convert to it JSON.
#>

$feeds = @{
    pbsnewshour     = 'https://www.pbs.org/newshour/feeds/rss/podcasts/show'
    madiganspubcast = 'https://rss.art19.com/madigans-pubcast'
    lastpotl        = 'https://feeds.simplecast.com/dCXMIpJz'
    opentodebate    = 'https://omnycontent.com/d/playlist/e73c998e-6e60-432f-8610-ae210140c5b1/A91018A4-EA4F-4130-BF55-AE270180C327/44710ECC-10BB-48D1-93C7-AE270180C33E/podcast.rss'
    nprpolitics     = 'https://feeds.npr.org/510310/podcast.xml'
}

#$feed = Invoke-WebRequest -Uri $feeds.lastpotl
$feed = Invoke-WebRequest -Uri $feeds.nprpolitics
$xml = [XML] $feed.Content
if ($null -ne $xml.rss.channel.author && $null -ne $xml.rss.channel.item) {
    $podcast = $xml.rss.channel.author
    $table = @()
    try {
        # '#text' is a key for many items; also duplicates.
        $xml.rss.channel.item | ForEach-Object { # order preserved
            $table += $($_ | convertfrom-xml)
        }
    }
    catch {
        Write-Host $_.ScriptStackTrace
        throw "Failed to convert from XML."
    }
    try {
        $table | ConvertTo-Json -depth 10 | Out-File "$podcast-episodes_feed.json" -Force
    }
    catch {
        throw "Failed to create JSON episode list."
    }

}
else {
    Throw "Unexpected XML format."
}

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
#>

$feeds = @{
    pbsnewshour     = 'https://www.pbs.org/newshour/feeds/rss/podcasts/show'
    madiganspubcast = 'https://rss.art19.com/madigans-pubcast'
    lastpotl        = 'https://feeds.simplecast.com/dCXMIpJz'
    opentodebate    = 'https://omnycontent.com/d/playlist/e73c998e-6e60-432f-8610-ae210140c5b1/A91018A4-EA4F-4130-BF55-AE270180C327/44710ECC-10BB-48D1-93C7-AE270180C33E/podcast.rss'
}

$feed = Invoke-WebRequest -Uri $feeds.lastpotl

$foo = 1

$xml = [XML] $feed.Content
<#
$xml.rss.channel.item | get-member

   TypeName: System.Xml.XmlElement

Name                 MemberType            Definition
----                 ----------            ----------
ToString             CodeMethod            static string XmlNode(psobject instance)
AppendChild          Method                System.Xml.XmlNode AppendChild(System.Xml.XmlNode newChild)
Clone                Method                System.Xml.XmlNode Clone(), System.Object ICloneable.Clone()
CloneNode            Method                System.Xml.XmlNode CloneNode(bool deep)
CreateNavigator      Method                System.Xml.XPath.XPathNavigator CreateNavigator(), System.Xml.XPath.XPathNavigator IXPathNavigable.CreateNavigator()
Equals               Method                bool Equals(System.Object obj)
GetAttribute         Method                string GetAttribute(string name), string GetAttribute(string localName, string namespaceURI)
GetAttributeNode     Method                System.Xml.XmlAttribute GetAttributeNode(string name), System.Xml.XmlAttribute GetAttributeNode(string localName, string namespaceURI)
GetElementsByTagName Method                System.Xml.XmlNodeList GetElementsByTagName(string name), System.Xml.XmlNodeList GetElementsByTagName(string localName, string namespaceURI)       
GetEnumerator        Method                System.Collections.IEnumerator GetEnumerator(), System.Collections.IEnumerator IEnumerable.GetEnumerator()
GetHashCode          Method                int GetHashCode()
GetNamespaceOfPrefix Method                string GetNamespaceOfPrefix(string prefix)
GetPrefixOfNamespace Method                string GetPrefixOfNamespace(string namespaceURI)
GetType              Method                type GetType()
HasAttribute         Method                bool HasAttribute(string name), bool HasAttribute(string localName, string namespaceURI)
InsertAfter          Method                System.Xml.XmlNode InsertAfter(System.Xml.XmlNode newChild, System.Xml.XmlNode refChild)
InsertBefore         Method                System.Xml.XmlNode InsertBefore(System.Xml.XmlNode newChild, System.Xml.XmlNode refChild)
Normalize            Method                void Normalize()
PrependChild         Method                System.Xml.XmlNode PrependChild(System.Xml.XmlNode newChild)
RemoveAll            Method                void RemoveAll()
RemoveAllAttributes  Method                void RemoveAllAttributes()
RemoveAttribute      Method                void RemoveAttribute(string name), void RemoveAttribute(string localName, string namespaceURI)
RemoveAttributeAt    Method                System.Xml.XmlNode RemoveAttributeAt(int i)
RemoveAttributeNode  Method                System.Xml.XmlAttribute RemoveAttributeNode(System.Xml.XmlAttribute oldAttr), System.Xml.XmlAttribute RemoveAttributeNode(string localName, string…
RemoveChild          Method                System.Xml.XmlNode RemoveChild(System.Xml.XmlNode oldChild)
ReplaceChild         Method                System.Xml.XmlNode ReplaceChild(System.Xml.XmlNode newChild, System.Xml.XmlNode oldChild)
SelectNodes          Method                System.Xml.XmlNodeList SelectNodes(string xpath), System.Xml.XmlNodeList SelectNodes(string xpath, System.Xml.XmlNamespaceManager nsmgr)
SelectSingleNode     Method                System.Xml.XmlNode SelectSingleNode(string xpath), System.Xml.XmlNode SelectSingleNode(string xpath, System.Xml.XmlNamespaceManager nsmgr)
SetAttribute         Method                void SetAttribute(string name, string value), string SetAttribute(string localName, string namespaceURI, string value)
SetAttributeNode     Method                System.Xml.XmlAttribute SetAttributeNode(System.Xml.XmlAttribute newAttr), System.Xml.XmlAttribute SetAttributeNode(string localName, string names…
Supports             Method                bool Supports(string feature, string version)
WriteContentTo       Method                void WriteContentTo(System.Xml.XmlWriter w)
WriteTo              Method                void WriteTo(System.Xml.XmlWriter w)
Item                 ParameterizedProperty System.Xml.XmlElement Item(string name) {get;}, System.Xml.XmlElement Item(string localname, string ns) {get;}
description          Property              System.Xml.XmlElement description {get;}
duration             Property              string duration {get;set;}
enclosure            Property              System.Xml.XmlElement enclosure {get;}
encoded              Property              System.Xml.XmlElement encoded {get;}
episode              Property              string episode {get;set;}
episodeType          Property              string episodeType {get;set;}
guid                 Property              System.Xml.XmlElement guid {get;}
image                Property              System.Xml.XmlElement image {get;}
keywords             Property              string keywords {get;set;}
pubDate              Property              string pubDate {get;set;}
summary              Property              string summary {get;set;}
title                Property              System.Object[] title {get;}


$xml.rss.channel.item.enclosure
 `- LISTS ALL URLS TO GET TRACKS

$xml.rss.channel.item.gettype() 
IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object[]                                 System.Array


$xml.rss.channel.item.pubDate[1][0..15] | join-string

#>

<#
$xml.rss.channel.item[0].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     False    XmlElement                               System.Xml.XmlLinkedNode

We want the Content as JSON, but the feed content is in markup language format, so we can create an XML object by type casting.

Then, borrowing from the generousity of https://www.red-gate.com/simple-talk/blogs/convert-from-xml/ we can convert to it JSON.

Parsing an item at a time was found to have the best results.
$xml.rss.channel.item[0] | ConvertFrom-XML

#>

# here-strings method from https://www.delftstack.com/howto/powershell/powershell-json-array/

# $results = $($response.Content | ConvertFrom-json).data | ConvertTo-Json

if ($null -ne $xml.rss.channel.author && $null -ne $xml.rss.channel.item) {
    $podcast = $xml.rss.channel.author
    $table = @{
        'podcast'  = $podcast
        'episodes' = @{}
    }
    $table2 = @()
    $table3 = @()
    try {
        $term = "Item"
        $amount = $xml.rss.channel.item.Count
        $digits = $amount.ToString().Length
        for ($i = 0; $i -lt $amount; $i++) {
            $ht = [hashtable] $( $xml.rss.channel.item[$i] | convertfrom-xml )
            $ht2 = $( $xml.rss.channel.item[$i] | convertfrom-xml )
            $pad = $i.ToString().PadLeft($digits, '0')
            $k = "$term $pad"
            $table.episodes.$k = $ht # #Text appears to be an artifact from convertfrom-xml ... possible to remove?
            $table2 += @($ht2)
            $table3 += @($k, @($ht2))
        }
        # for ($i=0; i -lt ) $xml.rss.channel.item | ForEach-Object { # sort is not garuanteed.
        #     $ht = [hashtable] $( $_ | convertfrom-xml )
        #     $table.episodes.Add($ht.title[0].'#text', $ht) # #Text appears to be an artifact from convertfrom-xml ... possible to remove?
        # }
    }
    catch {
        throw "Failed to create hash table from XML."
    }

    $foo = 1

    try {
        $table | ConvertTo-Json -depth 10 | Out-File "$podcast-episodes_feed.json" -Force
    }
    catch {
        throw "Failed to create JSON episode list."
    }

}
else {
    Throw "Location of podcast episodes was not found."
}

$foo = 1

# $idx = 0
# $xml.rss.channel.item | ForEach-Object {
#     $t = ""
#     if ($_.title.'#cdata-section'.Length -gt 0) {
#         $t = $_.title.'#cdata-section' | Join-String # seen by pbs news hour; maybe others.
#     }
#     elseif ($_.title.Length -ge 1) {
#         $t = $_.title[0] | Join-String # others - unclear why there is duplicates.
#     }
#     else {
#         throw "Title could not be located for the desired episode feed."
#     }
#     $tmp = @{
#         $("e" + $idx) = @{
#             Title = $t
#             Date  = $_.pubDate | join-string
#             URL   = $_.enclosure.url
#         }
#     }
#     $table | Add-Member $tmp
#     $idx += 1 # stepping for a new key index.
# } 

# $table | ConvertTo-Json -depth 10 | Out-File "episode_feed.json"

# read back via $(ConvertFrom-Json (Get-Content -Path .\episode_feed.json -raw))

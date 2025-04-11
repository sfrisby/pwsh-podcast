<#

.SYNOPSIS

Default configuration template.

.EXAMPLE

$template = .\.config.default.ps1

.NOTES
JSON template outline
{
    "version" : "2.0.0",
    "vlc" : "",     << vlc executable file path     >>
    "tls" : "",     << tag lib sharp dll file path  >>
    "podcasts" : "" << podcast rss & info file path >>
}

#>
return @"
{
    "version" : "2.0.0",
    "vlc" : "",
    "tls" : "",
    "podcasts" : ""
}
"@
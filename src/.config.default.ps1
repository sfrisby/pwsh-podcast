<#

.SYNOPSIS

Default configuration template.

.EXAMPLE

$template = .<PATH>\.config.default.ps1

.NOTES

hashtable template outline:
    > "version" : "2.0.0",   <- version
    > "vlc" : "",            <- vlc executable path
    > "tls" : "",            <- tag lib sharp dll path
    > "local" : ""           <- podcast local storage path

#>
return @"
{
    "version" : "2.0.0",
    "vlc" : "",
    "tls" : "",
    "local" : ""
}
"@
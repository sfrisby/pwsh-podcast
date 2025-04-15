<#

    .SYNOPSIS

    List results of podcast search.

    .DESCRIPTION

    By default the foreground colors of each podcast alternate.

    Additional foreground coloring performed when provided with the 'HighlightTitleMatches' switch.

    .PARAMETER Podcasts

    Podcasts search information. 
    
    Expected to contain the following keys: 
        query
        response
        data

    .PARAMETER HighlightTitleMatches

    Switch parameter to highlight any podcast title matching the query; displayed with a 'yellow' foreground color.

    Matches are case insensitive.

    .EXAMPLE

    $podcasts =  '<PATH>\search_podcasts.ps1' -Title "npr"

    <PATH>\show_podcasts.ps1 -Podcasts $podcasts

    .EXAMPLE

    <PATH>\show_podcasts.ps1 -Podcasts $(<PATH>\search_podcasts.ps1 -Title "npr") -HighlightTitleMatches

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $_.keys -contains "query" -and $_.keys -contains "response" -and $_.keys -contains "data" })]
    [PSCustomObject]
    $Podcasts,
    [Parameter()]
    [switch]
    $HighlightTitleMatches
)
begin {}
process {
    $escape = [char]27
    $highlight = $($escape + "[93m")
    $dark = $($escape + "[2m")
    $reset = $($escape + "[0m")
    $Podcasts.data | Format-List -Property @{
        Label      = "Result";
        Expression = { 
            if ($_.title -imatch $Podcasts.query -and $HighlightTitleMatches) { $highlight + [array]::IndexOf($Podcasts.data, $_) + $reset }
            elseif ([array]::IndexOf($Podcasts.data, $_) % 2 -eq 0) { $dark + [array]::IndexOf($Podcasts.data, $_) + $reset }
            else { [array]::IndexOf($Podcasts.data, $_) } };
    }, @{
        Label      = "Podcasts for '$($Podcasts.query)'";
        Expression = { 
            if ($_.title -imatch $Podcasts.query -and $HighlightTitleMatches) { $highlight + $_.title + $reset }
            elseif ([array]::IndexOf($Podcasts.data, $_) % 2 -eq 0) { $dark + $_.title + $reset }
            else { $_.title } };
    }, @{
        Label      = "Description";
        Expression = { 
            if ($_.title -imatch $Podcasts.query -and $HighlightTitleMatches) { $highlight + $_.description + $reset } 
            elseif ([array]::IndexOf($Podcasts.data, $_) % 2 -eq 0) { $dark + $_.description + $reset } 
            else { $_.description } };
    }, @{
        Label      = "RSS";
        Expression = { 
            if ($_.title -imatch $Podcasts.query -and $HighlightTitleMatches) { $highlight + $_.url + $reset } 
            elseif ([array]::IndexOf($Podcasts.data, $_) % 2 -eq 0) { $dark + $_.url + $reset } 
            else { $_.url } };
    }
}
end {}
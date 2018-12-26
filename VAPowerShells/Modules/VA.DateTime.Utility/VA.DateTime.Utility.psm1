
function Get-TimeZone
{
    [CmdletBinding()]
    param
    (
    [parameter(Mandatory=$true)]
    [string]$name = "UTC"
    )
 
    switch($name)
    {
        "IST" { $name = "India Standard Time" }
        "EST" { $name = "Eastern Standard Time" }        
    }

    [TimeZoneInfo]::FindSystemTimeZoneById($name)
}
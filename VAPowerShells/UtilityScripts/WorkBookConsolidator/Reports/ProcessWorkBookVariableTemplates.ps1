
$_accountNameMappingTable = @{}

function __Init__([string]$thisPath)
{
    $rootFolder = $(split-path -parent $thisPath) + "\"
    $accountMappingFile = $rootFolder + "CustomMappings.json"
    $accountMappingJson = Get-Content $accountMappingFile -Raw | ConvertFrom-Json 
    $accountMappingJson.psobject.properties | Foreach { $_accountNameMappingTable[$_.Name] = $_.Value }
}

function GetSegment()
{
    param(
        [string]$sourceFileName,
        [object]$templateMapping
    )

    $pathArray = $($sourceFileName -split "\\")

    $segment = "N/A"
    if($pathArray.Length -ge 2)
    {
        $segment = $pathArray[-2]
    }

    return $segment
}


function GetAccount()
{
    param(
        [string]$sourceFileName,
        [object]$templateMapping
    )

    $pathArray = $($sourceFileName -split "\\")

    $account = "N/A"
    if($pathArray.Length -ge 1)
    {
        $account = $pathArray[-1]

        $account = $account.Split(" ")[0]
    }

    return $_accountNameMappingTable[$account]
}
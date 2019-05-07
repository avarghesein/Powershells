
function GetFileName()
{
    param(
        [string]$sourceFileName,
        [object]$templateMapping
    )

    $account = $($sourceFileName -split "\\")[-1]

    return $account
}
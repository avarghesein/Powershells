
Set-Variable -scope Script fileSlash $("\")
Set-Variable -scope Script empty $([string]::Empty)
Set-Variable -scope Script newLineChar $([char]10) #\n

function IsNullOrEmpty
{
    param
    (
        [string]$value
    )

    $value -eq $null -or $value -eq $empty
}

function GetScriptPath
{
    #$((Split-Path $PSScriptRoot -Parent) + $pathSeperator)
    #$((Split-Path -Parent $MyInvocation.MyCommand.Definition) + $pathSeperator)
}

Export-ModuleMember -Function IsNullOrEmpty, GetScriptPath -Variable fileSlash, empty, newLineChar
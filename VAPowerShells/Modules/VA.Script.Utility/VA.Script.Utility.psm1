
Set-Variable -scope Script fileSlash $("\")
Set-Variable -scope Script empty $([string]::Empty)
Set-Variable -scope Script newLineChar $([char]10) #\n

Set-Alias ?: IIF -Scope Global -Description "IIF or ?: or Ternary Operator"

filter IIF($trueBlock, $elseBlock)
{
    $condition = if($_ -is [scriptblock]) { & $_} else { $_ }

    if($condition)
    {
        if($trueBlock -is [scriptblock]) { & $trueBlock } else { $trueBlock }
    }
    else
    {
        if($elseBlock -ne $null)
        {
            if($elseBlock -is [scriptblock]) { & $elseBlock } else { $elseBlock }
        }
    }
}

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

Export-ModuleMember -Function IsNullOrEmpty, GetScriptPath, IIF -Variable fileSlash, empty, newLineChar -Alias ?:

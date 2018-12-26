function Split-TextFile
{
    [CmdletBinding()]
    param
    (
    [parameter(Mandatory=$true)]
    [string]$sourceFile,
    [parameter(Mandatory=$false)]
    [string]$targetFolder,
    [parameter(Mandatory=$false)]
    [string]$targetFileNameFormat,
    [parameter(Mandatory=$true)]
    [int]$splitLimit=10MB,
    [switch]$adjustLinefeedBoundary = $false
    )
 
    Import-Module -Name "VA.Script.Utility" -Force
    Import-Module -Name "VA.DateTime.Utility" -Force

    $in = New-Object IO.StreamReader $sourceFile

    $charSplitLimit = $splitLimit
    $buff = New-Object char[] $charSplitLimit

    $sourceFileName = Split-Path -Path $sourceFile -Leaf
    $sourceFolder = Split-Path -Path $sourceFile

    [void](IsNullOrEmpty($targetFolder) -and ($targetFolder = $sourceFolder))
    [void](IsNullOrEmpty($targetFileNameFormat) -and ($targetFileNameFormat = $sourceFileName))

    try
    {
        $charCount = 0
        $idx = 0

        while(($charCount = $in.Read($buff, 0, $buff.Length)) -gt 0)
        {
            $targetFile = "{0}\{1}_{2}" -f ($targetFolder, ++$idx, $targetFileNameFormat)
            $out = New-Object IO.StreamWriter $targetFile
            try
            {
                $out.Write($buff, 0 , $charCount)
                
                if($adjustLinefeedBoundary)
                {
                    [char]$currentChar = $buff[$charCount - 1]
                    #write till we find the immediate next newline
                    while($currentChar -ne $newLineChar -and ! $in.EndOfStream)
                    {
                        $currentChar = [char]$in.Read()
                        $out.Write($currentChar)
                    }

                    if($in.EndOfStream)
                    {
                        break;
                    }
                }
            }
            finally
            {
                $out.Close()
                $out.Dispose()
                $out = $null
            }
        }
    }
    finally
    {
        $in.Close()
        $in.Dispose()
        $in = $null
    }
}
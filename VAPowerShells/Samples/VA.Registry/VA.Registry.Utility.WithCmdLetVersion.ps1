function Search-Registry
{
    [CmdletBinding()]
    param
    (
    [parameter(Mandatory=$true)]
    [string]$keyNameExpression,
    [parameter(Mandatory=$false)]
    [string]$keyValueExpression,
    [parameter(Mandatory=$false)]
    [string[]]$registryPathsToSearch = @("HKU:\", "HKCU:\")
    )
 
    [void](Import-Module -Name "VA.Script.Utility" -Force)
    [void](Import-Module -Name "VA.DateTime.Utility" -Force)

    if(! (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue))
	{
		[void](New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS)
	}

 	GCI  -LiteralPath $registryPathsToSearch -Recurse -EA SilentlyContinue | %{

		$curKey = $_;
        $searchedKeyValues = $null

        Try
        {
            $searchedKeyValues = $((Get-Item -LiteralPath $curKey.PsPath -ErrorAction Stop).PsObject.Properties | ? { $_.Name -imatch $keyNameExpression -and $_.Value -imatch $keyValueExpression })
        }
        Catch
        {
            Write-Host $_.Exception.Message
        }

		if($searchedKeyValues -and $searchedKeyValues.Count -gt 0)
		{
            $searchedKeyValues | %{

                [PsCustomObject]@{
                    "Name" = $_.Name
                    "Value" = $_.Value
                    "Path" = $curKey.PsPath
                }
            }
		}
	}
}
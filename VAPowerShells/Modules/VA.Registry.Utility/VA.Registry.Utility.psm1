function Search-Registry
{
    [CmdletBinding()]
    param
    (
    [parameter(Mandatory=$true)]
    [string]$tokenToSearch,
    [parameter(Mandatory=$true)]
    [ValidateSet('KeyName','ValueName','Value')]
    [string]$tokenType,
    [parameter(Mandatory=$false)]
    [switch]$searchExact,
    [parameter(Mandatory=$false)]
    [string[]]$pathsToSearch = @("HKLM")
    )
 
    [void](Import-Module -Name "VA.Script.Utility" -Force)
    [void](Import-Module -Name "VA.DateTime.Utility" -Force)

    $kMode = "/K"
    switch($tokenType)
    {
        "KeyName" { $kMode = "/K" }
        "ValueName" { $kMode = "/V" }        
        "Value" { $kMode = "/D" } 
    }

    $pathsToSearch | % {
        $regQueryResults = IEX "& REG QUERY $_ $kMode /F $tokenToSearch /S $(if($searchExact) {" /E" })"

        if($?)
        {
            [void]($regQueryResults.Foreach("Replace","(`r?`n)*",$empty).ForEach("Trim"))

            for($idx = 0; $idx -lt $regQueryResults.Length; ++$idx)
            {
                $regPathLine = $regQueryResults[$idx]

                if($regPathLine -eq $empty -or $regPathLine.StartsWith("End Of Search", $true, $null))
                {
                    continue
                }

                $valueFound = $false

                do
                {
                    $regKeyLine = $regQueryResults[++$idx]

                    $regNameValueMatch = [Regex]::Match($regKeyLine, "(?<NAME>.*)\s+REG_[^\s]*\s*(?<VALUE>.*)")

                    if(!$regNameValueMatch.Success)
                    {
                        --$idx
                        break
                    }

                    $valueFound = $true

                    $regNameValue = $regNameValueMatch.Groups

                    [PsCustomObject] @{
                        "KeyPath" = $regPathLine
                        "ValueName" = $regNameValue["NAME"]
                        "Value" = $regNameValue["VALUE"]
                    }
                }
                while($idx -lt $regQueryResults.Length)

                if(!$valueFound)
                {
                    [PsCustomObject] @{
                            "KeyPath" = $regPathLine
                            "ValueName" = $Empty
                            "Value" = $Empty
                        }
                }
            }
        }
    }
}
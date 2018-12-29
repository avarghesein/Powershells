clear

Import-Module -Name "VA.Registry.Utility" -Force

$values = Search-Registry -tokenToSearch "NGen" -tokenType KeyName -pathsToSearch @("HKLM\SOFTWARE\Microsoft")

$values = Search-Registry -tokenToSearch "Dbg" -tokenType ValueName -pathsToSearch @("HKLM\SOFTWARE\Microsoft")

Search-Registry -tokenToSearch "MsiExecCA32" -tokenType ValueName -searchExact -pathsToSearch @("HKLM")

Search-Registry -tokenToSearch "CascadedMenu" -tokenType ValueName -searchExact -pathsToSearch @("HKCU", "HKU")

Search-Registry -tokenToSearch "ShellCompatibility" -tokenType KeyName -searchExact -pathsToSearch @("HKLM")

Search-Registry -tokenToSearch "aero.theme" -tokenType Value -pathsToSearch @("HKLM")


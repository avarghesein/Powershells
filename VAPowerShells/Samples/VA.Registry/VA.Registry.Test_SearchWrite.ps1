clear

Import-Module -Name "VA.Registry.Utility" -Force

Search-Registry -tokenToSearch "MsiExecCA32" -tokenType ValueName -searchExact -pathsToSearch @("HKLM")

Search-Registry -tokenToSearch "CascadedMenu" -tokenType ValueName -searchExact -pathsToSearch @("HKCU", "HKU")

Search-Registry -tokenToSearch "ShellCompatibility" -tokenType KeyName -searchExact -pathsToSearch @("HKLM")

Search-Registry -tokenToSearch "aero.theme" -tokenType Value -pathsToSearch @("HKLM")


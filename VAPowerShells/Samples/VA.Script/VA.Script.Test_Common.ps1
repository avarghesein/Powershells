 Clear

 Import-Module -Name "VA.Script.Utility" -Force

 #Usage {condition} |?: {trueblock} {falseblock} or {condition} |?: {trueblock}
 { $true } |?: { "True" } { "False" }

 #You could provide condition directly without script block
 1 -eq 2  |?: { "1 Equals 2" } { "1 Not Equals 2" }

 #You could omit False Part of the ternary
 { 1 -eq 2 } |?: { "1 Equals 2" }

 #Use Ternary in Pipe line
 (@( {$true}, $true, { $false }, $true) | ?: { "YES" } ).Length
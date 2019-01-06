 Clear

 Import-Module -Name "VA.Script.Utility" -Force

 #Usage {condition} |?: {trueblock} {falseblock} or {condition} |?: {trueblock}
 { $true } |?: { "True" } { "False" }

  { 1 -eq 2 } |?: { "1 Equals 2" } { "1 Not Equals 2" }

 #You could omit False Part of the ternary
 { 1 -eq 2 } |?: { "1 Equals 2" }
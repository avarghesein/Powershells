 Clear
 #
 Import-Module -Name "VA.Script.Utility" -Force
 #
 #Usage condition |?: truepart falsePart or condition |?: truePartOnly
 $true |?: "Print True" "Print False"
 #
 #
 #Usage {condition} |?: {trueBlock} {falseBlock} or {condition} |?: {trueBlockOnly}
 { $true } |?: { "Print True" } { "Print False" }
 #
 #
 #You could provide condition directly without script block
 1 -eq 2  |?: { "1 Equals 2" } { "1 Not Equals 2" }
 #
 #
 #You could omit False Part of the ternary
 { 1 -eq 2 } |?: { "1 Equals 2" }
 #
 #
 #Use Ternary in Pipe line. Below will Print 3
 (@( {$true}, $true, { $false }, $true) | ?: "YES" ).Length
 #
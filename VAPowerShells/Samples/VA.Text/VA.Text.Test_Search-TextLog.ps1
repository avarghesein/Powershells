
$stopWatch = New-Object System.Diagnostics.Stopwatch
$stopWatch.Start()
clear

Import-Module -Name "VA.Script.Utility" -Force

$filterParams = @{
    serverLogFolders = @("C:\Windows\Logs\CBS")
    localFolder = "E:\TMP\LOGS"

    logFilterPattern = ".*"

    logFilterStartDateTime = "04-Dec-2018 00:00:00"
    logFilterEndDateTime = "07-Dec-2018 23:59:59"
    logFilterDateTimeFormat = "dd-MMM-yyyy HH:mm:ss"
    logFilterDateTimeZone = "IST"

    logPrintDateTimeZone = "IST"
    
    logTypeControlFile = "$PSScriptRoot$($fileSlash)$($scriptRoot)LogTypeControlFile.json"
    logTypeControlKey = "CBS_LOG"   
}

    
Import-Module -Name "VA.Text.Utility" -Force -Verbose

$logFolder = Search-TextLog @filterParams

II $logFolder

Write-Host $("Completed in {0} Seconds" -f $($stopWatch.ElapsedMilliseconds / 1000))
$stopWatch.Stop()
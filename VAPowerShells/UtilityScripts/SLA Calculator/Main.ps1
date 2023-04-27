param(
    [string]$configFile = "Config\Config.json"
)
function IsAbsolutePath([string] $path) {
    return [System.IO.Path]::IsPathRooted($path);
}

Write-Progress -Activity "SLA Breach Calculation" -Status "Starting" -PercentComplete 0 -CurrentOperation "Complete 0%"

$stopWatch = New-Object System.Diagnostics.Stopwatch
$stopWatch.Start()

Clear-Host

if (!(IsAbsolutePath $configFile)) {
    $rootFolder = $(split-path -parent $MyInvocation.MyCommand.Definition) + "\"
    $configFile = $rootFolder + $configFile
}
$rootFolder = $(split-path -parent $configFile) + "\"

$configObject = Get-Content $configFile -Raw | ConvertFrom-Json 

if (!(IsAbsolutePath $configObject.CalculatorScriptPath)) { $configObject.CalculatorScriptPath = $rootFolder + $configObject.CalculatorScriptPath }
if (!(IsAbsolutePath $configObject.SLAConfigPath)) { $configObject.SLAConfigPath = $rootFolder + $configObject.SLAConfigPath }
if (!(IsAbsolutePath $configObject.HolidayConfigPath)) { $configObject.HolidayConfigPath = $rootFolder + $configObject.HolidayConfigPath }
if (!(IsAbsolutePath $configObject.SourceFile)) { $configObject.SourceFile = $rootFolder + $configObject.SourceFile }
if (!(IsAbsolutePath $configObject.TargetFile)) { $configObject.TargetFile = $rootFolder + $configObject.TargetFile }

. "$($configObject.CalculatorScriptPath)"

__Init__ -thisPath $configObject.CalculatorScriptPath -config $configObject


#Test your SLA here
$curDate = "2019-02-27 11:39:18" #start time
$startDate = [DateTime]::ParseExact($curDate, "yyyy-MM-dd HH:mm:ss", $null) 
$pauseDurSecs = 49 #20 Mins
$slaType = "Incident - P4 Resolution"
$breachDate = GetSLABreachDate $startDate $slaType $pauseDurSecs
Write-Host("StartDate: $curDate, Breach Date:$breachDate")
#exit
#Test End

CP $configObject.SourceFile  $configObject.TargetFile

$excelApp = New-Object -ComObject "Excel.Application"
$excelApp.Visible = $true
$excelApp.AskToUpdateLinks = $false 
$excelApp.DisplayAlerts = $false 

$tarBook = $excelApp.Workbooks.Open($configObject.TargetFile)
$tarSheet = $tarBook.Worksheets.Item($configObject.SheetName) 

$rowCount = $tarSheet.UsedRange.Cells.Rows.Count

for ($row = 2; $row -le $rowCount; ++$row) {
    $slaType = $tarSheet.Cells.Item($row, $configObject.SLATypeColumn).Value().ToString()
    $startTime = $tarSheet.Cells.Item($row, $configObject.StartTimeColumn).Value()
    $pauseDurationInSecs = $tarSheet.Cells.Item($row, $configObject.PauseDurationColumn).Value()

    #$startTime = [DateTime]::ParseExact($startTime,$configObject.StartTimeFormatColumn, $null) 
    $pauseDurationInSecs = $(if ([string]::IsNullOrEmpty($pauseDurationInSecs)) { 0 } else { [int]::Parse($pauseDurationInSecs) })

    $breachDate = GetSLABreachDate $startTime $slaType $pauseDurationInSecs

    $tarSheet.Range("$($configObject.Out_BreachDateColumn)$row").Value2 = $breachDate.ToString($configObject.StartTimeFormatColumn)

    $percentComplete = [math]::Round($row * 100 / $rowCount, 0)
    Write-Progress -Activity "SLA Breach Calculation" -Status "Processing" -PercentComplete $percentComplete -CurrentOperation "Complete $($percentComplete)%"
}

$slaMetCondition = "=IF($($configObject.StopTimeColumn)2>$($configObject.Out_BreachDateColumn)2,""YES"",""NO"")"
$slaMetRange = "$($configObject.Out_IsBreachedColumn)2:$($configObject.Out_IsBreachedColumn)$rowCount"
$tarSheet.Range($slaMetRange ).formula = $slaMetCondition

$tarSheet.Range("$($configObject.Out_BreachDateColumn)1").Value2 = "Auto_BreachDate"
$tarSheet.Range("$($configObject.Out_IsBreachedColumn)1").Value2 = "Auto_SLAMissed"

function ApplyFormatting($srcRange, $tarRange)
{
    $srcRng = $tarSheet.Range($srcRange)
    $srcRng.copy() 
    $tarRng = $tarSheet.Range($tarRange)
    $tarRng.pastespecial(-4122,-4142,$false,$false)
}

$srcRng = "$($configObject.StopTimeColumn)1 : $($configObject.StopTimeColumn)$rowCount"
$tarRng = "$($configObject.Out_BreachDateColumn)1 : $($configObject.Out_BreachDateColumn)$rowCount"
ApplyFormatting $srcRng $tarRng | Out-Null
$tarRng = "$($configObject.Out_IsBreachedColumn)1 : $($configObject.Out_IsBreachedColumn)$rowCount"
ApplyFormatting $srcRng $tarRng | Out-Null

$tarBook.save()

$tarBook.Close($true)
$excelApp.Quit()

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelApp)
Remove-Variable -Name excelApp

Write-Host $("Completed in {0} Seconds" -f $($stopWatch.ElapsedMilliseconds / 1000))
$stopWatch.Stop()

Write-Progress -Activity "SLA Breach Calculation" -Status "Done" -PercentComplete 100 -CurrentOperation "Complete 100%"

II $(split-path -parent $configObject.TargetFile)


function Search-TextLog
{
[CmdletBinding()]
param
(
    [parameter(Mandatory=$true)]
    [string[]] $serverLogFolders = @(),
    [parameter(Mandatory=$true)]
    [string] $localFolder,

    [parameter(Mandatory=$true)]
    [string] $logFilterPattern,

    [parameter(Mandatory=$true)]
    [string] $logFilterStartDateTime,
    [parameter(Mandatory=$true)]
    [string] $logFilterEndDateTime,
    [parameter(Mandatory=$true)]
    [string] $logFilterDateTimeFormat,
    [parameter(Mandatory=$true)]
    [string] $logFilterDateTimeZone,

    [parameter(Mandatory=$true)]
    [string] $logPrintDateTimeZone,
    
    [parameter(Mandatory=$true)]
    [string] $logTypeControlFile,
    [parameter(Mandatory=$true)]
    [string] $logTypeControlKey   
)

    Import-Module -Name "VA.Script.Utility" -Force
    Import-Module -Name "VA.IO.Utility" -Force
    Import-Module -Name "VA.DateTime.Utility" -Force

    $scriptRoot = "$PSScriptRoot$($fileSlash)"
    [void](IsNullOrEmpty($logTypeControlFile) -and ($logTypeControlFile = "$($scriptRoot)LogTypeControlFile.json"))

    $logControlTypes = Get-Content $logTypeControlFile | ConvertFrom-Json 
    $logCtrl = $logControlTypes.LogTypes | ? { $_.LogType -eq $logTypeControlKey }

    $filterTimeZone = Get-TimeZone($logFilterDateTimeZone)
    $filterStartDateTime =  [DateTime]::ParseExact($logFilterStartDateTime, $logFilterDateTimeFormat, [Globalization.CultureInfo]::InvariantCulture) 
    $filterEndDateTime =  [DateTime]::ParseExact($logFilterEndDateTime, $logFilterDateTimeFormat, [Globalization.CultureInfo]::InvariantCulture) 
    $filterStartUtcDateTime =  [TimeZoneInfo]::ConvertTimeToUtc($filterStartDateTime, $filterTimeZone)
    $filterEndUtcDateTime =  [TimeZoneInfo]::ConvertTimeToUtc($filterEndDateTime, $filterTimeZone)

    $logEntryTimeZone = Get-TimeZone($logCtrl.LogDateTimeZone)
    $printTimeZone = Get-TimeZone($logPrintDateTimeZone)

    $targetFolder = "$localFolder$($fileSlash)$logTypeControlKey$($fileSlash){0}$fileSlash" -f $($filterEndDateTime.ToString("yyyy-MM-dd"))
    $targetLogFile = "$($targetFolder)Filtered_$($logTypeControlKey).log"
    GCI -Path $targetFolder -Recurse | % { rm -Recurse -Path $_.FullName }
    [void](New-Item $targetFolder -ItemType Directory -Force)

    $idx = 0
    $splitSize = 5MB

    $serverLogFolders | GCI -Recurse -Filter $logCtrl.LogFileType | ? { $_.Name -match $logCtrl.LogFileNameFormat } | ? { 
        $file = $_
        !($file.LastWriteTime.ToUniversalTime() -lt $filterStartUtcDateTime -or $file.CreationTime.ToUniversalTime() -gt $filterEndUtcDateTime)
    } | Sort-Object LastWriteTime | % {
        $file = $_
        ++$idx
        $targetFile = "$targetFolder$($idx)_$($file.Name)"
        CP -Path $file.FullName -Destination $targetFile

        if($file.Length -gt $splitSize)
        {
            Split-TextFile  -sourceFile $targetFile -targetFolder $targetFolder -targetFileNameFormat "$idx_$($file.Name)" -splitLimit 2MB -adjustLinefeedBoundary
            rm $targetFile
        }
    }

    $filteredLogs = New-Object Collections.Generic.List[Object]

    GCI $targetFolder -Filter $logCtrl.LogFileType -Recurse -Depth 0 | Sort-Object LastWriteTime | GC | Select-String -Pattern $logCtrl.LogEntryFormat -AllMatches | % { $_.Matches } | % {
        $match = $_
        $logItem = [PSCustomObject]@{
            "Date" = $_.Groups["DATE"].Value
            "Time" = $_.Groups["TIME"].Value
            "UtcDateTime" = $null
            "LogEntry" = $_.Groups["ENTRY"].Value
        }
     
        $logDateTime = [DateTime]::ParseExact("$($logItem.Date) $($logItem.Time)" , "$($logCtrl.LogDateFormat) $($logCtrl.LogTimeFormat)" , [Globalization.CultureInfo]::InvariantCulture) 
        $logUtcDateTime = [TimeZoneInfo]::ConvertTimeToUtc($logDateTime, $logEntryTimeZone)

        if($logUtcDateTime -ge $filterStartUtcDateTime -and $logUtcDateTime -le $filterEndUtcDateTime)
        {
            $logPrintDateTime = [TimeZoneInfo]::ConvertTimeFromUtc($logUtcDateTime, $printTimeZone)
            $logItem.Date = $logPrintDateTime.ToString("dd-MM-yyyy")
            $logItem.Time = $logPrintDateTime.ToString("HH:mm:ss tt")
            $logItem.UtcDateTime = $logUtcDateTime
            $filteredLogs.Add($logItem)
        }

        if($filteredLogs.Count -ge 3000)
        {
            Add-Content $targetLogFile $($filteredLogs | Sort-Object UtcDateTime | Out-String -Width 8000)
            $filteredLogs.Clear()        
        }
    }

    GCI -Path $targetFolder -Recurse | ? { $_.FullName -ne $targetLogFile } | % { rm -Recurse -Path $_.FullName }

    Add-Content $targetLogFile $($filteredLogs | Sort-Object UtcDateTime | Out-String -Width 8000)

    $targetFolder
}






param(
[string]$mappingFile = "$PSScriptRoot\WorkbookTemplateMapping.json",
[string]$sourceFolder = "$PSScriptRoot\Test\SRC",
[string]$templateFile = "$PSScriptRoot\Test\Template.xlsx",
[string]$targetFolder = "$PSScriptRoot\Test\"
)

$stopWatch = New-Object System.Diagnostics.Stopwatch
$stopWatch.Start()

CLS

. "$PSScriptRoot\ProcessWorkBookVariableTemplates.ps1"

$templateMap = Get-Content $mappingFile | ConvertFrom-Json 
$totalSheetCount = $sheetTemplateMap.TargetSourceColumnMapping.Count

$excelApp = New-Object -ComObject "Excel.Application"
$excelApp.Visible = $true

$targetFile = "$targetFolder\output.xlsx"
CP $templateFile $targetFile

$tarBook = $excelApp.Workbooks.Open($targetFile)

$tarStartIndexes = @{}

$totalSrcFiles = (GCI $sourceFolder -Filter *.xlsx -Depth 0).Count
$processedCount = 0

GCI $sourceFolder -Filter *.xlsx -Depth 0 |
%{    
    $srcBookName = $_.FullName
    $srcBook = $excelApp.Workbooks.Open($srcBookName) 
    $processedSheetCount = 0

    $templateMap |
    %{
        $sheetTemplateMap = $_

        $srcSheetName = $sheetTemplateMap.SourceSheet        
        $srcStartIndex = $sheetTemplateMap.SourceStartRow  
        $srcSheet = $srcBook.Worksheets.Item($srcSheetName) 

        $tarSheetName = $sheetTemplateMap.TargetSheet        
        $tarStartIndex = $sheetTemplateMap.TargetStartRow 
        $tarSheet = $tarBook.Worksheets.Item($tarSheetName)       

        if(!$tarStartIndexes.ContainsKey($tarSheetName))
        {
            $tarStartIndexes.Add($tarSheetName,$tarStartIndex)
        }

        $tarFinalRowIndex = 0
        $tarStartRowIndex = $tarStartIndexes[$tarSheetName]

        $sheetTemplateMap.TargetSourceColumnMapping | ? { !$_[1].Contains("%") } | 
        %{
            $srcCol = $_[1]
            $tarCol = $_[0]
            
            $srcSheet.activate()
            $rowCount = [long]::Parse($excelApp.Evaluate("=ROW(OFFSET(${srcCol}1,COUNTA(${srcCol}:${srcCol})-1,0))"))             
            $tarEndRowIndex = $tarStartRowIndex + $rowCount - 1

            if($tarEndRowIndex -gt $tarFinalRowIndex)
            {
                $tarFinalRowIndex = $tarEndRowIndex
            }

            if($rowCount -gt 0)
            {
                $srcSheet.activate()            
                $srcRng = $srcSheet.Range("${srcCol}$srcStartIndex : ${srcCol}$rowCount")
                $srcRng.copy()            
            
                $tarSheet.activate()
                $tarRng = $tarSheet.Range("${tarCol}$tarStartRowIndex : ${tarCol}$tarEndRowIndex")
                $tarSheet.Paste($tarRng)
            }

            $completePercent = $(++$processedSheetCount/$totalSheetCount)
            Write-Progress -Id 2 -Activity "Merging Sheet" -Status $srcSheetName -PercentComplete $completePercent -CurrentOperation "Complete $completePercent%"
        }

        $sheetTemplateMap.TargetSourceColumnMapping | ? { $_[1].Contains("%") } | 
        %{
            $srcCol = $_[1]
            $tarCol = $_[0]

            $match = [Text.RegularExpressions.Regex]::Match($srcCol,"%(?<TYPE>.+):(?<VAR>.+)")
            $type = $match.Groups["TYPE"].Value
            $var = $match.Groups["VAR"].Value
            $value = "" 

            switch($type){
               "Static" { 
                    $value = $var;
                    break;
                }

               "Dynamic" {  
                    $value = & $var $srcBookName $sheetTemplateMap           
                    break; 
                }  
            }

            if($tarFinalRowIndex -gt 0)
            {
                $tarSheet.activate()
                $tarSheet.Range("${tarCol}$tarStartRowIndex : ${tarCol}$tarFinalRowIndex").Value = $value
            }

            $completePercent = $(++$processedSheetCount/$totalSheetCount)
            Write-Progress -Id 2 -Activity "Merging Sheet" -Status $srcSheetName -PercentComplete $completePercent -CurrentOperation "Complete $completePercent%"
        }

        $tarBook.Save() 
        $tarStartIndexes[$tarSheetName] = $tarFinalRowIndex + 1
    }

    $srcBook.Close($false)

    $completePercent = $(++$processedCount/$totalSrcFiles)
    Write-Progress -Activity "Merging Workbook" -Status $_.Name -PercentComplete $completePercent -CurrentOperation "Complete $completePercent%"
}

$tarBook.Close($false)
$excelApp.Quit()

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelApp)
Remove-Variable -Name excelApp

Write-Host $("Completed in {0} Seconds" -f $($stopWatch.ElapsedMilliseconds / 1000))
$stopWatch.Stop()

param(
[string]$mappingFile = "ConsolidationSample\WorkbookTemplateMapping.json"
)

function DoesComesFirst([string]$first, [string]$second)
{
    if($first.Length -lt $second.Length) { return $true }
    if($first.Length -gt $second.Length) { return $false }
    
    $length = $first.Length
    $index = 0

    while($index -lt $length)
    {
        $firstChar = $first[$index]
        $secondChar = $second[$index]

        if($firstChar -eq $secondChar) { ++$index; continue }

        if($firstChar -lt $secondChar)
        {
            return $true
        }
        else
        {
            return $false
        }       
    }

}

function IsAbsolutePath([string] $path)
{
    return [System.IO.Path]::IsPathRooted($path);
}

$stopWatch = New-Object System.Diagnostics.Stopwatch
$stopWatch.Start()

CLS

if(!(IsAbsolutePath $mappingFile))
{
    $rootFolder = $(split-path -parent $MyInvocation.MyCommand.Definition) + "\"
    $mappingFile = $rootFolder + $mappingFile
}

$rootFolder = $(split-path -parent $mappingFile) + "\"

$mappingControl = Get-Content $mappingFile -Raw | ConvertFrom-Json 

[string]$sourceFolder = $mappingControl.SourceFolder
[string]$templateFile = $mappingControl.TargetTemplateFile
[string]$targetFolder = $mappingControl.TargetFolder
[string]$customScript = $mappingControl.CustomizationScript

if(!(IsAbsolutePath $sourceFolder)) { $sourceFolder = $rootFolder + $sourceFolder }
if(!(IsAbsolutePath $templateFile)) { $templateFile = $rootFolder + $templateFile }
if(!(IsAbsolutePath $targetFolder)) { $targetFolder = $rootFolder + $targetFolder }
if(!(IsAbsolutePath $customScript)) { $customScript = $rootFolder + $customScript }

. "$customScript"

$templateMap = $mappingControl.WorkBookMapping
$totalSheetCount = $templateMap.Count

$excelApp = New-Object -ComObject "Excel.Application"
$excelApp.Visible = $true
$excelApp.AskToUpdateLinks  = $false 
$excelApp.DisplayAlerts = $false 


$targetFile = "$targetFolder\$($mappingControl.TargetFileName)"
CP $templateFile $targetFile

$tarBook = $excelApp.Workbooks.Open($targetFile)

$tarStartIndexes = @{}

$totalSrcFiles = (GCI $sourceFolder -Filter $mappingControl.SourceFileTypes -Recurse).Count
$processedCount = 0

Write-Progress -Activity "Merging Workbook" -Status "Starting" -PercentComplete 0 -CurrentOperation "Complete 0%"

GCI $sourceFolder -Filter $mappingControl.SourceFileTypes -Recurse |
%{    
    $srcBookName = $_.FullName

    $excelApp.AskToUpdateLinks  = $false 
    $excelApp.DisplayAlerts = $false 
    $srcBook = $excelApp.Workbooks.Open($srcBookName,$false) 

    $processedSheetCount = 0  

    Write-Progress -Id 2 -Activity "Merging Sheet" -Status "Starting" -PercentComplete 0 -CurrentOperation "Complete 0%"  

    $templateMap |
    %{
        $sheetTemplateMap = $_

        $srcSheetName = $sheetTemplateMap.SourceSheet       
       
        $srcStartIndex = $sheetTemplateMap.SourceStartRow  
        $srcSheet = $srcBook.Worksheets.Item($srcSheetName) 

        if($srcSheet.AutoFilterMode)
        {
            $srcSheet.AutoFilterMode = $false
        }

        $tarSheetName = $sheetTemplateMap.TargetSheet        
        $tarStartIndex = $sheetTemplateMap.TargetStartRow 
        $tarSheet = $tarBook.Worksheets.Item($tarSheetName)    
        
        $rangeCopy = $sheetTemplateMap.RangeCopy
        $copyValues = $sheetTemplateMap.CopyValues
        $srcColToCountRows = $sheetTemplateMap.SourceColumnToCountRows

        if(!$tarStartIndexes.ContainsKey($tarSheetName))
        {
            $tarStartIndexes.Add($tarSheetName,$tarStartIndex)
        }

        $srcFinalRowIndex = 0
        $tarFinalRowIndex = 0
        $tarStartRowIndex = $tarStartIndexes[$tarSheetName]

        $processedColumnCount = 0
        $totalColumnCount = $sheetTemplateMap.TargetSourceColumnMapping.Count
        Write-Progress -Id 3 -Activity "Merging Column" -Status "Starting" -PercentComplete 0 -CurrentOperation "Complete 0%"

        #$srcSheet.activate()
        #$rowCount = $srcSheet.UsedRange.SpecialCells(11).Row

        $isRowCounted = $false

        if($srcColToCountRows -ne "")
        {
            $isRowCounted = $true
            $srcSheet.activate()
            #$rowCount = [long]::Parse($excelApp.Evaluate("=COUNTA($($srcColToCountRows)$srcStartIndex : $($srcColToCountRows)65535)"))
            #$rowCount += $srcStartIndex - 1
            
            $srcColRange = "$($srcColToCountRows)$srcStartIndex : $($srcColToCountRows)65535"
            #SUMPRODUCT is just a place holder to treat the formula as Array formula, as we  cannot mimick CTRL+SHFT+ENTR press,
            #in an excel cell, to make a formula as an array formula, by placing it inside {}.
            #SUMPRODUCT is the only array formula which does not requires,
            #CTRL+SHFT+ENTR and the formula will be treat as array formula without {}, in an excel cell 
            #$rowCount = [long]::Parse($excelApp.Evaluate("=SUMPRODUCT(MAX(( $srcColRange <> `"`")*(ROW( $srcColRange ))))"))  
            
            #Above fix not required, as VBA will always consider the formula as Array Formula,
            #hence the SUMPRODUCT place holder not required.      
            $rowCount = [long]::Parse($excelApp.Evaluate("=MAX(( $srcColRange <> `"`")*(ROW( $srcColRange )))"))            
        }       

        $directMappedRows = 0

        $srcStartCol = "X" * 5
        $srcEndCol = "A"
        $tarStartCol = "X" * 5
        $tarEndCol = "A"

        $sheetTemplateMap.TargetSourceColumnMapping | ? { !$_[1].Contains("%") } | 
        %{
            ++$directMappedRows

            $srcCol = $_[1]
            $tarCol = $_[0]
            
            if(!$isRowCounted)
            {
                $srcSheet.activate()                
                #$rowCount = [long]::Parse($excelApp.Evaluate("=ROW(OFFSET(${srcCol}1,COUNTA(${srcCol}:${srcCol})-1,0))"))
                
                $srcColRange = "$srcCol : $srcCol"                
                #SUMPRODUCT is just a place holder to treat the formula as Array formula, as we  cannot mimick CTRL+SHFT+ENTR press,
                #in an excel cell, to make a formula as an array formula, by placing it inside {}.
                #SUMPRODUCT is the only array formula which does not requires,
                #CTRL+SHFT+ENTR and the formula will be treat as array formula without {}, in an excel cell 
                #$rowCount = [long]::Parse($excelApp.Evaluate("=SUMPRODUCT(MAX(( $srcColRange <> `"`")*(ROW( $srcColRange ))))"))
                
                #Above fix not required, as VBA will always consider the formula as Array Formula,
                #hence the SUMPRODUCT place holder not required.                
                $rowCount = [long]::Parse($excelApp.Evaluate("=MAX(( $srcColRange <> `"`")*(ROW( $srcColRange )))"))
            }       

            $tarEndRowIndex = $tarStartRowIndex + ($rowCount - $srcStartIndex + 1) - 1

            if($tarEndRowIndex -gt $tarFinalRowIndex)
            {
                $tarFinalRowIndex = $tarEndRowIndex
            }

            if($rangeCopy -eq 0)
            {
                if($rowCount -gt 0 -and $rowCount -ge $srcStartIndex -and $tarEndRowIndex -ge $tarStartRowIndex)
                {
                    $srcSheet.activate()            
                    $srcRng = $srcSheet.Range("${srcCol}$srcStartIndex : ${srcCol}$rowCount")
                    $srcRng.copy()            
            
                    $tarSheet.activate()
                    $tarRng = $tarSheet.Range("${tarCol}$tarStartRowIndex : ${tarCol}$tarEndRowIndex")

                    if($copyValues -eq 0)
                    {
                        $tarSheet.Paste($tarRng)                        
                    }
                    else
                    {
                        $tarRng.pastespecial(-4163)
                    }
                }

                $completeColumnPercent = $(++$processedColumnCount * 100/$totalColumnCount)
                Write-Progress -Id 3 -Activity "Merging Column" -Status $srcCol -PercentComplete $completeColumnPercent -CurrentOperation "Complete $completeColumnPercent%"
            } 
            else
            {
                if($rowCount -gt $srcFinalRowIndex)
                {
                    $srcFinalRowIndex = $rowCount
                }

                if(DoesComesFirst $srcCol $srcStartCol)
                {
                    $srcStartCol = $srcCol
                }

                if(!(DoesComesFirst $srcCol $srcEndCol))
                {
                    $srcEndCol = $srcCol
                }
              
                if(DoesComesFirst $tarCol $tarStartCol)
                {
                    $tarStartCol = $tarCol
                }

                if(!(DoesComesFirst $tarCol $tarEndCol))
                {
                    $tarEndCol = $tarCol
                }  
            }           
        }

        if($rangeCopy -ne 0)
        {
            if($srcFinalRowIndex -gt 0 -and $srcFinalRowIndex -ge $srcStartIndex -and $tarFinalRowIndex -ge $tarStartRowIndex)
            {
                $srcSheet.activate()            
                $srcRng = $srcSheet.Range("${srcStartCol}$srcStartIndex : ${srcEndCol}$srcFinalRowIndex")
                $srcRng.copy()            
            
                $tarSheet.activate()
                $tarRng = $tarSheet.Range("${tarStartCol}$tarStartRowIndex : ${tarEndCol}$tarFinalRowIndex")
                
                if($copyValues -eq 0)
                {
                    $tarSheet.Paste($tarRng)                        
                }
                else
                {
                    $tarRng.pastespecial(-4163)
                }
            }

            $completeColumnPercent = $($directMappedRows * 100/$totalColumnCount)
            Write-Progress -Id 3 -Activity "Merging Column" -Status $srcCol -PercentComplete $completeColumnPercent -CurrentOperation "Complete $completeColumnPercent%"
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

            if($tarFinalRowIndex -gt 0 -and $tarFinalRowIndex -ge $tarStartRowIndex)
            {
                $tarSheet.activate()
                $tarSheet.Range("${tarCol}$tarStartRowIndex : ${tarCol}$tarFinalRowIndex").Value2 = $value
            }     
            
            $completeColumnPercent = $(++$processedColumnCount * 100/$totalColumnCount)
            Write-Progress -Id 3 -Activity "Merging Column" -Status $srcCol -PercentComplete $completeColumnPercent -CurrentOperation "Complete $completeColumnPercent%"       
        }

        $tarBook.Save() 

        if($tarFinalRowIndex -gt 0 -and $tarFinalRowIndex -ge $tarStartRowInde)
        {        
            $tarStartIndexes[$tarSheetName] = $tarFinalRowIndex + 1
        }

        $completeSheetPercent = $(++$processedSheetCount * 100/$totalSheetCount)
        Write-Progress -Id 2 -Activity "Merging Sheet" -Status $srcSheetName -PercentComplete $completeSheetPercent -CurrentOperation "Complete $completeSheetPercent%"
    }

    $srcBook.Close($false)

    $completePercent = $(++$processedCount * 100/$totalSrcFiles)
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

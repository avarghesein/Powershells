
$_slaMappingTable = @{ }
$_holidays = 0
$_startBusinessTime = [DateTime]::Now.TimeOfDay
$_endBusinessTime = [DateTime]::Now.TimeOfDay
$_businessDayDurationInSeconds = 0

function __Init__([string]$thisPath, $config) {
    $script:_holidays = (Get-Content $config.HolidayConfigPath -Raw | ConvertFrom-Json)

    $slaConfigObject = Get-Content $config.SLAConfigPath -Raw | ConvertFrom-Json 
    
    $script:_startBusinessTime = [DateTime]::Parse($slaConfigObject.StartTime).TimeOfDay
    $script:_endBusinessTime = [DateTime]::Parse($slaConfigObject.StopTime).TimeOfDay

    $script:_businessDayDurationInSeconds = ([TimeSpan]($_endBusinessTime - $_startBusinessTime)).TotalSeconds

    $slaValueRegx = New-Object Text.RegularExpressions.Regex("(?<DUR>[^\|]+)\|(?<UNT>[^\|]+)(\|(?<FUL>.+))?")

    $slaConfigObject.psobject.properties | ? { $_.Name.Contains( "- P") } | % {

        $key = $_.Name        
        $val = $_.Value

        $duration = [int]::Parse($slaValueRegx.Match($val).Groups["DUR"].Value)
        $unit = $slaValueRegx.Match($val).Groups["UNT"].Value
        $fullTime = $slaValueRegx.Match($val).Groups["FUL"].Value

        $valueObject = [PSCustomObject]@{
            "DurationInSeconds" = $duration
            "IsFullTime"        = $fullTime -eq "F"
        }

        switch ($unit) {
            "M" {                 
                $valueObject.DurationInSeconds *= 60
                break;
            }

            "H" {  
                $valueObject.DurationInSeconds *= 60 * 60
                break; 
            }  

            "D" {  
                $valueObject.DurationInSeconds *= $_businessDayDurationInSeconds
                break; 
            }  
        }

        $script:_slaMappingTable[$key] = $valueObject
    }
}

function IsOutSideBusiness([DateTime]$date) {
    return $date.TimeOfDay -lt $script:_startBusinessTime -or `
        $date.TimeOfDay -ge $script:_endBusinessTime
}

function IsHoliday($date) {
    $dateStr = $date.ToString($_holidays.DateFormat)
    return (($_holidays.Holidays | ? { $_ -imatch $dateStr }).Count -gt 0)
}

function FixToBusinessHours([DateTime]$date, [ref]$fixedDate) {
    $isOutSideBusiness = $false
    $dateChanged = $false

    while (`
            $date.DayOfWeek -eq [DayOfWeek]::Sunday -or `
            $date.DayOfWeek -eq [DayOfWeek]::Saturday -or `
        (IsHoliday($date)) -or ($isOutSideBusiness = IsOutSideBusiness($date))) {
        if (!$isOutSideBusiness) {
            $date = $date.Date.AddDays(1) + $_startBusinessTime
        }
        else {
            if ($date.TimeOfDay -lt $_startBusinessTime) {
                $date = $date.Date + $_startBusinessTime
            }
            else {
                $date = $date.Date.AddDays(1) + $_startBusinessTime
            }
        }

        $dateChanged = $true
    }

    $fixedDate.value = $date
    return $dateChanged
}

function FindBreachDate($startDate, $slaDurationInSecs, $businessHourSupportOnly) {
    $defSlaDurationInSecs = 60 * 60 #  1 hour default

    if ($slaDurationInSecs -lt $defSlaDurationInSecs) {
        $defSlaDurationInSecs = $slaDurationInSecs
    }

    [datetime]$breachDate = $startDate

    if ($businessHourSupportOnly) {
        [void](FixToBusinessHours -date $startDate -fixedDate([ref]$breachDate))
    }

    $reminder = 0
    $quotient = [math]::divrem( $slaDurationInSecs, $defSlaDurationInSecs, [ref]$reminder )

    for ($idx = 1; $idx -le $($quotient + 1); $idx++) {
        $secsToAdd = $defSlaDurationInSecs

        if ($idx -eq $($quotient + 1)) {
            $secsToAdd = $reminder 
        }

        $prevDate = $breachDate 
        $incDate = $breachDate.AddSeconds($secsToAdd)

        if ($businessHourSupportOnly) {
            $isDateFixed = FixToBusinessHours -date $incDate -fixedDate([ref]$breachDate)

            if ($isDateFixed) { 
                $outsideBusinessMins = $incDate - ($prevDate.Date + $script:_endBusinessTime)
                $breachDate += $outsideBusinessMins
            }
        }
        else {
            $breachDate = $incDate
        }
    }

    return $breachDate
}

function  GetSLABreachDate {
    param (
        [DateTime]$startDate,
        [string]$slaType,
        [int]$pauseDurationInSeconds
    )

    $slaObject = $_slaMappingTable[$slaType]
    $businessHourSupportOnly = $(!$slaObject.IsFullTime)
    $breachDate = FindBreachDate $startDate $($slaObject.DurationInSeconds + $pauseDurationInSeconds) $businessHourSupportOnly

    return $breachDate 
}


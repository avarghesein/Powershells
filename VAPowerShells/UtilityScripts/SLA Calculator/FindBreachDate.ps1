
CLS

$_startBusinessTime = [DateTime]::Parse("7:30:00 AM").TimeOfDay
$_endBusinessTime = [DateTime]::Parse("5:30:00 PM").TimeOfDay

function IsOutSideBusiness([DateTime]$date)
{
    return $date.TimeOfDay -lt $_startBusinessTime -or `
            $date.TimeOfDay -gt $_endBusinessTime
}

function IsHoliday($date)
{
    return $false
}

function FixToBusinessHours([DateTime]$date, [ref]$fixedDate)
{
    $isOutSideBusiness = $false
    $dateChanged = $false

    while(`
        $date.DayOfWeek -eq [DayOfWeek]::Sunday -or `
        $date.DayOfWeek -eq [DayOfWeek]::Saturday -or `
        (IsHoliday($date))-or ($isOutSideBusiness = IsOutSideBusiness($date)))
    {
        if(!$isOutSideBusiness)
        {
            $date = $date.Date.AddDays(1) + $_startBusinessTime
        }
        else
        {
            if($date.TimeOfDay -lt $_startBusinessTime)
            {
                $date = $date.Date + $_startBusinessTime
            }
            else
            {
                $date = $date.Date.AddDays(1) + $_startBusinessTime
            }
        }

        $dateChanged = $true
    }

    $fixedDate.value = $date
    return $dateChanged
}

function FindBreachDate($startDate, $slaDurationInMins, $businessHourSupportOnly)
{
    $defSlaDurIncMins = 60

    if($slaDurationInMins -lt $defSlaDurIncMins)
    {
        $defSlaDurIncMins = $slaDurationInMins
    }

    [datetime]$adjustedStartDate = $startDate

    if($businessHourSupportOnly)
    {
        [void](FixToBusinessHours -date $startDate -fixedDate([ref]$adjustedStartDate))
    }

    $durationInMinsAdded = 0

    $reminder = 0
    $quotient = [math]::divrem( $slaDurationInMins, $defSlaDurIncMins, [ref]$reminder )

    #while($durationInMinsAdded -lt $slaDurationInMins)
    for($idx = 1; $idx -le $($quotient + 1); $idx++)
    {
        #$durationInMinsAdded += $defSlaDurIncMins

        $minsToAdd = $defSlaDurIncMins

        if($idx -eq $($quotient + 1))
        {
            $minsToAdd = $reminder 
        }

        $prevDate = $adjustedStartDate 
        $incDate = $adjustedStartDate.AddMinutes($minsToAdd)

        if($businessHourSupportOnly)
        {
            $isDateFixed = FixToBusinessHours -date $incDate -fixedDate([ref]$adjustedStartDate)

            if($isDateFixed)
            {
                $outsideBusinessMins = $incDate - $prevDate
                $adjustedStartDate += $outsideBusinessMins
            }
        }
    }

    return $adjustedStartDate
}

#Test your SLA here

$curDate = "2019-06-20 18:30:35" #start time
$startDate = [DateTime]::ParseExact($curDate,"yyyy-MM-dd HH:mm:ss", $null) 

$slaDurMins = 10 * 60 * 3 #3 days SLA
$pauseDurMins = 20 #20 Mins

#$slaDurMins = 20 #20 mins SLA

$breachDate = FindBreachDate $startDate $($slaDurMins+$pauseDurMins) $true


Write-Host("StartDate: $curDate, Breach Date:$breachDate")


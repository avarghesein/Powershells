
How To Run: (Every time)

    1. Copy the SLA Import from Service Now to 'Data\SLA_DATA.xlsx'. The name of the xlsx should exactly match.
    2. Run 'Main.ps1' from Powershell console or Powershell ISE
    3. Access the output in 'Data\SLA_DATA.OUT.xlsx'
    4. Validate Columns 'Auto_BreachDate and Auto_SLAMissed'

        PS: Run the below command before the very first un of Main.ps1 script
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser


How To Configure: (If required only)

    1. Configure input SLA Dump excel file details in 'Config\Config.json' (Columns for StartTime, PauseDuration and Output columns)
    2. Configure SLA specific details in 'Config\SLA.json' (Business hours, SLA Types, Duration, Priority etc)
    3. Configure Holiday details in 'Config\Holiday.json'



#Name: OnTopClock.ps1 
#Usage: powershell.exe -WindowStyle Hidden -File "<Path>\OnTopClock.ps1"

#Purpose:
#Always on top Digital Clock for Windows11,
#Enabling the taskbar to be hidden for more screen space,
#While keeping the date and time visible,
#as a workaround for the non-resizable taskbar in Windows 11.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.ShowInTaskbar = $false  # Hides the taskbar icon
$form.TopMost = $true
$form.StartPosition = 'Manual'
$form.Location = New-Object Drawing.Point(0, 0)
$form.BackColor = [System.Drawing.Color]::White
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = [System.Drawing.Color]::White                      
#$form.TransparencyKey = $form.BackColor # For transparency

$label = New-Object Windows.Forms.Label
$label.ForeColor = [System.Drawing.Color]::Black
$label.Font = New-Object System.Drawing.Font('Arial', 11, [System.Drawing.FontStyle]::Bold)
$label.AutoSize = $true
$label.BackColor = [System.Drawing.Color]::Transparent

$form.Controls.Add($label)

# Define the function to update the time and adjust form size
function Update-Time {
    $global:label.Text = (Get-Date).ToString("dd/M h:mm")
    $global:form.ClientSize = $global:label.PreferredSize
    $global:form.Width -= 4
    $global:form.Height -= 6
    $global:form.TopMost = $true
}

# Define the second timer outside for proper garbage collection
$secondTimer = New-Object Windows.Forms.Timer
$secondTimer.Interval = 60000  # 60 seconds (1 minute)
$secondTimer.Add_Tick({
    Update-Time
    $secondsRemaining = 60 - (Get-Date).Second
    $secondTimer.Interval = $secondsRemaining
})

# Initial Timer logic: wait for the next full minute
$initialTimer = New-Object Windows.Forms.Timer
$initialTimer.Interval = 5  # 5 seconds
$initialTimer.Add_Tick({
    Update-Time

    # Calculate seconds remaining until the next full minute
    $secondsRemaining = 60 - (Get-Date).Second
    Start-Sleep -Seconds $secondsRemaining  # Sleep until the next full minute

    Update-Time

    # Start the second timer after the sleep
    $secondTimer.Start()

    # Stop and dispose of the initial timer
    $initialTimer.Stop()
    $initialTimer.Dispose()
})

# Start the initial timer (trigger the first tick immediately)
$initialTimer.Start()
# Show the form and display the time immediately
$form.ShowDialog()

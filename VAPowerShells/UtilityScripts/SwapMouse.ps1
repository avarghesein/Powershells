$key = 'HKCU:\Control Panel\Mouse'
$mouseKey = (Get-ItemProperty -Path $key -Name SwapMouseButtons).SwapMouseButtons
#If ($mouseKey -eq 0) { Write-Host "Right Mouse" }  Else { Write-Host "Left Mouse" } 
$mouseKey = If ($mouseKey -eq 0) { 1 }  Else { 0 }
If ($mouseKey -eq 0) { Write-Host "Right Mouse" }  Else { Write-Host "Left Mouse" } 
Set-ItemProperty -Path $key -Name SwapMouseButtons -Value $mouseKey

# Add the P/Invoke API definition
$api = Add-Type -PassThru -Namespace Win32 -Name Win32SwapMouseButton -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool SwapMouseButton(bool fSwap);
'@

# Call the API to restore normal mouse button behavior
$api::SwapMouseButton($mouseKey)

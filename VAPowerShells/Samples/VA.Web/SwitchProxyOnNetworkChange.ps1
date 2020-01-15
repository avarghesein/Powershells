function ManageProxy{
    param(
    [parameter(Mandatory=$true)]
    $enable
    )

    $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    $proxyServer = ""
    $proxyServerToDefine = "<Proxy>:<Port>"
    Write-Host "Retrieve the proxy server ..."
    $proxyServer = Get-ItemProperty -path $regKey ProxyServer -ErrorAction SilentlyContinue
    Write-Host $proxyServer

    if($enable -eq $true)
    {
        Set-ItemProperty -path $regKey ProxyEnable -value 1
        Set-ItemProperty -path $regKey ProxyServer -value $proxyServerToDefine
        Write-Host "Proxy is now enabled"
    }
    else
    {
        Set-ItemProperty -path $regKey ProxyEnable -value 0
        Remove-ItemProperty -path $regKey -name ProxyServer
        Write-Host "Proxy is now disabled"
    }
}
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$netadapter = Get-NetAdapter | Where-Object PhysicalMediaType -EQ 802.3
if($netadapter.status -eq "Up"){
    ManageProxy -enable $true
    #$oReturn=[System.Windows.Forms.Messagebox]::Show("LAN connected, Proxy enabled")
}
else {
    ManageProxy -enable $false
    #$oReturn=[System.Windows.Forms.Messagebox]::Show("LAN disconnected, Proxy disabled")
}

[system.enum]::getValues($oReturn.GetType())
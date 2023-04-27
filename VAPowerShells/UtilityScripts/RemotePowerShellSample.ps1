CLS
#Enable-PSRemoting -Force #On Remote Computer

netsh winhttp import proxy source=ie
$pcred = [System.Net.CredentialCache]::DefaultNetworkCredentials#Get-Credential

#$options = New-PSSessionOption –SkipCACheck -SkipCNCheck
$options = New-PSSessionOption -ProxyAccessType IEConfig -ProxyAuthentication Negotiate -ProxyCredential <domain>\<user>  –SkipCACheck -SkipCNCheck
#$options = New-PSSessionOption -ProxyAccessType IEConfig -ProxyCredential $pcred –SkipCACheck -SkipCNCheck

$sess = Enter-PSSession -ComputerName <remoteip> -Port 6000  -Credential <username> -UseSSL -SessionOption $options
ls
Exit-PSSession
Remove-PSSession $sess

###Server Side
#New-SelfSignedCertificate -DnsName <ServerCertificateName> -CertStoreLocation Cert:\LocalMachine\My

###Set HTTP access for powershell
#Run From Command Line (cmd) to work
#winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="ServerIP";CertificateThumbprint="7A032C62F2A8CB6FC34653C186CC5833729991A2"}

###Kow this succeded
#winrm get winrm/config/client

###See current ports
#dir WSMan:\localhost\listener\*\Port

###Change HTTP and HTTPS ports, which are exempted in AWS console
#winrm set winrm/config/Listener?Address=*+Transport=HTTP '@{Port="6000"}'
#winrm set winrm/config/Listener?Address=*+Transport=HTTPS '@{Port="6001"}'

#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

###Test Locally
#$so = New-PsSessionOption –SkipCACheck -SkipCNCheck
#Enter-PSSession -ComputerName 127.0.0.1 -Port 6000  -Credential "331905" -UseSSL -SessionOption $so
#
# Usage eg: VA.Web.Test_PostFileToWebAPI.ps1 -jsonsFolder ".\Documents" -uploadApiUrl "http://localhost:50153/api/upload"
#
param(
[string]$jsonsFolder = ".\Documents",
[string]$uploadApiUrl = "http://localhost:50153/api/upload")

$dropFolder = $jsonsFolder
$url = $uploadApiUrl
Add-Type -AssemblyName System.Web
GCI "$dropFolder"-Filter *.json | % {
	$docContent = GC -Path $_.FullName
	$body = "=" + [Web.HttpUtility]::UrlEncode($docContent)
	$hdrs = @{}
	Try
	{
		$currentDoc = $_.Name
		$response = (Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded; charset=UTF-8' -Headers $hdrs -UseDefaultCredentials 2> $null)
		Write-Output "$currentDoc->OK ($response)"
	}
	Catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Output "$currentDoc->Failed ($ErrorMessage)"
		Break
	}
}
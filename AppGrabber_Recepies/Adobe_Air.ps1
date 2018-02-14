#	Adobe Air

# Get Air version number
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$urlVer = "https://filehippo.com/download_adobe_air/"
$status = invoke-webrequest $urlVer -DisableKeepAlive -UseBasicParsing -Method head
if($status.StatusCode -eq 200){

	$dataVer = Invoke-WebRequest $urlVer
	$adobeAirVersion = $dataVer.ParsedHtml.body.getElementsByTagName('h1') | Where {$_.getAttributeNode('class').Value -eq 'title-text'}
	$adobeAirVersion = $adobeAirVersion.innerText -replace ("Adobe Air ", "")
	$adobeAirVersion = $adobeAirVersion.trim()

	$url = "http://airdownload.adobe.com/air/win/download/latest/AdobeAIRInstaller.exe"

	# Check version
		if(!(Test-Path "$dlLocation\file_versions\Adobe_Air.txt")){
		New-Item "$dlLocation\file_versions\Adobe_Air.txt" -Type file | Out-Null
		}
		
		$adobeAirOldVersion = Get-Content "$dlLocation\file_versions\Adobe_Air.txt"
		
		if($adobeAirVersion -gt $adobeAirOldVersion){
			Set-content "$dlLocation\file_versions\Adobe_Air.txt" -value $adobeAirVersion
			$appsToDL++
			SlackWrite "New update - $recepieName $adobeAirVersion"
			try {
				Start-BitsTransfer -Source "$url" -Destination $dlLocation
				Write-Host "$recepieName $adobeAirVersion - Download complete!" -ForegroundColor 'green'
				LogWrite "$recepieName $adobeAirVersion - Download complete!"
			} catch {
				Write-Host "$recepieName $adobeAirVersion - Download failed!" -ForegroundColor 'red'
				LogWrite "$recepieName $adobeAirVersion - Download failed!"
			}
		} else {
			Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
			LogWrite "$recepieName - No updates found!"
		}
		
} else {
	Write-Host "$recepieName $adobeAirVersion - Download failed!" -ForegroundColor 'red'
	LogWrite "$recepieName - URL not working!"
}

#	Skype

# Get Skype version number
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$urlVer = "https://filehippo.com/download_skype/"
$dataVer = Invoke-WebRequest $urlVer
$skypeVersion = $dataVer.ParsedHtml.body.getElementsByTagName('h1') | Where {$_.getAttributeNode('class').Value -eq 'title-text'}
$skypeVersion = $skypeVersion.innerText -replace ("Skype ", "")
$skypeVersion = $skypeVersion.trim()

$url = "http://download.skype.com/msi/SkypeSetup_$skypeVersion.msi"

# Check version
	if(!(Test-Path "$dlLocation\file_versions\Skype.txt")){
	New-Item "$dlLocation\file_versions\Skype.txt" -Type file | Out-Null
	}
	
	$skypeOldVersion = Get-Content "$dlLocation\file_versions\Skype.txt"
	
	if($skypeVersion -gt $skypeOldVersion){
		Set-content "$dlLocation\file_versions\Skype.txt" -value $skypeVersion
		$appsToDL++
		SlackWrite "New update - $recepieName $skypeVersion"
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			Write-Host "$recepieName $skypeVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $skypeVersion - Download complete!"
		} catch {
			Write-Host "$recepieName $skypeVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $skypeVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}
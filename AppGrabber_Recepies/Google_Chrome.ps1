#	Google Chrome

# Check version
$urlVer = "https://www.whatismybrowser.com/guides/the-latest-version/chrome"
$dataVer = Invoke-WebRequest $urlVer
$chromeVersion = $dataVer.ParsedHtml.getElementsByTagName("td")[1] | select -ExpandProperty innertext

if(!(Test-Path "$dlLocation\file_versions\Google_Chrome.txt")){
	New-Item "$dlLocation\file_versions\Google_Chrome.txt" -Type file | Out-Null
}
	$chromeOldVersion = Get-Content "$dlLocation\file_versions\Google_Chrome.txt"
	
if($chromeVersion -gt $chromeOldVersion){
	Set-content "$dlLocation\file_versions\Google_Chrome.txt" -value $chromeVersion
	$appsToDL++
	SlackWrite "New update - $recepieName $chromeVersion"
	$url = "https://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi"
	try {
		Start-BitsTransfer -Source "$url" -Destination $dlLocation
		Write-Host "$recepieName $chromeVersion - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $chromeVersion - Download complete!"
	} catch {
		Write-Host "$recepieName $chromeVersion - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $chromeVersion - Download failed!"
	}
} else {
	Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
	LogWrite "$recepieName - No updates found!"
}
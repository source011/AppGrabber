#	Adobe Reader DC

# Get Reader DC version number
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$urlVer = "https://filehippo.com/download_adobe-acrobat-reader-dc/"
$dataVer = Invoke-WebRequest $urlVer
$adobeReaderVersion = $dataVer.ParsedHtml.body.getElementsByTagName('h1') | Where {$_.getAttributeNode('class').Value -eq 'title-text'}
$adobeReaderVersion = $adobeReaderVersion.innerText -replace ("Adobe Acrobat Reader DC ", "")
$adobeReaderVersion = $adobeReaderVersion.trim()
$adobeReaderUrlVersion = $adobeReaderVersion.Substring(2) -replace '\.', ''

$url = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/" + $($adobeReaderUrlVersion) + "/AcroRdrDC" + $($adobeReaderUrlVersion) + "_en_US.exe"

# Check version
if(!(Test-Path "$dlLocation\file_versions\Adobe_Reader_DC.txt")){
	New-Item "$dlLocation\file_versions\Adobe_Reader_DC.txt" -Type file | Out-Null
}
	
	$adobeReaderOldVersion = Get-Content "$dlLocation\file_versions\Adobe_Reader_DC.txt"
	
	if($adobeReaderVersion -gt $adobeReaderOldVersion){
		Set-content "$dlLocation\file_versions\Adobe_Reader_DC.txt" -value $adobeReaderVersion
		$appsToDL++
		SlackWrite "New update - $recepieName $adobeReaderVersion"
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			
			Write-Host "$recepieName $adobeReaderVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $adobeReaderVersion - Download complete!"
		} catch {
			Write-Host "$recepieName $adobeReaderVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $adobeReaderVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}
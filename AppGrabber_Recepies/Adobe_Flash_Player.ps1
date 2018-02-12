#	Adobe Flash Player

# Get Flash Player version number
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$urlVer = "https://filehippo.com/download_adobe-flash-player/"
$dataVer = Invoke-WebRequest $urlVer
$adobeFlashPlayerVersion = $dataVer.ParsedHtml.body.getElementsByTagName('h1') | Where {$_.getAttributeNode('class').Value -eq 'title-text'}
$adobeFlashPlayerVersion = $adobeFlashPlayerVersion.innerText -replace ("Adobe Flash Player ", "")
$adobeFlashPlayerVersion = $adobeFlashPlayerVersion.trim()
$adobeFlashPlayerUrlVersion = $adobeFlashPlayerVersion.SubString(0,2)
$url = "https://fpdownload.adobe.com/get/flashplayer/distyfp/current/win/install_flash_player_" + $($adobeFlashPlayerUrlVersion) + "_active_x.msi"
$url2 = "https://fpdownload.adobe.com/get/flashplayer/distyfp/current/win/install_flash_player_" + $($adobeFlashPlayerUrlVersion) + "_plugin.msi"
$url3 = "https://fpdownload.adobe.com/get/flashplayer/distyfp/current/win/install_flash_player_" + $($adobeFlashPlayerUrlVersion) + "_ppapi.msi"
# Check version
	if(!(Test-Path "$dlLocation\file_versions\Adobe_Flash_Player.txt")){
	New-Item "$dlLocation\file_versions\Adobe_Flash_Player.txt" -Type file | Out-Null
	}
	
	$adobeFlashPlayerOldVersion = Get-Content "$dlLocation\file_versions\Adobe_Flash_Player.txt"
	
	if($adobeFlashPlayerVersion -gt $adobeFlashPlayerOldVersion){
		Set-content "$dlLocation\file_versions\Adobe_Flash_Player.txt" -value $adobeFlashPlayerVersion
		$appsToDL++
		SlackWrite "New update - $recepieName $adobeFlashPlayerVersion"
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			Start-BitsTransfer -Source "$url2" -Destination $dlLocation
			Start-BitsTransfer -Source "$url3" -Destination $dlLocation
			
			Write-Host "$recepieName $adobeFlashPlayerVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $adobeFlashPlayerVersion - Download complete!"
		} catch {
			Write-Host "$recepieName $adobeFlashPlayerVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $adobeFlashPlayerVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}
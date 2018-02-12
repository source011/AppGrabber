#	VLC

$url = "https://www.videolan.org/vlc/download-windows.html"
$search = "Installer for 64bit version"
$downloadSw = ((Invoke-WebRequest -Uri $url).Links | Where innerHTML -like $search).href
$VLCVersion = ($downloadSw -split '/')[4]
$downloadSw = $downloadSw -Replace '//','http://'

# Check version
	if(!(Test-Path "$dlLocation\file_versions\VLC.txt")){
	New-Item "$dlLocation\file_versions\VLC.txt" -Type file | Out-Null
	}
	
	$VLCOldVersion = Get-Content "$dlLocation\file_versions\VLC.txt"
	
	if($VLCVersion -gt $VLCOldVersion){
		Set-content "$dlLocation\file_versions\VLC.txt" -value $VLCVersion
		$appsToDL++
		SlackWrite "New update - $recepieName $VLCVersion"
		try {
			Start-BitsTransfer -Source $downloadSw -Destination $dlLocation
			Write-Host "$recepieName $VLCVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $VLCVersion - Download complete!"
		} catch {
			Write-Host "$recepieName $VLCVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $VLCVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}
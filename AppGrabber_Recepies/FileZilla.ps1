#	FileZilla

# Get Filezilla version
$filezillaVersion = ((Invoke-WebRequest -Uri 'https://filezilla-project.org/download.php?show_all=1').Links | Where innerHtml -like "FileZilla_*_win64-setup.exe").innerText
$filezillaVersion = $filezillaVersion -Replace "FileZilla_", ""
$filezillaVersion = $filezillaVersion -Replace "_win64-setup.exe", ""

$url = "https://downloads.sourceforge.net/project/filezilla/FileZilla_Client/$filezillaVersion/FileZilla_$($filezillaVersion)_win64-setup.exe"

# Check version
	if(!(Test-Path "$dlLocation\file_versions\FileZilla.txt")){
	New-Item "$dlLocation\file_versions\FileZilla.txt" -Type file | Out-Null
	}
	
	$filezillaOldVersion = Get-Content "$dlLocation\file_versions\FileZilla.txt"
	
	if($filezillaVersion -gt $filezillaOldVersion){
		Set-content "$dlLocation\file_versions\FileZilla.txt" -value $filezillaVersion
		$appsToDL++
		SlackWrite "New update - $recepieName $filezillaVersion"
		try {
			Start-BitsTransfer -Source $url -Destination $dlLocation
			Write-Host "$recepieName $filezillaVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $filezillaVersion - Download complete!"
		} catch {
			Write-Host "$recepieName $filezillaVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $filezillaVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}


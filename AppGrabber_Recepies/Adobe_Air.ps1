#	Adobe Air

# Get Air version number
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$urlVer = "https://filehippo.com/download_adobe_air/"
$status = invoke-webrequest $urlVer -DisableKeepAlive -UseBasicParsing -Method head
if($status.StatusCode -eq 200){

	$dataVer = Invoke-WebRequest $urlVer
	$recepieVersion = $dataVer.ParsedHtml.body.getElementsByTagName('h1') | Where {$_.getAttributeNode('class').Value -eq 'title-text'}
	$recepieVersion = $recepieVersion.innerText -replace ("Adobe Air ", "")
	$recepieVersion = $recepieVersion.trim()

	$url = "http://airdownload.adobe.com/air/win/download/latest/AdobeAIRInstaller.exe"

	# Check version
		if(!(Test-Path "$dlLocation\file_versions\Adobe_Air.txt")){
		New-Item "$dlLocation\file_versions\Adobe_Air.txt" -Type file | Out-Null
		}
		
		$recepieVersionOld = Get-Content "$dlLocation\file_versions\Adobe_Air.txt"
		
		if($recepieVersion -gt $recepieVersionOld){
			$appsToDL++
			try {
				Start-BitsTransfer -Source "$url" -Destination $dlLocation
				Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
				LogWrite "$recepieName $recepieVersion - Download complete!"
				Set-content "$dlLocation\file_versions\Adobe_Air.txt" -value $recepieVersion
				$build = 1
			} catch {
				Write-Host "$recepieName $recepieVersion - Download failed!" -ForegroundColor 'red'
				LogWrite "$recepieName $recepieVersion - Download failed!"
			}
		} else {
			Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
			LogWrite "$recepieName - No updates found!"
		}
		
} else {
	Write-Host "$recepieName $recepieVersion - Download failed!" -ForegroundColor 'red'
	LogWrite "$recepieName - URL not working!"
}


# Build package
if($build -eq 1){
$build = 0

Write-Host "$recepieName $recepieVersion - Build started!" -ForegroundColor 'green'
LogWrite "$recepieName $recepieVersion - Build started!"

$date = Get-Date -format "yyyy-MM-dd"
$folderLoc = "$buildLocation\$recepieName $recepieVersion - $date"
New-Item "$folderLoc" -Type Directory | Out-Null

# Copy config for EXE installer to build folder
$config = @"
;!@Install@!UTF-8!
Title="$recepieName"
Progress="no"
RunProgram="AdobeAIRInstaller.exe -silent"
;!@InstallEnd@!
"@
$config | Out-File -encoding ascii "$folderLoc\config.txt"

# Move downloaded file to build folder
Move-Item "$dlLocation\AdobeAIRInstaller.exe" -Destination "$folderLoc\AdobeAIRInstaller.exe"

# Copy required sfx file to build folder
Copy-Item "$templateLocation\7zS.sfx" -Destination "$folderLoc\7zS.sfx"

# Compress raw installer files
if (-not (test-path "$templateLocation\7-Zip\7z.exe")) {throw "$templateLocation\7-Zip\7z.exe needed"}
set-alias sz "$templateLocation\7-Zip\7z.exe"
$zipFile = "temp.7z"
sz a -r "$folderLoc\$zipFile" "$folderLoc\*.*" | Out-Null

# Create EXE installer from compressed archive
$command = @'
cmd.exe /C copy /b "$folderLoc\7zS.sfx" + "$folderLoc\config.txt" + "$folderLoc\$zipFile" "$folderLoc\$($recepieName)_$($recepieVersion).exe"
'@

Invoke-Expression -Command:$command | Out-Null

if(Test-Path "$folderLoc\$($recepieName)_$($recepieVersion).exe"){
	Get-ChildItem -Path  "$folderLoc" -Recurse -exclude "$($recepieName)_$($recepieVersion).exe" | Remove-Item -force -recurse

	Write-Host "$recepieName $recepieVersion - Build complete!" -ForegroundColor 'green'
	LogWrite "$recepieName $recepieVersion - Build complete!"
} else {
	Write-Host "$recepieName $recepieVersion - Build failed!" -ForegroundColor 'red'
	LogWrite "$recepieName $recepieVersion - Build failed!"
}

}
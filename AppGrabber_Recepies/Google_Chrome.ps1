#	Google Chrome

# Get Google Chrome version number
Get-ChocoPackageVersion -ChocoPackageURL "https://chocolatey.org/packages/GoogleChrome"
$recepieVersion = $script:ChocoPackageVersion

if(!(Test-Path "$dlLocation\file_versions\Google_Chrome.txt")){
	New-Item "$dlLocation\file_versions\Google_Chrome.txt" -Type file | Out-Null
}
	$recepieVersionOld = Get-Content "$dlLocation\file_versions\Google_Chrome.txt"
	
if($recepieVersion -gt $recepieVersionOld){
  $appsToDL++
  if($enableSlack){
  SlackWrite "New update found! :package: *$recepieName $recepieVersion*"
  }
	$url = "https://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi"
	try {
		Start-BitsTransfer -Source "$url" -Destination "$dlLocation\GoogleChromeStandaloneEnterprise64.msi" -ErrorAction SilentlyContinue -ErrorVariable dlErr

		Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $recepieVersion - Download complete!"
		Set-content "$dlLocation\file_versions\Google_Chrome.txt" -value $recepieVersion
		$build = 1
	} catch {
		Write-Host "$recepieName $recepieVersion - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $recepieVersion - Download failed!"
		LogWrite "$dlErr"
	}
} else {
	Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
	LogWrite "$recepieName - No updates found!"
}

# Build package
if($build -eq 1){
$build = 0

Write-Host "$recepieName $recepieVersion - Build started!" -ForegroundColor 'green'
LogWrite "$recepieName $recepieVersion - Build started!"

$date = Get-Date -format "yyyy-MM-dd"

# Create build folder with todays date
$folderLoc = "$buildLocation\$recepieName $recepieVersion - $date"
if(!(Test-Path "$folderLoc")){
  New-Item "$folderLoc" -Type Directory | Out-Null
} else {
  Get-ChildItem "$folderLoc" -Recurse | Remove-Item
  Write-Host "$recepieName $recepieVersion - Old content found, removing!" -ForegroundColor 'green'
}

# Create main script file for EXE installer
$installer = @"
@echo off
cd /d "%~dp0"

echo [Installing/Updating Chrome]
msiexec /i "%cd%\GoogleChromeStandaloneEnterprise64.msi" /quiet /norestart
cls
echo [Change permission on shortcut]
IF EXIST "C:\Users\Public\Desktop\Google Chrome.lnk" (
C:\windows\system32\icacls "C:\Users\Public\Desktop\Google Chrome.lnk" /grant "*S-1-1-0":F
)
"@
$installer | Out-File -encoding ascii "$folderLoc\Install_$recepieName.bat"

# Copy config for EXE installer to build folder
$config = @"
;!@Install@!UTF-8!
Title="$recepieName"
Progress="no"
RunProgram="Install_$recepieName.bat"
;!@InstallEnd@!
"@
$config | Out-File -encoding ascii "$folderLoc\config.txt"

# Move downloaded file to build folder
Move-Item "$dlLocation\GoogleChromeStandaloneEnterprise64.msi" -Destination "$folderLoc\GoogleChromeStandaloneEnterprise64.msi"

# Copy required sfx file to build folder
Copy-Item "$templateLocation\7zS.sfx" -Destination "$folderLoc\7zS.sfx"

# 7zip
if (-not (test-path "$templateLocation\7-Zip\7z.exe")) {throw "$templateLocation\7-Zip\7z.exe needed"}
set-alias sz "$templateLocation\7-Zip\7z.exe"
$zipFile = "temp.7z"

# Compress to temp archive
sz a -r "$folderLoc\$zipFile" "$folderLoc\*" | Out-Null

# Create EXE installer from compressed archive
$command = @'
cmd.exe /C copy /b "$folderLoc\7zS.sfx" + "$folderLoc\config.txt" + "$folderLoc\$zipFile" "$folderLoc\$($recepieName)_$($recepieVersion).exe"
'@

Invoke-Expression -Command:$command | Out-Null


# Remove all files

if(Test-Path "$folderLoc\$($recepieName)_$($recepieVersion).exe"){
	Get-ChildItem -Path  "$folderLoc" -Recurse -exclude "$($recepieName)_$($recepieVersion).exe" | Remove-Item -force -recurse

	Write-Host "$recepieName $recepieVersion - Build complete!" -ForegroundColor 'green'
	LogWrite "$recepieName $recepieVersion - Build complete!"
} else {
	Write-Host "$recepieName $recepieVersion - Build failed!" -ForegroundColor 'red'
	LogWrite "$recepieName $recepieVersion - Build failed!"
}

}
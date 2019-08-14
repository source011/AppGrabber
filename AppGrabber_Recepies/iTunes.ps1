#	iTunes

$url = "https://www.apple.com/itunes/download"
$search = "Download now (64-bit)"
$downloadSw = "https://www.apple.com" + ((Invoke-WebRequest -Uri $url).Links | Where-Object innerHTML -like $search).href

# Get Itunes version number
Get-ChocoPackageVersion -ChocoPackageURL "https://chocolatey.org/packages/Itunes"
$recepieVersion = $script:ChocoPackageVersion

if(!(Test-Path "$dlLocation\file_versions\iTunes.txt")){
	New-Item "$dlLocation\file_versions\iTunes.txt" -Type file | Out-Null
}
	
$recepieVersionOld = Get-Content "$dlLocation\file_versions\iTunes.txt"
	
if($recepieVersion -gt $recepieVersionOld){
  $appsToDL++
  if($enableSlack){
	SlackWrite "New update found! :package: *$recepieName $recepieVersion*"
  }
  try {
		Start-BitsTransfer -Source $downloadSw -Destination "$dlLocation\iTunes64Setup.exe"

		Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $recepieVersion - Download complete!"
		Set-content "$dlLocation\file_versions\iTunes.txt" -value $recepieVersion
		$build = 1
	} catch {
		Write-Host "$recepieName $recepieVersion - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $recepieVersion - Download failed!"
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


# Copy required files from template
if(!(Test-Path "$templateLocation\$recepieName")){
	New-Item "$templateLocation\$recepieName" -Type Directory | Out-Null
}
Copy-Item "$templateLocation\$recepieName\*" -Destination "$folderLoc\" -Recurse

# Create main script file for EXE installer
$installer = @"
@echo off
cd /d "%~dp0"

echo [Uninstall iTunes before installing the new one]
wmic product where "name like 'iTunes%%'" call uninstall /nointeractive
cls
echo [Uninstall iTunes before installing the new one]
wmic product where "name like 'Apple Mobile Device Support%%'" call uninstall /nointeractive
cls
echo [Uninstall iTunes before installing the new one]
wmic product where "name like 'Apple-program%%'" call uninstall /nointeractive
cls
echo [Uninstall iTunes before installing the new one]
wmic product where "name like 'Bonjour%%'" call uninstall /nointeractive
cls
echo [Install Apple Application Support]
msiexec /i "%cd%\AppleApplicationSupport.msi" /t "%cd%\AppleApplicationSupport.mst" /quiet /norestart
cls
echo [Install Apple Application Support x64]
msiexec /i "%cd%\AppleApplicationSupport64.msi" /t "%cd%\AppleApplicationSupport64.mst" /quiet /norestart
cls 
echo [Install Apple mobile device support]
msiexec /i "%cd%\AppleMobileDeviceSupport6464.msi" /t "%cd%\AppleMobileDeviceSupport6464.mst" /quiet /norestart
cls
echo [Check if Application Support is installed]
IF NOT EXIST "C:\Program Files\Common Files\Apple\Apple Application Support\" (goto Reinstall) else goto iTunes

:Reinstall
echo [Reinstall Application Support 32-bit]
msiexec /i "%cd%\AppleApplicationSupport.msi" /t "%cd%\AppleApplicationSupport.mst" /quiet /norestart
cls
echo [Reinstall Application Support 64-bit]
msiexec /i "%cd%\AppleApplicationSupport64.msi" /t "%cd%\AppleApplicationSupport64.mst" /quiet /norestart
goto iTunes

:iTunes
cls
echo [Install iTunes]
msiexec /i "%cd%\iTunes64.msi" /t "%cd%\iTunes64.mst" /quiet /norestart
TIMEOUT /T 3
cls
echo [Change permission on shortcut]
Set scut="C:\Users\Public\Desktop"
C:\windows\system32\icacls "%scut%\iTunes*.lnk" /grant "*S-1-1-0":F
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
Move-Item "$dlLocation\iTunes64Setup.exe" -Destination "$folderLoc\iTunes64Setup.exe"

# Copy required sfx file to build folder
Copy-Item "$templateLocation\7zS.sfx" -Destination "$folderLoc\7zS.sfx"

# 7zip
if (-not (test-path "$templateLocation\7-Zip\7z.exe")) {throw "$templateLocation\7-Zip\7z.exe needed"}
set-alias sz "$templateLocation\7-Zip\7z.exe"
$zipFile = "temp.7z"

# Extract OpenOffice installer
sz x "$folderLoc\iTunes64Setup.exe" -o"$folderLoc\" | Out-Null

# Delete original installer files
Remove-Item "$folderLoc\AppleSoftwareUpdate.msi" -force
Remove-Item "$folderLoc\SetupAdmin.exe" -force
Remove-Item "$folderLoc\iTunes64Setup.exe" -force

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
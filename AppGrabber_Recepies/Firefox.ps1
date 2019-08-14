#	Firefox

# Get Firefox version number
Get-ChocoPackageVersion -ChocoPackageURL "https://chocolatey.org/packages/firefox"
$recepieVersion = $script:ChocoPackageVersion

# Download Firefox
$url = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win&lang=sv-SE"

# Check version
	if(!(Test-Path "$dlLocation\file_versions\Firefox.txt")){
	New-Item "$dlLocation\file_versions\Firefox.txt" -Type file | Out-Null
	}
	
	$recepieVersionOld = Get-Content "$dlLocation\file_versions\Firefox.txt"
	
	if($recepieVersion -gt $recepieVersionOld){
    $appsToDL++
    if($enableSlack){
		SlackWrite "New update found! :package: *$recepieName $recepieVersion*"
    }
    try {
      Start-BitsTransfer -Source "$url" -Destination "$dlLocation\Firefox Setup $($recepieVersion).msi" -ErrorAction SilentlyContinue -ErrorVariable dlErr
			Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $recepieVersion - Download complete!"
			Set-content "$dlLocation\file_versions\Firefox.txt" -value $recepieVersion
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
IF EXIST "C:\Users\Public\Desktop\Mozilla Firefox.lnk" (
echo Deleting old shortcut...
del /f "C:\Users\Public\Desktop\Mozilla Firefox.lnk"
)
echo [Installing/Updating Firefox]
msiexec /i "%cd%\Firefox-$($recepieVersion)-sv-SE.msi" /quiet /norestart
cls
echo [Change permission on shortcut]
Set scut="C:\Users\Public\Desktop"
C:\windows\system32\icacls "%scut%\Mozilla Firefox.lnk" /grant "*S-1-1-0":F
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

# Rename installer and move to build folder
Rename-Item -Path "$dlLocation\Firefox Setup $($recepieVersion).msi" -NewName "Firefox-$($recepieVersion)-sv-SE.msi"
Move-Item "$dlLocation\Firefox-$($recepieVersion)-sv-SE.msi" -Destination "$folderLoc\Firefox-$($recepieVersion)-sv-SE.msi"

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
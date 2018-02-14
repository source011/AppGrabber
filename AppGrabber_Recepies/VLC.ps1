#	VLC

$url = "https://www.videolan.org/vlc/download-windows.html"
$search = "Installer for 64bit version"
$downloadSw = ((Invoke-WebRequest -Uri $url).Links | Where innerHTML -like $search).href
$recepieVersion = ($downloadSw -split '/')[4]
$downloadSw = $downloadSw -Replace '//','http://'

# Check version
	if(!(Test-Path "$dlLocation\file_versions\VLC.txt")){
	New-Item "$dlLocation\file_versions\VLC.txt" -Type file | Out-Null
	}
	
	$recepieVersionOld = Get-Content "$dlLocation\file_versions\VLC.txt"
	
	if($recepieVersion -gt $recepieVersionOld){
		$appsToDL++
		try {
			# Download
			Start-BitsTransfer -Source $downloadSw -Destination $dlLocation
			Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $recepieVersion - Download complete!"
			Set-content "$dlLocation\file_versions\VLC.txt" -value $recepieVersion
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
$folderLoc = "$buildLocation\$recepieName $recepieVersion - $date"
New-Item "$folderLoc" -Type Directory | Out-Null

# Create main script file for EXE installer
$installer = @"
@echo off
cd /d "%~dp0"
echo [Installing/Updating VLC]
"%cd%\vlc-$recepieVersion-win64.exe" /S
echo [Delete shortcut]
Set scut="C:\Users\Public\Desktop"
del /s /q /f "%scut%\VLC media player.lnk"
"@
$installer | Out-File -encoding ascii "$folderLoc\Install_VLC.bat"

# Copy config for EXE installer to build folder
$config = @"
;!@Install@!UTF-8!
Title="VLC"
Progress="no"
RunProgram="Install_VLC.bat"
;!@InstallEnd@!
"@
$config | Out-File -encoding ascii "$folderLoc\config.txt"

# Move downloaded file to build folder
Move-Item "$dlLocation\vlc-$recepieVersion-win64.exe" -Destination "$folderLoc\vlc-$recepieVersion-win64.exe"

# Copy required sfx file to build folder
Copy-Item "$templateLocation\7zS.sfx" -Destination "$folderLoc\7zS.sfx"

# Compress raw installer files
if (-not (test-path "$templateLocation\7-Zip\7z.exe")) {throw "$templateLocation\7-Zip\7z.exe needed"}
set-alias sz "$templateLocation\7-Zip\7z.exe"
$zipFile = "temp.7z"
sz a -r "$folderLoc\$zipFile" "$folderLoc\*.*" | Out-Null

$exeName = $recepieName + "_" + $recepieVersion

# Create EXE installer from compressed archive
$command = @'
cmd.exe /C copy /b "$folderLoc\7zS.sfx" + "$folderLoc\config.txt" + "$folderLoc\$zipFile" "$folderLoc\$exeName.exe"
'@

Invoke-Expression -Command:$command | Out-Null

if(Test-Path "$folderLoc\$exeName.exe"){
	Get-ChildItem -Path  "$folderLoc" -Recurse -exclude "$exeName.exe" | Remove-Item -force -recurse

	Write-Host "$recepieName $recepieVersion - Build complete!" -ForegroundColor 'green'
	LogWrite "$recepieName $recepieVersion - Build complete!"
} else {
	Write-Host "$recepieName $recepieVersion - Build failed!" -ForegroundColor 'red'
	LogWrite "$recepieName $recepieVersion - Build failed!"
}

}
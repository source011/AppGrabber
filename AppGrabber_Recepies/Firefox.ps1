#	Firefox

# Get Firefox latest version (THIS IS UGLY)
$url ='http://www.frontmotion.com/firefox/download/'
$response = Invoke-WebRequest -Uri $url
$recepieVersion = $response.ParsedHtml.body.getElementsByClassName('so-panel widget widget_black-studio-tinymce widget_black_studio_tinymce panel-first-child panel-last-child')[1] | select -expand outerText
$recepieVersion = $recepieVersion -split "`n"
$recepieVersion = ($recepieVersion -split "`r?`n")[1]
$recepieVersion = $recepieVersion -replace "Firefox-",""
$recepieVersion = $recepieVersion -replace "`r|`n",""

# Download Firefox
$url = "http://hicap.frontmotion.com.s3.amazonaws.com/Firefox/Firefox-$($recepieVersion)/Firefox-$($recepieVersion)-sv-SE.msi"

# Check version
	if(!(Test-Path "$dlLocation\file_versions\Firefox.txt")){
	New-Item "$dlLocation\file_versions\Firefox.txt" -Type file | Out-Null
	}
	
	$recepieVersionOld = Get-Content "$dlLocation\file_versions\Firefox.txt"
	
	if($recepieVersion -gt $recepieVersionOld){
		$appsToDL++
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $recepieVersion - Download complete!"
			Set-content "$dlLocation\file_versions\Firefox.txt" -value $recepieVersion
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
New-Item "$folderLoc" -Type Directory | Out-Null

# Copy required files from template
if(!(Test-Path "$templateLocation\$recepieName")){
	New-Item "$templateLocation\$recepieName" -Type Directory | Out-Null
}
Copy-Item "$templateLocation\$recepieName\*" -Destination "$folderLoc\" -Recurse

# Create main script file for EXE installer
$installer = @"
@echo off
cd /d "%~dp0"

echo [Installing/Updating Firefox]
msiexec /i "%cd%\Firefox-$($recepieVersion)-sv-SE.msi" /quiet /norestart
cls
echo [Installing SSO for Firefox]
echo Kolla om mozilla.cfg finns...
IF EXIST "C:\Program Files (x86)\Mozilla Firefox\mozilla.cfg" (
echo Raderar mozilla.cfg...
del /f "C:\Program Files (x86)\Mozilla Firefox\mozilla.cfg"
)

echo Kopierar mozilla.cfg...
xcopy "%cd%\files\mozilla.cfg" "C:\Program Files (x86)\Mozilla Firefox" /Y
cls
echo [Add Firewall exception]
cscript //NoLogo //B "%cd%\Firefox_FWexception.vbs"
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

# Move downloaded file to build folder
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

if(Test-Path "$folderLoc\$($recepieName)_$($recepieVersion).exe"){
	Get-ChildItem -Path  "$folderLoc" -Recurse -exclude "$($recepieName)_$($recepieVersion).exe" | Remove-Item -force -recurse

	Write-Host "$recepieName $recepieVersion - Build complete!" -ForegroundColor 'green'
	LogWrite "$recepieName $recepieVersion - Build complete!"
} else {
	Write-Host "$recepieName $recepieVersion - Build failed!" -ForegroundColor 'red'
	LogWrite "$recepieName $recepieVersion - Build failed!"
}

}
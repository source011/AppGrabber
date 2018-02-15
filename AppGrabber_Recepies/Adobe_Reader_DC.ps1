#	Adobe Reader DC

# Get Reader DC version number
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$urlVer = "https://filehippo.com/download_adobe-acrobat-reader-dc/"
$dataVer = Invoke-WebRequest $urlVer
$recepieVersion = $dataVer.ParsedHtml.body.getElementsByTagName('h1') | Where {$_.getAttributeNode('class').Value -eq 'title-text'}
$recepieVersion = $recepieVersion.innerText -replace ("Adobe Acrobat Reader DC ", "")
$recepieVersion = $recepieVersion.trim()
$adobeReaderUrlVersion = $recepieVersion.Substring(2) -replace '\.', ''

$url = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/$($adobeReaderUrlVersion)/AcroRdrDC$($adobeReaderUrlVersion)_en_US.exe"

# Check version
if(!(Test-Path "$dlLocation\file_versions\Adobe_Reader_DC.txt")){
	New-Item "$dlLocation\file_versions\Adobe_Reader_DC.txt" -Type file | Out-Null
}
	
	$recepieVersionOld = Get-Content "$dlLocation\file_versions\Adobe_Reader_DC.txt"
	
	if($recepieVersion -gt $recepieVersionOld){
		$appsToDL++
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			
			Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $recepieVersion - Download complete!"
			Set-content "$dlLocation\file_versions\Adobe_Reader_DC.txt" -value $recepieVersion
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

echo [Uninstall any version of Adobe Reader before installing the new one]
wmic product where "name like 'Adobe Reader%%'" call uninstall /nointeractive
cls

echo [Uninstall any version of Acrobat Reader before installing the new one]
wmic product where name="Adobe Acrobat Reader DC" call uninstall /nointeractive
cls

echo [Install Adobe Reader]
msiexec /i "%cd%\AcroRead.msi" DISABLE_ARM_SERVICE_INSTALL="1" /quiet
cls

echo [Check if Adobe Reader is installed]
IF NOT EXIST "C:\Program Files (x86)\Adobe\Acrobat Reader DC" (goto Reinstall) else goto dS

:Reinstall
cls
echo [Reinstall Adobe Reader]
msiexec /i "%cd%\AcroRead.msi" DISABLE_ARM_SERVICE_INSTALL="1" /quiet 
goto dS

:dS
cls
echo [Delete shortcut]
Set scut="C:\Users\Public\Desktop"
del /s /q /f "%scut%\Acrobat Reader*.lnk"
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
Move-Item "$dlLocation\AcroRdrDC$($adobeReaderUrlVersion)_en_US.exe" -Destination "$folderLoc\AcroRdrDC$($adobeReaderUrlVersion)_en_US.exe"

# Copy required sfx file to build folder
Copy-Item "$templateLocation\7zS.sfx" -Destination "$folderLoc\7zS.sfx"

# 7zip
if (-not (test-path "$templateLocation\7-Zip\7z.exe")) {throw "$templateLocation\7-Zip\7z.exe needed"}
set-alias sz "$templateLocation\7-Zip\7z.exe"
$zipFile = "temp.7z"

# Extract OpenOffice installer
sz x "$folderLoc\AcroRdrDC$($adobeReaderUrlVersion)_en_US.exe" -o"$folderLoc\" | Out-Null

# Delete original installer files
Remove-Item "$folderLoc\AcroRdrDC$($adobeReaderUrlVersion)_en_US.exe" -force

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
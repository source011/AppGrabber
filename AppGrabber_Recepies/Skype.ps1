#	Skype

# Get Skype version number
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$urlVer = "https://filehippo.com/download_skype/"
$dataVer = Invoke-WebRequest $urlVer
$skypeVersion = $dataVer.ParsedHtml.body.getElementsByTagName('h1') | Where {$_.getAttributeNode('class').Value -eq 'title-text'}
$skypeVersion = $skypeVersion.innerText -replace ("Skype ", "")
$skypeVersion = $skypeVersion.trim()

$url = "http://download.skype.com/msi/SkypeSetup_$skypeVersion.msi"

# Check version
	if(!(Test-Path "$dlLocation\file_versions\Skype.txt")){
	New-Item "$dlLocation\file_versions\Skype.txt" -Type file | Out-Null
	}
	
	$skypeOldVersion = Get-Content "$dlLocation\file_versions\Skype.txt"
	
	if($skypeVersion -gt $skypeOldVersion){
		$appsToDL++
		SlackWrite "New update - $recepieName $skypeVersion"
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			Write-Host "$recepieName $skypeVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $skypeVersion - Download complete!"
			Set-content "$dlLocation\file_versions\Skype.txt" -value $skypeVersion			
			$build = 1
		} catch {
			Write-Host "$recepieName $skypeVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $skypeVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}
	
# Build package
if($build -eq 1){
$build = 0

Write-Host "$recepieName $skypeVersion - Build started!" -ForegroundColor 'green'
LogWrite "$recepieName $skypeVersion - Build started!"

$date = Get-Date -format "yyyy-MM-dd"
$folderLoc = "$buildLocation\$recepieName $skypeVersion - $date"
New-Item "$folderLoc" -Type Directory | Out-Null

# Create main script file for EXE installer
$installer = @"
@echo off

wmic product where "name like 'Skype%%'" call uninstall /nointeractive

cd /d "%~dp0"
msiexec /i "%cd%\SkypeSetup_$skypeVersion.msi" /quiet /norestart

echo [Delete shortcut]
Set scut="C:\Users\Public\Desktop"
del /s /q /f "%scut%\Skype*.lnk"
"@
$installer | Out-File -encoding ascii "$folderLoc\Install_$recepieName.bat"

# Copy config for EXE installer to build folder
$config = @"
;!@Install@!UTF-8!
Title="Skype"
Progress="no"
RunProgram="Install_$recepieName.bat"
;!@InstallEnd@!
"@
$config | Out-File -encoding ascii "$folderLoc\config.txt"

# Move downloaded file to build folder
Move-Item "$dlLocation\SkypeSetup_$skypeVersion.msi" -Destination "$folderLoc\SkypeSetup_$skypeVersion.msi"

# Copy required sfx file to build folder
Copy-Item "$templateLocation\7zS.sfx" -Destination "$folderLoc\7zS.sfx"

# Compress raw installer files
if (-not (test-path "$templateLocation\7-Zip\7z.exe")) {throw "$templateLocation\7-Zip\7z.exe needed"}
set-alias sz "$templateLocation\7-Zip\7z.exe"
$zipFile = "temp.7z"
sz a -r "$folderLoc\$zipFile" "$folderLoc\*.*" | Out-Null

$exeName = $recepieName + "_" + $skypeVersion

# Create EXE installer from compressed archive
$command = @'
cmd.exe /C copy /b "$folderLoc\7zS.sfx" + "$folderLoc\config.txt" + "$folderLoc\$zipFile" "$folderLoc\$exeName.exe"
'@

Invoke-Expression -Command:$command | Out-Null

if(Test-Path "$folderLoc\$exeName.exe"){
	Get-ChildItem -Path  "$folderLoc" -Recurse -exclude "$exeName.exe" | Remove-Item -force -recurse

	Write-Host "$recepieName $skypeVersion - Build complete!" -ForegroundColor 'green'
	LogWrite "$recepieName $skypeVersion - Build complete!"
} else {
	Write-Host "$recepieName $skypeVersion - Build failed!" -ForegroundColor 'red'
	LogWrite "$recepieName $skypeVersion - Build failed!"
}

}
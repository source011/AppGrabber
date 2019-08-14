#	OpenOffice

# Get Open Office version number
Get-ChocoPackageVersion -ChocoPackageURL "https://chocolatey.org/packages/OpenOffice"
$recepieVersion = $script:ChocoPackageVersion

# Check version
if(!(Test-Path "$dlLocation\file_versions\OpenOffice.txt")){
	New-Item "$dlLocation\file_versions\OpenOffice.txt" -Type file | Out-Null
}

$recepieVersionOld = Get-Content "$dlLocation\file_versions\OpenOffice.txt"

if($recepieVersion -gt $recepieVersionOld){
	$appsToDL++
  if($enableSlack){
  SlackWrite "New update found! :package: *$recepieName $recepieVersion*"
  }

  # Get full installer (Swedish)
	$url = "https://sourceforge.net/projects/openofficeorg.mirror/files/$recepieVersion/binaries/sv/Apache_OpenOffice_$($recepieVersion)_Win_x86_install_sv.exe/download"
  #  $WebClientObject = New-Object System.Net.WebClient
  #  $WebRequest = [System.Net.WebRequest]::create($URL)
  #  $WebResponse = $WebRequest.GetResponse()
  #  $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
  #  $ObjectProperties = @{ 'Shortened URL' = $URL;
  #                         'Actual URL' = $ActualDownloadURL}
  #  $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
  #  $WebResponse.Close()
	#  $url = $ResultsObject.'Actual URL'
	try {
		Start-BitsTransfer -Source $url -Destination "$dlLocation\Apache_OpenOffice_$($recepieVersion)_Win_x86_install_sv.exe" -ErrorAction SilentlyContinue -ErrorVariable dlErr
       # $msbuild = "$dlLocation\wget\wget.exe"
       # $argumentz = "$url -P $dlLocation --no-check-certificate"
       # start-process -WindowStyle hidden $msbuild $argumentz -wait
		Write-Host "$recepieName $recepieVersion Installer - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $recepieVersion Installer - Download complete!"
		Set-content "$dlLocation\file_versions\OpenOffice.txt" -value $recepieVersion
		$build = 1
	} catch {
		Write-Host "$recepieName $recepieVersion Installer - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $recepieVersion Installer - Download failed!"
	}
	
	# Get English language pack
	$url = "https://sourceforge.net/projects/openofficeorg.mirror/files/$recepieVersion/binaries/en-GB/Apache_OpenOffice_$($recepieVersion)_Win_x86_langpack_en-GB.exe/download"
  #  $WebClientObject = New-Object System.Net.WebClient
  #  $WebRequest = [System.Net.WebRequest]::create($URL)
  #  $WebResponse = $WebRequest.GetResponse()
  #  $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
  #  $ObjectProperties = @{ 'Shortened URL' = $URL;
  #                         'Actual URL' = $ActualDownloadURL}
  #  $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
  #  $WebResponse.Close()
	#$url = $ResultsObject.'Actual URL'
	try {
		Start-BitsTransfer -Source $url -Destination "$dlLocation\Apache_OpenOffice_$($recepieVersion)_Win_x86_langpack_en-GB.exe" -ErrorAction SilentlyContinue -ErrorVariable dlErr
    #    $msbuild = "$dlLocation\wget\wget.exe"
    #    $argumentz = "$url -P $dlLocation --no-check-certificate"
    #    start-process -WindowStyle hidden $msbuild $argumentz -wait
		Write-Host "$recepieName $recepieVersion Language pack - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $recepieVersion Language pack - Download complete!"
	} catch {
		Write-Host "$recepieName $recepieVersion Language pack - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $recepieVersion Language pack - Download failed!"
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

$tempVersion = $recepieVersion -replace "\.", ""

# Create main script file for EXE installer
$installer = @"
@echo off
cd /d "%~dp0"
echo [Install OpenOffice]
"%cd%\setup.exe" SELECT_WORD=0 SELECT_EXCEL=0 SELECT_POWERPOINT=0 /qn /norestart
cls
echo [Install Language-pack]
msiexec /i "%cd%\en\openoffice$($tempVersion).msi" /qn /norestart
cls
echo [Delete shortcut]
Set scut="C:\Users\Public\Desktop"
del /s /q /f "%scut%\OpenOffice*.lnk"
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
Move-Item "$dlLocation\Apache_OpenOffice_$($recepieVersion)_Win_x86_install_sv.exe" -Destination "$folderLoc\Apache_OpenOffice_$($recepieVersion)_Win_x86_install_sv.exe"
Move-Item "$dlLocation\Apache_OpenOffice_$($recepieVersion)_Win_x86_langpack_en-GB.exe" -Destination "$folderLoc\Apache_OpenOffice_$($recepieVersion)_Win_x86_langpack_en-GB.exe"

# Copy required sfx file to build folder
Copy-Item "$templateLocation\7zS.sfx" -Destination "$folderLoc\7zS.sfx"

# 7zip
if (-not (test-path "$templateLocation\7-Zip\7z.exe")) {throw "$templateLocation\7-Zip\7z.exe needed"}
set-alias sz "$templateLocation\7-Zip\7z.exe"
$zipFile = "temp.7z"

# Extract OpenOffice installer
sz x "$folderLoc\Apache_OpenOffice_$($recepieVersion)_Win_x86_install_sv.exe" -o"$folderLoc\" | Out-Null
sz x "$folderLoc\Apache_OpenOffice_$($recepieVersion)_Win_x86_langpack_en-GB.exe" -o"$folderLoc\en" | Out-Null

# Delete original installer files
Remove-Item "$folderLoc\Apache_OpenOffice_$($recepieVersion)_Win_x86_install_sv.exe" -force
Remove-Item "$folderLoc\Apache_OpenOffice_$($recepieVersion)_Win_x86_langpack_en-GB.exe" -force

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
#	Adobe Air

# Get Adobe Air version number
Get-ChocoPackageVersion -ChocoPackageURL "https://chocolatey.org/packages/AdobeAIR"
$recepieVersion = $script:ChocoPackageVersion

$url = "http://airdownload.adobe.com/air/win/download/latest/AdobeAIRInstaller.exe"

# Check version
if(!(Test-Path "$dlLocation\file_versions\Adobe_Air.txt")){
  New-Item "$dlLocation\file_versions\Adobe_Air.txt" -Type file | Out-Null
}

$recepieVersionOld = Get-Content "$dlLocation\file_versions\Adobe_Air.txt"

if($recepieVersion -gt $recepieVersionOld){
  $appsToDL++
  if($enableSlack){
    SlackWrite "New update found! :package: *$recepieName $recepieVersion*"
  }
  try {
    Start-BitsTransfer -Source "$url" -Destination "$dlLocation\AdobeAIRInstaller.exe"
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
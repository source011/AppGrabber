#	Silverlight


# Get latest version number
$html = invoke-webrequest "https://en.wikipedia.org/wiki/Microsoft_Silverlight_version_history"
$table = $html.parsedHtml.getElementsByTagName("table")[0]
$TR = $table.getElementsByTagName("tr") | where { $_.innerText -like "*.*.*.*" } | Select-Object -Last 1
$recepieVersion = $TR.getElementsByTagName("td")[1].innerText



$url = "http://bit.ly/1K5WrPA" # Bitly goes to -> http://go.microsoft.com/fwlink/?LinkID=229321
    $WebClientObject = New-Object System.Net.WebClient
    $WebRequest = [System.Net.WebRequest]::create($URL)
    $WebResponse = $WebRequest.GetResponse()
    $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
    $ObjectProperties = @{ 'Shortened URL' = $URL;
                           'Actual URL' = $ActualDownloadURL}
    $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
    $WebResponse.Close()
$url = $ResultsObject.'Actual URL'

# Check version
	if(!(Test-Path "$dlLocation\file_versions\Silverlight.txt")){
	New-Item "$dlLocation\file_versions\Silverlight.txt" -Type file | Out-Null
	}
	
	$recepieVersionOld = Get-Content "$dlLocation\file_versions\Silverlight.txt"
	
	if($recepieVersion -gt $recepieVersionOld){
		$appsToDL++
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			Write-Host "$recepieName $recepieVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $recepieVersion - Download complete!"
			Set-content "$dlLocation\file_versions\Silverlight.txt" -value $recepieVersion
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

# Copy config for EXE installer to build folder
$config = @"
;!@Install@!UTF-8!
Title="Silverlight"
Progress="no"
RunProgram="Silverlight_x64.exe /q"
;!@InstallEnd@!
"@
$config | Out-File -encoding ascii "$folderLoc\config.txt"

# Move downloaded file to build folder
Move-Item "$dlLocation\Silverlight_x64.exe" -Destination "$folderLoc\Silverlight_x64.exe"

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
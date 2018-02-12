#	OpenOffice

# Get version
$ooVersion = ((Invoke-WebRequest -Uri 'http://www.openoffice.org/download/').Links | Where innerText -like "Apache OpenOffice*").innerText
$ooVersion = $ooVersion.Substring(18)
$ooVersion = $ooVersion -replace(" released", "")


# Check version
if(!(Test-Path "$dlLocation\file_versions\OpenOffice.txt")){
	New-Item "$dlLocation\file_versions\OpenOffice.txt" -Type file | Out-Null
}

$OpenOfficeOldVersion = Get-Content "$dlLocation\file_versions\OpenOffice.txt"

if($ooVersion -gt $OpenOfficeOldVersion){
	Set-content "$dlLocation\file_versions\OpenOffice.txt" -value $ooVersion
	$appsToDL++
	SlackWrite "New update - $recepieName $ooVersion"
	
	# Get full installer (Swedish)
	$url = "https://sourceforge.net/projects/openofficeorg.mirror/files/$ooVersion/binaries/sv/Apache_OpenOffice_$($ooVersion)_Win_x86_install_sv.exe/download"
    $WebClientObject = New-Object System.Net.WebClient
    $WebRequest = [System.Net.WebRequest]::create($URL)
    $WebResponse = $WebRequest.GetResponse()
    $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
    $ObjectProperties = @{ 'Shortened URL' = $URL;
                           'Actual URL' = $ActualDownloadURL}
    $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
    $WebResponse.Close()
	$url = $ResultsObject.'Actual URL'
	try {
		Start-BitsTransfer -Source $url -Destination $dlLocation
		Write-Host "$recepieName $ooVersion Installer - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $ooVersion Installer - Download complete!"
	} catch {
		Write-Host "$recepieName $ooVersion Installer - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $ooVersion Installer - Download failed!"
	}
	
	# Get English language pack
	$url = "https://sourceforge.net/projects/openofficeorg.mirror/files/$ooVersion/binaries/en-GB/Apache_OpenOffice_$($ooVersion)_Win_x86_langpack_en-GB.exe/download"
    $WebClientObject = New-Object System.Net.WebClient
    $WebRequest = [System.Net.WebRequest]::create($URL)
    $WebResponse = $WebRequest.GetResponse()
    $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
    $ObjectProperties = @{ 'Shortened URL' = $URL;
                           'Actual URL' = $ActualDownloadURL}
    $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
    $WebResponse.Close()
	$url = $ResultsObject.'Actual URL'
	try {
		Start-BitsTransfer -Source $url -Destination $dlLocation
		Write-Host "$recepieName $ooVersion Language pack - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $ooVersion Language pack - Download complete!"
	} catch {
		Write-Host "$recepieName $ooVersion Language pack - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $ooVersion Language pack - Download failed!"
	}
} else {
	Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
	LogWrite "$recepieName - No updates found!"
}
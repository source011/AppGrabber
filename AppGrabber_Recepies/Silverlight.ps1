#	Silverlight


# Get latest version number
$html = invoke-webrequest "https://en.wikipedia.org/wiki/Microsoft_Silverlight_version_history"
$table = $html.parsedHtml.getElementsByTagName("table")[0]
$TR = $table.getElementsByTagName("tr") | where { $_.innerText -like "*.*.*.*" } | Select-Object -Last 1
$silverlightVersion = $TR.getElementsByTagName("td")[1].innerText



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
	
	$silverlightOldVersion = Get-Content "$dlLocation\file_versions\Silverlight.txt"
	
	if($silverlightVersion -gt $silverlightOldVersion){
		Set-content "$dlLocation\file_versions\Silverlight.txt" -value $silverlightVersion
		$appsToDL++
		SlackWrite "New update - $recepieName $silverlightVersion"
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			Write-Host "$recepieName $silverlightVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $silverlightVersion - Download complete!"
		} catch {
			Write-Host "$recepieName $silverlightVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $silverlightVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}
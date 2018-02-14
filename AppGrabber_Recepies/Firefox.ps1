#	Firefox

# Get Firefox latest version (THIS IS UGLY)
$url ='http://www.frontmotion.com/firefox/download/'
$response = Invoke-WebRequest -Uri $url
$firefoxVersion = $response.ParsedHtml.body.getElementsByClassName('so-panel widget widget_black-studio-tinymce widget_black_studio_tinymce panel-first-child panel-last-child')[1] | select -expand outerText
$firefoxVersion = $firefoxVersion -split "`n"
$firefoxVersion = ($firefoxVersion -split "`r?`n")[1]
$firefoxVersion = $firefoxVersion -replace "Firefox-",""
$firefoxVersion = $firefoxVersion -replace "`r|`n",""

# Download Firefox
$url = "http://hicap.frontmotion.com.s3.amazonaws.com/Firefox/Firefox-$($firefoxVersion)/Firefox-$($firefoxVersion)-sv-SE.msi"

# Check version
	if(!(Test-Path "$dlLocation\file_versions\Firefox.txt")){
	New-Item "$dlLocation\file_versions\Firefox.txt" -Type file | Out-Null
	}
	
	$firefoxOldVersion = Get-Content "$dlLocation\file_versions\Firefox.txt"
	
	if($firefoxVersion -gt $firefoxOldVersion){
		Set-content "$dlLocation\file_versions\Firefox.txt" -value $firefoxVersion
		$appsToDL++
		SlackWrite "New update - $recepieName $firefoxVersion"
		try {
			Start-BitsTransfer -Source "$url" -Destination $dlLocation
			Write-Host "$recepieName $firefoxVersion - Download complete!" -ForegroundColor 'green'
			LogWrite "$recepieName $firefoxVersion - Download complete!"
		} catch {
			Write-Host "$recepieName $firefoxVersion - Download failed!" -ForegroundColor 'red'
			LogWrite "$recepieName $firefoxVersion - Download failed!"
		}
	} else {
		Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
		LogWrite "$recepieName - No updates found!"
	}
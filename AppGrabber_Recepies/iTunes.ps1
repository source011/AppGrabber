#	iTunes

$url = "https://www.apple.com/itunes/download/"
$search = "Download now (64-bit)"
$downloadSw = ((Invoke-WebRequest -Uri $url).Links | Where innerHTML -like $search).href

# Check version
$urlVer = "http://itunes.sv.downloadastro.com"
$dataVer = Invoke-WebRequest $urlVer
$parseVer = $dataVer.ParsedHtml.getElementById("item_name").innerHTML
$regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
$iTunesVersion = $regex.Matches($parseVer) | %{ $_.value }

if(!(Test-Path "$dlLocation\file_versions\iTunes.txt")){
	New-Item "$dlLocation\file_versions\iTunes.txt" -Type file | Out-Null
}
	
$iTunesOldVersion = Get-Content "$dlLocation\file_versions\iTunes.txt"
	
if($iTunesVersion -gt $iTunesOldVersion){
	Set-content "$dlLocation\file_versions\iTunes.txt" -value $iTunesVersion
	$appsToDL++
	SlackWrite "New update - $recepieName $iTunesVersion"
	try {
		Start-BitsTransfer -Source $downloadSw -Destination $dlLocation
		Write-Host "$recepieName $iTunesVersion - Download complete!" -ForegroundColor 'green'
		LogWrite "$recepieName $iTunesVersion - Download complete!"
	} catch {
		Write-Host "$recepieName $iTunesVersion - Download failed!" -ForegroundColor 'red'
		LogWrite "$recepieName $iTunesVersion - Download failed!"
	}
} else {
	Write-Host "$recepieName - No updates found!" -ForegroundColor 'yellow'
	LogWrite "$recepieName - No updates found!"
}
################################# SLACK INTEGRATION #############################################
$enableSlack = $false # $true/$false

if($enableSlack){
Function SlackWrite {
    Param ([string]$slackstring)

$payload = @{
	"channel" = "#SLACK-CHANNEL"
	"text" = "$slackstring"
}

Invoke-WebRequest `
	-Body (ConvertTo-Json -Compress -InputObject $payload) `
	-Method Post `
	-Uri "https://CHANGEMEPLEASE.CHANGE" | Out-Null
}
}
################################# AppGrabber Settings ###########################################

# Download location
$dlLocation = "$PSSCRIPTROOT\AppGrabber_Downloads"

if(!(Test-Path $dlLocation)){
	New-Item $dlLocation -Type Directory | Out-Null
}

# Recepies location
$recepieLocation = "$PSSCRIPTROOT\AppGrabber_Recepies"
$recepies = Get-ChildItem "$recepieLocation\*.ps1"
$totalRecepies = Get-Childitem $recepieLocation | Where-Object {$_.extension -in ".ps1"}  | Group-Object Extension -NoElement | Sort-Object count -desc | Select-Object -ExpandProperty count

# File versions location
$fvLocation = "$PSSCRIPTROOT\AppGrabber_Downloads\file_versions"

if(!(Test-Path $fvLocation)){
	New-Item $fvLocation -Type Directory | Out-Null
}

# Log vars
$logPath = "$PSScriptRoot\AppGrabber_Log" # Log file folder in same location as the script
$logFileName = "AppGrabber.log" # Log filename
$logFile = "$logPath\$logFileName" # Combine LPath and LFile to make one full path

# Create log file and folder if missing
if(!(Test-Path $logPath)){
	New-Item $logPath -Type Directory | Out-Null
}
if(!(Test-Path $logFile)){
	New-Item $logFile -Type file | Out-Null
}

Function LogWrite {
    Param ([string]$logstring)
    $logTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    $logText = $logTime + " - " + $logstring
    Add-content $logFile -value $logText
}

# Function for gathering version numbers
function Get-ChocoPackageVersion {
	# Gets the version of the Chocolatey package.
	[cmdletbinding()]
	param(
		[Parameter(Position=0)]
		# Example: https://chocolatey.org/packages/GoogleChrome
		[String]$ChocoPackageURL
	)
	$script:ChocoPackageVersion = ((Invoke-RestMethod -Uri "https://chocolatey.org/packages/GoogleChrome").Split("`r`n") | Select-String "<title>").ToString() -split " " -replace "</title>",""  | Select-Object -Last 1
  }
  

################################# Build Settings ###########################################

# Builds location
$buildLocation = "$PSSCRIPTROOT\AppGrabber_Builds"
if(!(Test-Path $buildLocation)){
	New-Item $buildLocation -Type Directory | Out-Null
}

$templateLocation = "$PSSCRIPTROOT\AppGrabber_Templates"
if(!(Test-Path $templateLocation)){
	New-Item $templateLocation -Type Directory | Out-Null
}


################################# Define softwares ###########################################

# Set start time
$startTime = Get-Date -Format HH:mm:ss
# Set counting apps to download to zero
$appsToDL = 0
# Count recepies, starts from 1
$countRecepie = 1

Write-Host("`n`n`n`n`n`n`n")
Write-Host "============================================================" -ForegroundColor 'green'
Write-Host "AppGrabber - Script started" -ForegroundColor 'green'
LogWrite "AppGrabber - Script started"
Write-Host "============================================================" -ForegroundColor 'green'

# Cycle through all recepies found in $recepieLocation
forEach($recepie in $recepies){
# Set app name to the recepie name without .extension
$recepieName = $recepie.BaseName

Write-Host "Processing $recepieName | Recepie [$countRecepie/$totalRecepies]" -ForegroundColor 'green'
LogWrite "Processing $recepieName"

. $recepieLocation\$recepieName.ps1

Write-Host "------------------------------------------------------------"  -ForegroundColor 'green'
$countRecepie++
}

$endTime = Get-Date -Format HH:mm:ss
$totalTime = New-TimeSpan $startTime $endTime

# Updates available (Slack)
if($enableSlack -and $appsToDL -gt 0){
	if($appsToDL -eq 1){
		SlackWrite "*1* new app grabbed!"
	} else {
		SlackWrite "*$appsToDL* new apps grabbed!"
	}
	SlackWrite "*Script has completed in $totalTime*"
	SlackWrite "============================================================"
} else {
	#SlackWrite "*Sorry! No apps to grab..*"
}

Write-Host "============================================================" -ForegroundColor 'green'
Write-Host "Script has completed in $totalTime " -ForegroundColor 'green'
Write-Host "============================================================" -ForegroundColor 'green'
LogWrite "Script has completed in $totalTime"
LogWrite   "============================================================"

################################# AppGrabber Settings ###########################################

# Download location
$dlLocation = "$PSSCRIPTROOT\AppGrabber_Downloads"

if(!(Test-Path $dlLocation)){
	New-Item $dlLocation -Type Directory | Out-Null
}

# Recepies location
$recepieLocation = "$PSSCRIPTROOT\AppGrabber_Recepies"
$recepies = Get-ChildItem "$recepieLocation\*.ps1"
$totalRecepies = Get-Childitem $recepieLocation | where {$_.extension -in ".ps1"}  | group Extension -NoElement | sort count -desc | Select -ExpandProperty count

# File versions location
$fvLocation = "$PSSCRIPTROOT\AppGrabber_Downloads\file_versions"

if(!(Test-Path $fvLocation)){
	New-Item $fvLocation -Type Directory | Out-Null
}

# Clean download folder at script start? (0=Disabled,1=Enabled)
$cleanFolder = 0

if($cleanFolder -eq 1){
Remove-Item "$dlLocation\*.*"
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
$startTime = Get-Date -Format HH:mm:ss
$appsToDL = 0
Write-Host("`n")
Write-Host("`n")
Write-Host("`n")
Write-Host("`n")
Write-Host "============================================================" -ForegroundColor 'green'
Write-Host "AppGrabber - Script started" -ForegroundColor 'green'
LogWrite "AppGrabber - Script started"
Write-Host "============================================================" -ForegroundColor 'green'

$countRecepie = 1

forEach($recepie in $recepies){
$recepieName = $recepie.BaseName

Write-Host "Processing $recepieName | Recepie [$countRecepie/$totalRecepies]" -ForegroundColor 'green'
LogWrite "Processing $recepieName"

. $recepieLocation\$recepieName.ps1

Write-Host "------------------------------------------------------------"  -ForegroundColor 'green'
$countRecepie++
}

$endTime = Get-Date -Format HH:mm:ss
$totalTime = New-TimeSpan $startTime $endTime
Write-Host "============================================================" -ForegroundColor 'green'
Write-Host "Script has completed in $totalTime " -ForegroundColor 'green'
LogWrite "Script has completed in $totalTime"
Write-Host "============================================================" -ForegroundColor 'green'
LogWrite   "============================================================"
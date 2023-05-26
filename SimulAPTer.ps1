<#
.SYNOPSIS
PowerShell automation script to read local .evtx files into Elastic's winlogbeat agent and prompt the user to change the values in 
username, hostname, and timestamp etc of the log files.
To Bypass Execution Policy
PowerShell.exe -ExecutionPolicy Bypass -File .\SimulAPTer.ps1


.DESCRIPTION
PowerShell automation to read local .evtx files into Elastic's winlogbeat agent.
Use winlogbeat-evtxtojson.yml to customize your configuration of winlogbeat including filenames and agent.name
Default settings is to output the EVTX logs to NDJSON format with their names.
NDJSON logs will be saved to .\converted\allevents.ndjson. 
Once an EVTX file has been winlogbeated, it will store the filenames to $Source\converted\evtx-registry to prevent reading the same logs again.
Remove this file to replay EVTX files you have used with winlogbeat.

Original Author: Grant Sales
Date: 2020.08.20
Stripped @ modified version with feature: EkkiE
Date: 2022.05.10

Last tested: 2023.05.26 with Winlogbeat 8.8.0

.PARAMETER Reset
Reset flag will delete the registry file allowing replay of evtx files that have
already been read once. By default, winlogbeat will read all the files but will not
generate output from an already read file due to bookmarks set in the registry file.

.EXAMPLE
.\SimulAPTer.ps1
#>

param(
  [switch]$Reset
)

@("
 Powered By: EkkiE
")

$Source = "$PSScriptRoot"
$Exe = "$PSScriptRoot\winlogbeat*\winlogbeat.exe" # Wildcard in the end of winlogbeat* to find path for the winlogbeat binary
$Config = "$PSScriptRoot\winlogbeat-evtxtojson.yml"
$JsonFilePath = "$PSScriptRoot\converted"
$time = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.msZ" # Get-Date (Get-Date).AddSeconds(5)  -Format "yyyy-MM-ddTHH:mm:ss.msZ"  to change sec, min, hours..
$user = "Victim username"
$attackerusername = "Attacker username"
$hostnaming = "Victim hostname"
$attackerhostname = "Attacker hostname"
$parentdomain = "domain.local"
$subdomain = "AD"


# Getting values for variables
[Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
 $username = [Microsoft.VisualBasic.interaction]::inputbox('Enter the victim username you want to simulate', 'Victim Username?', $user)

 [Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
 [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
 $attacker = [Microsoft.VisualBasic.interaction]::inputbox('Enter the attacker username you want to simulate', 'Attacker Username?', $attackerusername)

 [Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
 $hostname = [Microsoft.VisualBasic.interaction]::inputbox('Enter the victim hostname you want to simulate', 'Victim Hostname?', $hostnaming)

 [Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
 $attackerhost = [Microsoft.VisualBasic.interaction]::inputbox('Enter the attacker hostname you want to simulate', 'Attacker Hostname?', $attackerhostname)

 [Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
 [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
 $thetime = [Microsoft.VisualBasic.interaction]::inputbox('Enter the time you want to simulate', 'Time?', $time)

[Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
 [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
 $domainname = [Microsoft.VisualBasic.interaction]::inputbox('Enter the root domain name you want to simulate', 'Domain name?', $parentdomain)

 [Void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
 [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
 $subdom = [Microsoft.VisualBasic.interaction]::inputbox('Enter the subdomain you want to simulate', 'Subdomain?', $subdomain)



Write-Host "Using binary: $Exe" -ForegroundColor Green

$winlogbeat_log = "$PSScriptRoot\converted\log"
if (!(Test-Path -Path "$PSScriptRoot\converted")) {
  New-Item -Path "$PSScriptRoot\converted" -ItemType Directory
}
else {
  if ($Reset -and (Test-Path -Path "$PSScriptRoot\converted\evtx-registry.yml")) {
    Remove-Item -Path "$PSScriptRoot\converted\evtx-registry.yml"
  }
}

if (Test-Path -Path $Config) {
  ## Use winlogbeat-evtxtojson.yml config
  Write-Host "Using config from: $Config" -ForegroundColor Green

}
else {
  Write-Host "Could not find winlogbeat-evtxtojson.yml" -ForegroundColor Red
}

# Get input evtx files, searching source directory recursively, if not desired put the path after -Path "$Source\PathtoEVTXFiles"
Write-Host "Source from: $Source" -ForegroundColor Green
$evtx_files = Get-ChildItem -Path "$Source" -Filter "*.evtx" -Recurse
# Count the evtx files
$evtx_count = $evtx_files.count

# if equals zero stop. 
if ($evtx_count -eq 0){
  Write-Error -Message "No EVTX files found at $Source" -ErrorAction Stop
}

# Write amount of evtx files.
Write-Host "Processing $evtx_count EVTX files." -ForegroundColor Green
# Loop each evtx file to winlogbeat.exe and output a ndjson file to work with later in script.
# EVTX_FILE is evtx filepath as argument to winlogbeat which it will parse and output.
# EVTX_NAME is filename as argument to winlogbeat which is used to save the file with its filename in ndjson format.
foreach ($evtx in $evtx_files) {
  $evtx_path = $evtx.FullName
  $evtx_name = $evtx.name
    & $Exe -c $Config -e --path.data "$PSScriptRoot\converted" -E "CWD=$PSScriptRoot" -E "EVTX_FILE=$evtx_path" -E "EVTX_NAME=$evtx_name" 2>&1 >> "$winlogbeat_log"
  }


write-Host -ForegroundColor Yellow "#######################################################################################################"
write-Host -ForegroundColor Yellow "####                                                                                                   "
Write-Host -ForegroundColor Yellow "####                        Converting EVTX files to one NDJSON completed                              "
Write-Host -ForegroundColor Yellow "####             Changing the username to $username and hostname to $hostname                          "
Write-Host -ForegroundColor Yellow "####                                                                                                   "
write-Host -ForegroundColor Yellow "####                                                                                                   "
write-Host -ForegroundColor Yellow "#######################################################################################################"

# Remove ErrorActionPreference "SilentlyContinue" to see all errors while running script.
$ErrorActionPreference = "SilentlyContinue"
Write-host "Working with files in folder: $JsonFilePath" -ForegroundColor Yellow
# All evtx converted ndjson files saved untouched in allinoneraw.ndjson
Get-Content $PSScriptRoot\converted\*ndjson* | Set-Content "$JsonFilePath\allinoneraw.ndjson"
$json =  [System.IO.File]::ReadLines("$JsonFilePath\allinoneraw.ndjson") | ConvertFrom-Json
# For loop to read each index in ndjson-file and change value 
Write-host "Total rows of $evtx_count EVTX files:" $Json.Length -ForegroundColor Yellow
$i = 0
foreach($iterate in $json)
{
$iterate.'@timestamp' = (Get-Date $thetime).AddSeconds($i).ToString("yyyy-MM-ddTHH:mm:ss.msZ")
$iterate.winlog.computer_name = "$hostname"
$iterate.host.name = "$hostname" 
$iterate.winlog.user_data.SubjectUserName = "$username"
$iterate.winlog.user_data.Param1 = "$username"  
$iterate.winlog.event_data.SubjectUserName = "$username" 
$iterate.winlog.event_data.TargetUserName = "$username"
$iterate.winlog.event_data.User = "$subdom\$username"
$iterate.event.created = (Get-Date $thetime).AddSeconds($i).ToString("yyyy-MM-ddTHH:mm:ss.msZ")
$iterate.winlog.event_data.SubjectDomainName = "$subdom"
$iterate.winlog.event_data.TargetDomainName = "$subdom"
$iterate.winlog.user_data.SubjectDomainName = "$subdom"
$iterate.winlog.event_data.'Detection User' = "$subdom\$username"
$iterate.winlog.event_data.jobOwner = "$subdom\$username"
$iterate.winlog.event_data.OldTargetUserName ="$username"
$iterate.winlog.event_data.'Detection Time' = (Get-Date $thetime).AddSeconds($i).ToString("yyyy-MM-ddTHH:mm:ss.msZ")
$iterate.winlog.event_data.DSName = "$domainname"
$iterate.winlog.event_data.TargetInfo = "$hostname.$subdom.$domainname"
$iterate.winlog.event_data.TargetServerName = "$hostname.$subdom.$domainname"
$iterate.winlog.event_data.AccountDomain = "$subdom.$domainname"
$iterate.winlog.event_data.AccountName = "$username"
$iterate.winlog.event_data.ClientName = "$attackerhost"
$iterate.winlog.event_data.ServiceName = "krbtgt\$domainname"
$iterate.winlog.event_data.WorkstationName = "$attackerhost"
$iterate.winlog.event_data.DestinationHostname = "$attackerhost or $hostname" # Destination are mostly same as attackerhost depending on which attack is used.
$iterate.winlog.event_data.SourceHostname = "$hostname or $attackerhost"  #Source is mostly the same as hostname depending on which attack is used.
$iterate.winlog.event_data.UserPrincipalName = "$attacker.$subdom.$domainname" # PrincipalName is mostly attackername.subdom.domainname but could also be computeraccount$.subdom.domainname
$iterate.winlog.event_data.SamAccountName = "$attacker" # SamAccountName is mostly the same as attacker username if its not a created computer account$
$iterate.winlog.event_data.DisplayName = "$attacker" #DisplayName is mostly the same as attacker username if its not a created computer account$
#$iterate.winlog.event_data.ObjectName = "Null" # Objectname has a big variation of values: DC=subdom,DC=domainname, S-1-5-32-549 or -5xx, S-1-5-21-4230534742-2542757381-3142984815-512 or -510, \REGISTRY\MACHINE\SYSTEM\ControlSet001\Control\Lsa, C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Cache\{25FC59D8-3DE9-41EA-A4D6-AE68D5131ECC}_1914620234177861815, SAM, Unknown, etc.
$i = $i + 1
}

Write-Host "Populating finished, saving files...." -ForegroundColor Yellow
# Saving the completed file to alleventspretty.json
$json | ConvertTo-Json -Depth 100 | Out-File "$JsonFilePath\alleventspretty.json"
# -Depth 100 makes the Json file pretty viewing. Compared to without -Depth .....
Write-Host "Saving alleventspretty.json from memory" -ForegroundColor Yellow
# Saving the json file and reading it to convert it to ndjson
$JSONSourceFile = [System.IO.File]::ReadLines("$JsonFilePath\alleventspretty.json") | ConvertFrom-JSON
Write-Host "Working with allevents.ndjson" -ForegroundColor Yellow
# Converting from json and saving the ndjson file
$NDJSONTargetFile = "$JsonFilePath\allevents.ndjson"
New-Item $NDJSONTargetFile -ItemType file 
for ( $i = 0 ; $i -lt $JSONSourceFile.Length ; $i++) {
  $item = $JSONSourceFile.item($i)
  $row = ($item | ConvertTo-JSON -Compress -Depth 20)
  Add-Content $NDJSONTargetFile $row
}

# All done, printing the outputted files.
Write-Host "Saving allevents.ndjson from memory" -ForegroundColor Yellow
Write-Host "This might take a while" -ForegroundColor Yellow
Write-Host -ForegroundColor Green "############################################################################################################"
Write-Host -ForegroundColor Green "####                                     ALL FILES SAVED                                                    "
Write-Host -ForegroundColor Green "####        For all untouched files  "$JsonFilePath\allinoneraw.ndjson"                                     "
Write-Host -ForegroundColor Green "####        For pretty viewing check "$JsonFilePath\alleventspretty.json"                                   "
Write-Host -ForegroundColor Green "####        For importing to SIEM check "$JsonFilePath\allevents.ndjson"                                     "
Write-Host -ForegroundColor Green "####                                      HAPPY HUNTING                                                     "
Write-Host -ForegroundColor Green "############################################################################################################"
Read-Host -Prompt "Press Enter to exit"

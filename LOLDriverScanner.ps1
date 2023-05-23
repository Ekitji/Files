# Specify the path to the loldrivers.json file via the -loldriversFilePath argument
# or place the loldrivers.json file in the same directory as this script
# Download from https://www.loldrivers.io/api/drivers.json

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$loldriversFilePath = ".\drivers.json",
    [Parameter(Mandatory = $false)]
    [string]$showtextoutput = $true,
    [Parameter(Mandatory = $false)]
    [string]$showresultgui = $true
)

# Check if the loldrivers.json file exists
if (-not (Test-Path -Path $loldriversFilePath)) {
    Write-Host "loldrivers.json file not found, please download from https://www.loldrivers.io/api/drivers.json or specify path" -ForegroundColor Red
    Exit
}

# Get all driver files in C:\windows\system32\drivers directory
$drivers = Get-ChildItem -Path "C:\windows\system32\drivers" -Force -Recurse -File -Filter "*.sys" -ErrorAction SilentlyContinue

# Read the contents of the loldrivers.json file
$loldrivers = Get-Content -Path $loldriversFilePath | ConvertFrom-Json

Write-Host "Checking $($drivers.Count) drivers in C:\windows\system32\drivers against loldrivers.io JSON file" -ForegroundColor Green

$hashes = @()

foreach ($driver in $drivers) {
    try {
        # Calculate the SHA256 hash of the driver file
        $hash = Get-FileHash -Algorithm SHA256 -Path $driver.FullName -ErrorAction Stop | Select-Object -ExpandProperty Hash
        $status = "OK"

        # Check the SHA256 hash against the drivers.json file
        if ($loldrivers.KnownVulnerableSamples | Where-Object { $_.SHA256 -eq $hash }) {
            $status = "Vulnerable"
        }

        # Calculate the Authenticode SHA256 hash of the driver file
        $authenticodeHash = (Get-AppLockerFileInformation -Path $driver.FullName).Hash
        $authenticodeHash = $authenticodeHash -replace 'SHA256 0X', ''
        
        # Check the Authenticode SHA256 hash against the drivers.json file
        if ($loldrivers.KnownVulnerableSamples.Authentihash | Where-Object { $_.SHA256 -eq $authenticodeHash}) {
            $status = "Vulnerable"
        }

        # Add information about driver file to the $hashes array
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            SHA256Hash = $hash
            AuthenticodeHash = $authenticodeHash
            Status = $status
            Path = $driver.FullName
        }
    } catch {
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            SHA256Hash = "Hash Calculation Failed: $($_.Exception.Message)"
            AuthenticodeHash = "Hash Calculation Failed: $($_.Exception.Message)"
            Status = "Error"
            Path = $driver.FullName
        }
    }
}


if ($showtextoutput -eq $true) {
    # Display results in the console with color highlighting
    Write-Output ""
    foreach ($hashEntry in $hashes) {
        $driver = $hashEntry.Driver
        $hash = $hashEntry.SHA256Hash
        $authenticodeHash = $hashEntry.AuthenticodeHash
        $status = $hashEntry.Status

        if ($status -eq "Vulnerable") {
            Write-Host "Driver: $driver"
            Write-Host "SHA256Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Red
        } elseif ($status -eq "Error") {
            Write-Host "Driver: $driver"
            Write-Host "SHA256Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Yellow
        } else {
            Write-Host "Driver: $driver"
            Write-Host "SHA256Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Green
        }

        Write-Output ""
    }
}

if ($showresultgui -eq $true) {
    # Sort the array based on the "Status" column to display vulnerable drivers at the top in Out-GridView
    Write-Output ""
    $hashesSorted = $hashes | Sort-Object -Property @{Expression = { if ($_.Status -eq "Vulnerable") { 0 } elseif ($_.Status -eq "Error") { 1 } else { 2 } } }

    # Display the sorted results in Out-GridView
    $hashesSorted | Out-GridView -Title "Results from LOLDrivers scan, check Status column for value: Vulnerable"
}

Write-Host "Scanning after LOLDrivers completed" -ForegroundColor Green
$vulnerableDrivers = ($hashes | Where-Object { $_.Status -eq "Vulnerable" }).Count

if ($vulnerableDrivers -gt 0) {
    Write-Host "Found $vulnerableDrivers Vulnerable Drivers" -ForegroundColor Red
    exit 1
} else {
    Write-Host "No vulnerable drivers found" -ForegroundColor Green
    exit 0
}

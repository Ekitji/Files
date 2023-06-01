# Specify the path to the loldrivers.json file or simply put it in the powershell script root
# and run the script
# Download from https://www.loldrivers.io/api/drivers.json
$loldriversFilePath = "$PSScriptRoot\drivers.json"
# Check if the drivers.json file exists
if (-not (Test-Path -Path $loldriversFilePath)) {
    Write-Host "drivers.json file not found, please download from https://www.loldrivers.io/api/drivers.json and specify path in script or put it in scripts root folder" -ForegroundColor Red
    Exit
}
# Get all driver files in C:\windows\system32\Drivers* directory and C:\Windows\SysWOW64\drivers
$drivers = Get-ChildItem -Path "C:\Windows\System32\drivers","C:\Windows\System32\DriverStore","C:\Windows\SysWOW64\drivers" -Force -Recurse -File -Filter "*.sys"

# Read the contents of the loldrivers.json file
$loldrivers = Get-Content -Path $loldriversFilePath | ConvertFrom-Json

Write-Host "Checking $($drivers.Count) drivers in C:\windows\system32\drivers against loldrivers.io JSON file" -ForegroundColor Yellow

#Declare a variable to keep track of the vulnerable drivers count
$vulnerableCount = 0

$hashes = @()

foreach ($driver in $drivers) {
    try {
        # Calculate the SHA256 hash of the driver file
        $hash = Get-FileHash -Algorithm SHA256 -Path $driver.FullName -ErrorAction Stop | Select-Object -ExpandProperty Hash
        $status = "OK"
        $vulnerableSample = $loldrivers.KnownVulnerableSamples | Where-Object { $_.SHA256 -eq $hash }
       if ($vulnerableSample) {
        $status = "Vulnerable"
        $vulnerableCount++
        }
        # Calculate the Authenticode SHA256 hash of the driver file
        $authenticodeHash = (Get-AppLockerFileInformation -Path $driver.FullName).Hash
        $authenticodeHash = $authenticodeHash -replace 'SHA256 0X', ''
        
        # Check the Authenticode SHA256 hash against the drivers.json file
        $authenticodeMatch = $loldrivers.KnownVulnerableSamples.Authentihash| Where-Object { $_.SHA256 -eq $authenticodeHash} 

        if ($authenticodeMatch) {
        $status = "Vulnerable"
         if ($vulnerableSample -eq $null) {
                $vulnerableCount++
        }
        }
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

# Sort the array based on the "Status" column to display vulnerable drivers at the top in Out-GridView
Write-Output ""
$hashesSorted = $hashes | Sort-Object -Property @{Expression = { if ($_.Status -eq "Vulnerable") { 0 } elseif ($_.Status -eq "Error") { 1 } else { 2 } } }


# Display the sorted results in Out-GridView
$hashesSorted | Out-GridView -Title "Results from LOLDrivers scan, check Status column for value: Vulnerable, Copy row with CTRL-C"

Write-Host "Scanning after LOLDrivers completed" -ForegroundColor Green
Write-Host "Found $vulnerableCount Vulnerable Drivers" -ForegroundColor $(if ($vulnerableCount -gt 0) { "Red" } else { "Green" })
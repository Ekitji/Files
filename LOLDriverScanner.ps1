# Specify the path to the loldrivers.json file
# Download from https://www.loldrivers.io/api/drivers.json
$loldriversFilePath = "C:\Users\*\Desktop\loldrivers\drivers.json"

# Get all driver files in C:\windows\system32\drivers directory
$drivers = Get-ChildItem -Path "C:\windows\system32\drivers" -Force -Recurse -File -Filter "*.sys"

# Read the contents of the loldrivers.json file
$loldrivers = Get-Content -Path $loldriversFilePath | ConvertFrom-Json

Write-Output "Checking $($drivers.Count) drivers in C:\windows\system32\drivers against loldrivers.io JSON file"

$hashes = @()

foreach ($driver in $drivers) {
    try {
        # Calculate the SHA256 hash of the driver file
        $hash = Get-FileHash -Algorithm SHA256 -Path $driver.FullName -ErrorAction Stop | Select-Object -ExpandProperty Hash
        $status = "OK"
        $vulnerableSample = $loldrivers.KnownVulnerableSamples | Where-Object { $_.SHA256 -eq $hash }
        if ($vulnerableSample) {
            $status = "Vulnerable"
        }

        # Calculate the Authenticode SHA256 hash of the driver file
        $authenticodeHash = (Get-AppLockerFileInformation -Path $driver.FullName).Hash
        $authenticodeHash = $authenticodeHash -replace 'SHA256 0X', ''
        
        # Check the Authenticode SHA256 hash against the drivers.json file
        $authenticodeMatch = $loldrivers.KnownVulnerableSamples.Authentihash.SHA256 -contains $authenticodeHash
        if ($authenticodeMatch) {
            $status = "Vulnerable"
        }
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            Hash = $hash
            AuthenticodeHash = $authenticodeHash
            Status = $status
            Path = $driver.FullName
        }
    } catch {
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            Hash = "Hash Calculation Failed: $($_.Exception.Message)"
            Status = "Error"
        }
    }
}

# Display results in the console with color highlighting
Write-Output ""
foreach ($hashEntry in $hashes) {
    $driver = $hashEntry.Driver
    $hash = $hashEntry.Hash
    $authenticodeHash = $hashEntry.AuthenticodeHash
    $status = $hashEntry.Status

    if ($status -eq "Vulnerable") {
        Write-Host "Driver: $driver"
        Write-Host "Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Red
    } elseif ($status -eq "Error") {
        Write-Host "Driver: $driver"
        Write-Host "Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Yellow
    } else {
        Write-Host "Driver: $driver"
        Write-Host "Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Green
    }

    Write-Output ""
}

# Sort the array based on the "Status" column to display vulnerable drivers at the top in Out-GridView
Write-Output ""
$hashesSorted = $hashes | Sort-Object -Property @{Expression = { if ($_.Status -eq "Vulnerable") { 0 } elseif ($_.Status -eq "Error") { 1 } else { 2 } } }


# Display the sorted results in Out-GridView
$hashesSorted | Out-GridView

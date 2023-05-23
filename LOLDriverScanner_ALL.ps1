# Specify the path to the loldrivers.json file
# Download from https://www.loldrivers.io/api/drivers.json
$loldriversFilePath = "C:\Users\*\Desktop\loldrivers\drivers.json"

# Get all driver files in C:\
Write-Host "Scanning after sys-files" -ForegroundColor Green
$drivers = Get-ChildItem -Path "C:\" -Force -Recurse -File -Filter "*.sys" -ErrorAction SilentlyContinue
# Check whole C: drive to catch other applications or hardwares drivers who might 
# have their own installation folders, where they store their respective .sys files.


# Read the contents of the loldrivers.json file
$loldrivers = Get-Content -Path $loldriversFilePath | ConvertFrom-Json

Write-Host "Hashing the $($drivers.Count) drivers found in C:\ and checking against loldrivers.io JSON file" -ForegroundColor Yellow

#Declare a variable to keep track of the vulnerable drivers count
$vulnerableCount = 0

$hashes = @()

foreach ($driver in $drivers) {
    try {
        # Calculate the SHA256, SHA1, and MD5 hashes of the driver file
        $sha256Hash = Get-FileHash -Algorithm SHA256 -Path $driver.FullName -ErrorAction Stop | Select-Object -ExpandProperty Hash
        $sha1Hash = Get-FileHash -Algorithm SHA1 -Path $driver.FullName -ErrorAction Stop | Select-Object -ExpandProperty Hash
        $md5Hash = Get-FileHash -Algorithm MD5 -Path $driver.FullName -ErrorAction Stop | Select-Object -ExpandProperty Hash

        $status = "OK"
        $vulnerableSample = $loldrivers.KnownVulnerableSamples | Where-Object { $_.SHA256 -eq $sha256Hash -or $_.SHA1 -eq $sha1Hash -or $_.MD5 -eq $md5Hash }

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
            Status = $status
            Path = $driver.FullName
            SHA256Hash = $sha256Hash
            AuthenticodeHash = $authenticodeHash
            SHA1Hash = $sha1Hash
            MD5Hash = $md5Hash
        }
    } catch {
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            Status = "Error"
            Path = $driver.FullName
            SHA256Hash = "Hash Calculation Failed: $($_.Exception.Message)" # Mainly the hiberfil.sys, pagefile.sys, swapfile.sys
            AuthenticodeHash = "Hash Calculation Failed: $($_.Exception.Message)" # Mainly the hiberfil.sys, pagefile.sys, swapfile.sys
            SHA1Hash = "Hash Calculation Failed: $($_.Exception.Message)" # Mainly the hiberfil.sys, pagefile.sys, swapfile.sys
            MD5Hash = "Hash Calculation Failed: $($_.Exception.Message)" # Mainly the hiberfil.sys, pagefile.sys, swapfile.sys
        }
    }
}

# Display results in the console with color highlighting - some Hash Algorithms are excluded but shown in GridView
Write-Output ""
foreach ($hashEntry in $hashes) {
    $driver = $hashEntry.Driver
    $hash = $hashEntry.SHA1Hash
    $authenticodeHash = $hashEntry.AuthenticodeHash
    $status = $hashEntry.Status

    if ($status -eq "Vulnerable") {
        Write-Host "Driver: $driver"
        Write-Host "SHA1:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Red
    } elseif ($status -eq "Error") {
        Write-Host "Driver: $driver"
        Write-Host "SHA1:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Yellow
    } else {
        Write-Host "Driver: $driver"
        Write-Host "SHA1:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Green
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

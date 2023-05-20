# Specify the path to the loldrivers.json file
$loldriversFilePath = "C:\Users\Ekkie\Desktop\loldrivers\drivers.json"

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
        if ($loldrivers.KnownVulnerableSamples.Filename -contains $driver.Name) {
            $status = "Vulnerable"
        }
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            Hash = $hash
            Status = $status
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
    $status = $hashEntry.Status

    if ($status -eq "Vulnerable") {
        Write-Host "Driver: $driver"
        Write-Host "Hash:   $hash    Status: $status" -ForegroundColor Red
    } else {
        Write-Host "Driver: $driver"
        Write-Host "Hash:   $hash    Status: $status" -ForegroundColor Green
    }

    Write-Output ""
}

# Sort the array based on the "Status" column to display vulnerable drivers at the top in Out-GridView
Write-Output ""
$hashesSorted = $hashes | Sort-Object -Property @{Expression = { if ($_.Status -eq "Vulnerable") { 0 } else { 1 } } }

# Display the sorted results in Out-GridView
$hashesSorted | Out-GridView

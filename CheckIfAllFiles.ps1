param (
    [string]$FolderName,
    [Parameter(Mandatory = $true)]
    [string]$DestinationFolder
)

if (-not (Test-Path -Path $FolderName -PathType Container)) {
    Write-Host "The folder '$FolderName' does not exist." -ForegroundColor Red
    exit 1
}

Write-Host "The folder '$FolderName' exists." -ForegroundColor Green

$files = Get-ChildItem -Path $FolderName -Filter "takeout*-*.zip" -File

if ($files.Count -eq 0) {
    Write-Host "No files matching the pattern 'takeout*-{number}.zip' were found in the folder." -ForegroundColor Yellow
    exit 1
}

$numbers = $files | ForEach-Object {
    if ($_ -match 'takeout.*-(\d+)\.zip') {
        [int]$matches[1]
    } 
} | Sort-Object 

$expectedNumber = 1
$missingNumbers = @()

foreach ($number in $numbers) {
    while ($expectedNumber -lt $number) {
        $missingNumbers += $expectedNumber
        $expectedNumber++
    }
    $expectedNumber++
}

if ($missingNumbers.Count -gt 0) {
    Write-Host "Missing files: $($missingNumbers -join ', ')" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "$($numbers.Count) files are present and in consecutive order starting from 1." -ForegroundColor Green
}

foreach ($file in $files) {
    $number = if ($file.Name -match 'takeout.*-(\d+)\.zip') { $matches[1] } else { "unknown" }
    $destinationPath = Join-Path -Path $DestinationFolder -ChildPath "$number"
    if (-not (Test-Path -Path $destinationPath -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationPath | Out-Null
    }

    Write-Host "Extracting $($file.FullName) to $destinationPath..." -ForegroundColor Cyan
    Expand-Archive -Path $file.FullName -DestinationPath $destinationPath -Force
}

Write-Host "All files have been successfully extracted to '$DestinationFolder'." -ForegroundColor Green

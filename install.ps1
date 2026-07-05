# install.ps1

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "      Mecha Chameleon Game Installer         " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Ask for installation path
$installPath = Read-Host "Enter the game installation path (Press Enter for C:\game)"
if ([string]::IsNullOrWhiteSpace($installPath)) {
    $installPath = "C:\game"
}

# Clean installation path for absolute path resolution
$installPath = [System.IO.Path]::GetFullPath($installPath)

# 2. Check and download game files
$chunkIndex = 1
$tempDir = Join-Path $env:TEMP "mecha_chameleon_temp"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

Write-Host "`nChecking and downloading game files from GitHub..." -ForegroundColor Cyan

$downloadedPaths = @()

while ($true) {
    $chunkName = "part.7z." + $chunkIndex.ToString("000")
    $url = "https://raw.githubusercontent.com/psycodess/mecha-chameleon/main/$chunkName"
    $targetPath = Join-Path $tempDir $chunkName
    
    # Check if the file exists on GitHub first
    $checkUrlCode = & curl.exe -s -o NUL -w "%{http_code}" -I -L "$url"
    if ($checkUrlCode -ne "200") {
        if ($chunkIndex -eq 1) {
            Write-Host "Error: Repository or files not found at $url" -ForegroundColor Red
            Write-Host "Make sure the GitHub repo 'mecha-chameleon' is public and the files are successfully pushed." -ForegroundColor Yellow
            return
        }
        break # No more chunks left
    }
    
    Write-Host "`nDownloading $chunkName..." -ForegroundColor Green
    & curl.exe -f -L -# -o "$targetPath" "$url"
    
    if (-not (Test-Path $targetPath)) {
        Write-Host "Error: Download failed for $chunkName" -ForegroundColor Red
        return
    }
    
    $downloadedPaths += $targetPath
    $chunkIndex++
}

# 3. Merge files
Write-Host "`nMerging game archive..." -ForegroundColor Cyan
$mergedPath = Join-Path $tempDir "MECCHA_CHAMELEON.7z"
$outputStream = [System.IO.File]::Create($mergedPath)

foreach ($partPath in $downloadedPaths) {
    Write-Host "Merging $(Split-Path $partPath -Leaf)..." -ForegroundColor Gray
    $inputStream = [System.IO.File]::OpenRead($partPath)
    $inputStream.CopyTo($outputStream)
    $inputStream.Close()
}
$outputStream.Close()
Write-Host "Merge complete." -ForegroundColor Green

# 4. Create target directory
if (-not (Test-Path $installPath)) {
    Write-Host "`nCreating target directory $installPath..." -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path $installPath | Out-Null
}

# 5. Extract files
Write-Host "`nExtracting game files to $installPath using built-in Windows tar..." -ForegroundColor Cyan
& tar.exe -xf "$mergedPath" -C "$installPath"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nExtraction completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nExtraction failed. Please check if tar.exe encountered any errors." -ForegroundColor Red
    return
}

# 6. Cleanup
Write-Host "`nCleaning up temporary files..." -ForegroundColor Gray
Remove-Item -Recurse -Force $tempDir
Write-Host "Cleanup complete." -ForegroundColor Green

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " Installation Finished! Game installed at:   " -ForegroundColor Green
Write-Host " $installPath" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

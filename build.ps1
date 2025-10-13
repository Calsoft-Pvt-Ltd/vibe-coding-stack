# Build script for Local Vibe Coding Stack MSI Installer
# Requires WiX Toolset 3.14+ to be installed

param(
    [string]$Configuration = "Release",
    [string]$OutputDir = ".\output",
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Building Local Vibe Coding Stack MSI Installer ===" -ForegroundColor Cyan

# Check for WiX Toolset
$WixPath = "${env:ProgramFiles(x86)}\WiX Toolset v3.14\bin"
if (-not (Test-Path $WixPath)) {
    $WixPath = "${env:ProgramFiles}\WiX Toolset v3.14\bin"
}

if (-not (Test-Path $WixPath)) {
    Write-Host "ERROR: WiX Toolset not found!" -ForegroundColor Red
    Write-Host "Please install WiX Toolset from: https://wixtoolset.org/releases/" -ForegroundColor Yellow
    exit 1
}

$CandleExe = Join-Path $WixPath "candle.exe"
$LightExe = Join-Path $WixPath "light.exe"

Write-Host "Found WiX Toolset at: $WixPath" -ForegroundColor Green

# Create output directory
if ($Clean -and (Test-Path $OutputDir)) {
    Write-Host "Cleaning output directory..."
    Remove-Item -Path $OutputDir -Recurse -Force
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Created output directory: $OutputDir"
}

# Create temporary build directory
$BuildDir = ".\build"
if (Test-Path $BuildDir) {
    Remove-Item -Path $BuildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $BuildDir | Out-Null

# Verify assets directory exists
$AssetsDir = ".\assets"
if (-not (Test-Path $AssetsDir)) {
    Write-Host "Creating assets directory..."
    New-Item -ItemType Directory -Path $AssetsDir | Out-Null
}

# Note: Optional assets (icon.ico, banner.bmp, dialog.bmp, license.rtf) 
# are not required for the build. Add them to the assets folder for 
# custom branding if desired.

# Step 1: Compile WiX source files (.wxs -> .wixobj)
Write-Host "`nStep 1: Compiling WiX source files..." -ForegroundColor Cyan

$WxsFile = ".\src\installer\Product.wxs"
$WixObjFile = Join-Path $BuildDir "Product.wixobj"

$CandleArgs = @(
    "-nologo"
    "-ext", "WixUtilExtension"
    "-out", $WixObjFile
    $WxsFile
)

Write-Host "Running: candle.exe $($CandleArgs -join ' ')"
& $CandleExe $CandleArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Compilation failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Compilation successful!" -ForegroundColor Green

# Step 2: Link WiX object files (.wixobj -> .msi)
Write-Host "`nStep 2: Linking MSI installer..." -ForegroundColor Cyan

$MsiFile = Join-Path $OutputDir "LocalVibeCodingStack.msi"

$LightArgs = @(
    "-nologo"
    "-ext", "WixUIExtension"
    "-ext", "WixUtilExtension"
    "-cultures:en-US"
    "-out", $MsiFile
    $WixObjFile
)

Write-Host "Running: light.exe $($LightArgs -join ' ')"
& $LightExe $LightArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Linking failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Linking successful!" -ForegroundColor Green

# Cleanup build directory
Write-Host "`nCleaning up temporary files..."
Remove-Item -Path $BuildDir -Recurse -Force

# Display results
Write-Host "`n=== Build Complete ===" -ForegroundColor Green
Write-Host "MSI Installer: $MsiFile" -ForegroundColor Cyan
Write-Host "File size: $([math]::Round((Get-Item $MsiFile).Length / 1MB, 2)) MB" -ForegroundColor Cyan

# Calculate hash for verification
Write-Host "`nCalculating SHA256 hash..."
$Hash = Get-FileHash -Path $MsiFile -Algorithm SHA256
Write-Host "SHA256: $($Hash.Hash)" -ForegroundColor Yellow

Write-Host "`nTo install, run: msiexec /i `"$MsiFile`"" -ForegroundColor Cyan
Write-Host "Or double-click the MSI file" -ForegroundColor Cyan

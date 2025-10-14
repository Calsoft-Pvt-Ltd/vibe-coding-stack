# Build script for Local Vibe Coding Stack MSI Installer
# Requires WiX Toolset 6.0+ (wix.exe CLI) to be installed

param(
    [string]$Configuration = "Release",
    [string]$OutputDir = ".\output",
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Building Local Vibe Coding Stack MSI Installer ===" -ForegroundColor Cyan

# Locate WiX CLI
$WixExe = $null
$WixCommand = Get-Command "wix.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($WixCommand) {
    $WixExe = $WixCommand.Source
}

if (-not $WixExe) {
    $FallbackPaths = @(
        "${env:ProgramFiles}\WiX Toolset v6\bin\wix.exe",
        "${env:ProgramFiles(x86)}\WiX Toolset v6\bin\wix.exe",
        "${env:ProgramFiles}\WiX Toolset\wix.exe",
        "${env:ProgramFiles}\WiX Toolset\bin\wix.exe"
    )

    foreach ($Path in $FallbackPaths) {
        if (Test-Path $Path) {
            $WixExe = $Path
            break
        }
    }
}

if (-not $WixExe) {
    Write-Host "ERROR: WiX Toolset CLI (wix.exe) not found!" -ForegroundColor Red
    Write-Host "Install it via: dotnet tool install --global wix --version 6.*" -ForegroundColor Yellow
    Write-Host "Documentation: https://wixtoolset.org/docs/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found WiX CLI at: $WixExe" -ForegroundColor Green

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

# Step 1: Ensure required WiX extensions are available
Write-Host "`nStep 1: Preparing WiX extensions..." -ForegroundColor Cyan
$RequiredExtensions = @(
    "WixToolset.UI.wixext"
)

foreach ($Extension in $RequiredExtensions) {
    Write-Host "Ensuring extension $Extension is installed..."
    & $WixExe "extension" "add" $Extension
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to add extension $Extension" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host "Extensions ready." -ForegroundColor Green

# Step 2: Build MSI
Write-Host "`nStep 2: Building MSI with WiX 6..." -ForegroundColor Cyan

$WxsFile = ".\src\installer\Product.wxs"
$MsiFile = Join-Path $OutputDir "LocalVibeCodingStack.msi"

$BuildArgs = @(
    "build"
    $WxsFile
    "-ext", "WixToolset.UI.wixext"
    "-out", $MsiFile
)

Write-Host "Running: wix $($BuildArgs -join ' ')"
& $WixExe $BuildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: WiX build failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "WiX build successful!" -ForegroundColor Green

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

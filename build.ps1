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

# Create placeholder assets if they don't exist
$AssetsDir = ".\assets"

# Create placeholder icon
$IconPath = Join-Path $AssetsDir "icon.ico"
if (-not (Test-Path $IconPath)) {
    Write-Host "Warning: icon.ico not found, using default" -ForegroundColor Yellow
    # Copy a default Windows icon or create a placeholder
    Copy-Item "$env:SystemRoot\System32\imageres.dll" $IconPath -ErrorAction SilentlyContinue
}

# Create placeholder license
$LicensePath = Join-Path $AssetsDir "license.rtf"
if (-not (Test-Path $LicensePath)) {
    Write-Host "Creating default license file..."
    $LicenseContent = @"
{\rtf1\ansi\ansicpg1252\deff0\nouicompat{\fonttbl{\f0\fnil\fcharset0 Calibri;}}
{\*\generator Riched20 10.0.19041}\viewkind4\uc1 
\pard\sa200\sl276\slmult1\f0\fs22\lang9 MIT License\par
Copyright (c) 2025 Local Vibe\par
\par
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\par
\par
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\par
\par
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\par
}
"@
    $LicenseContent | Out-File -FilePath $LicensePath -Encoding ASCII
}

# Create placeholder banner (493x58 pixels)
$BannerPath = Join-Path $AssetsDir "banner.bmp"
if (-not (Test-Path $BannerPath)) {
    Write-Host "Warning: banner.bmp not found (493x58 pixels recommended)" -ForegroundColor Yellow
}

# Create placeholder dialog image (493x312 pixels)
$DialogPath = Join-Path $AssetsDir "dialog.bmp"
if (-not (Test-Path $DialogPath)) {
    Write-Host "Warning: dialog.bmp not found (493x312 pixels recommended)" -ForegroundColor Yellow
}

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

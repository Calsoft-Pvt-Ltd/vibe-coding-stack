# Build EXE Installer
# This script converts the PowerShell installer to an EXE using PS2EXE

param(
    [string]$OutputDir = ".\dist"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Building EXE Installer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if ps2exe is installed
$ps2exeInstalled = Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue

if (-not $ps2exeInstalled) {
    Write-Host "PS2EXE not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
        Write-Host "PS2EXE installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install PS2EXE: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install manually:" -ForegroundColor Yellow
        Write-Host "  Install-Module -Name ps2exe -Scope CurrentUser" -ForegroundColor White
        exit 1
    }
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$ScriptPath = ".\scripts\standalone-installer.ps1"
$OutputExe = Join-Path $OutputDir "LocalVibeCodingStack-Setup.exe"

if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: Script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Building EXE installer..." -ForegroundColor Cyan
Write-Host "  Input:  $ScriptPath" -ForegroundColor Gray
Write-Host "  Output: $OutputExe" -ForegroundColor Gray
Write-Host ""

try {
    # Build the EXE
    Invoke-ps2exe `
        -inputFile $ScriptPath `
        -outputFile $OutputExe `
        -title "Local Vibe Coding Stack Installer" `
        -description "Automated installer for VS Code, Cline, LM Studio, and AI model" `
        -company "Local Vibe" `
        -product "Local Vibe Coding Stack" `
        -version "1.0.0.0" `
        -noConsole:$false `
        -requireAdmin:$false `
        -supportOS `
        -noOutput:$false `
        -noError:$false `
        -credentialGUI:$false
    
    if (Test-Path $OutputExe) {
        $fileSize = (Get-Item $OutputExe).Length / 1MB
        Write-Host ""
        Write-Host "✓ EXE built successfully!" -ForegroundColor Green
        Write-Host "  Location: $OutputExe" -ForegroundColor White
        Write-Host "  Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor White
        Write-Host ""
        Write-Host "You can now distribute this EXE file." -ForegroundColor Cyan
        Write-Host "Users simply run it - no MSI, no admin required!" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Build failed - output file not created" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "✗ Build failed: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Build complete!" -ForegroundColor Green

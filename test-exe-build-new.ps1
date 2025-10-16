# Test EXE Installer Build
# This script tests if the standalone installer can be converted to EXE

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Testing EXE Build Process" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$TestsPassed = 0
$TestsFailed = 0

function Test-Requirement {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FailureMessage = "Test failed",
        [string]$InstallCommand = ""
    )
    
    Write-Host "Testing: $Name..." -NoNewline
    try {
        $result = & $Test
        if ($result) {
            Write-Host " ✓" -ForegroundColor Green
            $script:TestsPassed++
            return $true
        } else {
            Write-Host " ✗" -ForegroundColor Red
            Write-Host "  $FailureMessage" -ForegroundColor Yellow
            if ($InstallCommand) {
                Write-Host "  Install: $InstallCommand" -ForegroundColor Gray
            }
            $script:TestsFailed++
            return $false
        }
    } catch {
        Write-Host " ✗" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Yellow
        if ($InstallCommand) {
            Write-Host "  Install: $InstallCommand" -ForegroundColor Gray
        }
        $script:TestsFailed++
        return $false
    }
}

Write-Host "Checking prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Test 1: PowerShell version
Test-Requirement -Name "PowerShell 5.1+" -Test {
    $PSVersionTable.PSVersion.Major -ge 5
} -FailureMessage "PowerShell 5.1 or higher required"

# Test 2: Standalone installer exists
Test-Requirement -Name "Standalone installer script" -Test {
    Test-Path ".\scripts\standalone-installer.ps1"
} -FailureMessage "standalone-installer.ps1 not found in scripts folder"

# Test 3: IExpress available (built into Windows)
Test-Requirement -Name "IExpress (built into Windows)" -Test {
    $null -ne (Get-Command iexpress.exe -ErrorAction SilentlyContinue)
} -FailureMessage "IExpress not found (should be in Windows)"

# Test 4: PS2EXE module (optional)
$hasPS2EXE = Test-Requirement -Name "PS2EXE module (optional)" -Test {
    $null -ne (Get-Module -ListAvailable -Name ps2exe)
} -FailureMessage "PS2EXE not installed (optional - IExpress can be used instead)" -InstallCommand "Install-Module -Name ps2exe -Scope CurrentUser -Force"

# Test 5: Output directory writable
Test-Requirement -Name "Output directory writable" -Test {
    $testDir = ".\dist"
    if (-not (Test-Path $testDir)) {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }
    Test-Path $testDir -PathType Container
} -FailureMessage "Cannot create output directory"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Test Results" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Passed: $TestsPassed" -ForegroundColor Green
Write-Host "Failed: $TestsFailed" -ForegroundColor $(if ($TestsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($TestsFailed -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can build the EXE using:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Option 1 (IExpress - No tools needed):" -ForegroundColor White
    Write-Host "    .\build-exe-iexpress.ps1" -ForegroundColor Gray
    Write-Host ""
    if ($hasPS2EXE) {
        Write-Host "  Option 2 (PS2EXE - Better compression):" -ForegroundColor White
        Write-Host "    .\build-exe.ps1" -ForegroundColor Gray
    } else {
        Write-Host "  Option 2 (PS2EXE - Install first):" -ForegroundColor White
        Write-Host "    Install-Module -Name ps2exe -Scope CurrentUser -Force" -ForegroundColor Gray
        Write-Host "    .\build-exe.ps1" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Offer to build now
    $response = Read-Host "Would you like to build the EXE now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host ""
        if ($hasPS2EXE) {
            Write-Host "Building with PS2EXE..." -ForegroundColor Cyan
            & .\build-exe.ps1
        } else {
            Write-Host "Building with IExpress..." -ForegroundColor Cyan
            & .\build-exe-iexpress.ps1
        }
    }
} else {
    Write-Host "✗ Some tests failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please resolve the issues above and try again." -ForegroundColor Yellow
    exit 1
}

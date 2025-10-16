# Validate PowerShell Scripts
# Checks syntax of all .ps1 files

Write-Host "Validating PowerShell scripts..." -ForegroundColor Cyan
Write-Host ""

$ScriptsToCheck = @(
    ".\test-exe-build.ps1",
    ".\build-exe.ps1",
    ".\build-exe-iexpress.ps1",
    ".\scripts\standalone-installer.ps1"
)

$AllValid = $true

foreach ($Script in $ScriptsToCheck) {
    if (-not (Test-Path $Script)) {
        Write-Host "[WARN] Skipped: $Script (not found)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Checking: $Script" -NoNewline
    
    try {
        # Try to parse the script
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $Script -Raw), [ref]$null)
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $AllValid = $false
    }
}

Write-Host ""
if ($AllValid) {
    Write-Host "[OK] All scripts are valid!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Some scripts have syntax errors" -ForegroundColor Red
    exit 1
}

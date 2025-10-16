# Build EXE using IExpress (Built into Windows)
# This script creates a self-extracting executable using IExpress
# No additional tools required!

param(
    [string]$OutputDir = ".\dist"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Building EXE with IExpress" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$ScriptPath = Resolve-Path ".\scripts\standalone-installer.ps1"
$OutputExe = Join-Path (Resolve-Path $OutputDir) "LocalVibeCodingStack-Setup.exe"
$SedFile = Join-Path $OutputDir "installer-config.sed"

# Create IExpress configuration file
$SedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles

[Strings]
InstallPrompt=Would you like to install Local Vibe Coding Stack? This will install VS Code, Cline, LM Studio, and configure your AI assistant.
DisplayLicense=
FinishMessage=Installation completed! Check your desktop for the shortcut.
TargetName=$OutputExe
FriendlyName=Local Vibe Coding Stack Installer
AppLaunched=cmd /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File standalone-installer.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="standalone-installer.ps1"

[SourceFiles]
SourceFiles0=$((Get-Item $ScriptPath).DirectoryName)

[SourceFiles0]
%FILE0%=
"@

Write-Host "Creating IExpress configuration..." -ForegroundColor Cyan
$SedContent | Set-Content -Path $SedFile -Encoding ASCII

Write-Host "Building EXE installer..." -ForegroundColor Cyan
Write-Host "  Input:  $ScriptPath" -ForegroundColor Gray
Write-Host "  Output: $OutputExe" -ForegroundColor Gray
Write-Host "  Config: $SedFile" -ForegroundColor Gray
Write-Host ""

try {
    # Run IExpress
    $process = Start-Process -FilePath "iexpress.exe" -ArgumentList "/N", "/Q", $SedFile -Wait -PassThru -WindowStyle Hidden
    
    if ($process.ExitCode -eq 0 -and (Test-Path $OutputExe)) {
        $fileSize = (Get-Item $OutputExe).Length / 1MB
        Write-Host ""
        Write-Host "[OK] EXE built successfully!" -ForegroundColor Green
        Write-Host "  Location: $OutputExe" -ForegroundColor White
        Write-Host "  Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor White
        Write-Host ""
        Write-Host "You can now distribute this EXE file." -ForegroundColor Cyan
        Write-Host "Built with IExpress - no admin required!" -ForegroundColor Cyan
    } else {
        Write-Host "[FAIL] Build failed - output file not created" -ForegroundColor Red
        Write-Host "Exit code: $($process.ExitCode)" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "[FAIL] Build failed: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Build complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: IExpress is built into Windows, so this EXE is" -ForegroundColor Yellow
Write-Host "less likely to trigger antivirus warnings than PS2EXE." -ForegroundColor Yellow

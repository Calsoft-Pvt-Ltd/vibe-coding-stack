# Local Vibe Coding Stack - Uninstallation Script
# This script removes VS Code, Cline, LM Studio, and optionally AI models

#Requires -RunAsAdministrator

param(
    [switch]$RemoveModels = $false,
    [switch]$RemoveSettings = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Initialize logging
$LogFile = "$env:TEMP\LocalVibeCodingStack-uninstall.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

Write-Log "=== Local Vibe Coding Stack Uninstallation Started ==="

# Confirm uninstallation
if (-not $Force) {
    $Confirmation = Read-Host "Are you sure you want to uninstall Local Vibe Coding Stack? (yes/no)"
    if ($Confirmation -ne "yes") {
        Write-Log "Uninstallation cancelled by user"
        exit 0
    }
}

# 1. Uninstall Cline Extension
Write-Log "=== Removing Cline Extension ==="
try {
    $CodeExe = "code"
    
    Write-Log "Uninstalling Cline extension..."
    $Process = Start-Process -FilePath $CodeExe `
        -ArgumentList "--uninstall-extension", "saoudrizwan.claude-dev" `
        -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
    
    if ($Process.ExitCode -eq 0) {
        Write-Log "Cline extension uninstalled successfully"
    } else {
        Write-Log "Cline extension may not have been installed" "WARN"
    }
} catch {
    Write-Log "Could not uninstall Cline extension: $_" "WARN"
}

# 2. Uninstall VS Code
Write-Log "=== Uninstalling VS Code ==="

# Find VS Code installation
$VSCodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code",
    "$env:ProgramFiles\Microsoft VS Code",
    "$env:ProgramFiles(x86)\Microsoft VS Code"
)

$VSCodeInstalled = $false
foreach ($Path in $VSCodePaths) {
    if (Test-Path "$Path\unins000.exe") {
        Write-Log "Found VS Code at: $Path"
        Write-Log "Uninstalling VS Code..."
        
        Start-Process -FilePath "$Path\unins000.exe" `
            -ArgumentList "/VERYSILENT", "/NORESTART" `
            -Wait -NoNewWindow
        
        Write-Log "VS Code uninstalled"
        $VSCodeInstalled = $true
        break
    }
}

if (-not $VSCodeInstalled) {
    # Try MSI uninstall
    Write-Log "Attempting MSI-based uninstall..."
    
    $VSCodeProduct = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Visual Studio Code*" }
    if ($VSCodeProduct) {
        Write-Log "Found VS Code product: $($VSCodeProduct.Name)"
        $VSCodeProduct.Uninstall() | Out-Null
        Write-Log "VS Code uninstalled via MSI"
    } else {
        Write-Log "VS Code installation not found" "WARN"
    }
}

# 3. Uninstall LM Studio
Write-Log "=== Uninstalling LM Studio ==="

$LMStudioPath = "$env:LOCALAPPDATA\LM-Studio"
$LMStudioUninstaller = "$LMStudioPath\Uninstall LM Studio.exe"

if (Test-Path $LMStudioUninstaller) {
    Write-Log "Found LM Studio uninstaller"
    Write-Log "Uninstalling LM Studio..."
    
    Start-Process -FilePath $LMStudioUninstaller `
        -ArgumentList "/S" `
        -Wait -NoNewWindow
    
    Write-Log "LM Studio uninstalled"
} else {
    Write-Log "LM Studio uninstaller not found" "WARN"
}

# Remove LM Studio directory if it still exists
if (Test-Path $LMStudioPath) {
    Write-Log "Removing LM Studio directory..."
    Remove-Item -Path $LMStudioPath -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. Remove AI Models (optional)
if ($RemoveModels) {
    Write-Log "=== Removing AI Models ==="
    
    $ModelPaths = @(
        "$env:USERPROFILE\.cache\lm-studio",
        "$env:USERPROFILE\.lmstudio"
    )
    
    foreach ($Path in $ModelPaths) {
        if (Test-Path $Path) {
            Write-Log "Removing models from: $Path"
            try {
                Remove-Item -Path $Path -Recurse -Force
                Write-Log "Models removed from: $Path"
            } catch {
                Write-Log "Could not remove models from: $Path - $_" "WARN"
            }
        }
    }
} else {
    Write-Log "Keeping AI models (use -RemoveModels to delete)"
}

# 5. Remove VS Code Settings (optional)
if ($RemoveSettings) {
    Write-Log "=== Removing VS Code Settings ==="
    
    $SettingsPaths = @(
        "$env:APPDATA\Code",
        "$env:USERPROFILE\.vscode"
    )
    
    foreach ($Path in $SettingsPaths) {
        if (Test-Path $Path) {
            Write-Log "Removing settings from: $Path"
            try {
                Remove-Item -Path $Path -Recurse -Force
                Write-Log "Settings removed from: $Path"
            } catch {
                Write-Log "Could not remove settings from: $Path - $_" "WARN"
            }
        }
    }
} else {
    Write-Log "Keeping VS Code settings (use -RemoveSettings to delete)"
}

# 6. Remove PATH entries
Write-Log "=== Cleaning PATH environment variable ==="

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$PathsToRemove = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
    "$env:ProgramFiles\Microsoft VS Code\bin"
)

$ModifiedPath = $UserPath
foreach ($PathToRemove in $PathsToRemove) {
    if ($ModifiedPath -like "*$PathToRemove*") {
        $ModifiedPath = $ModifiedPath -replace [regex]::Escape(";$PathToRemove"), ""
        $ModifiedPath = $ModifiedPath -replace [regex]::Escape("$PathToRemove;"), ""
        $ModifiedPath = $ModifiedPath -replace [regex]::Escape($PathToRemove), ""
        Write-Log "Removed from PATH: $PathToRemove"
    }
}

if ($ModifiedPath -ne $UserPath) {
    [Environment]::SetEnvironmentVariable("Path", $ModifiedPath, "User")
    Write-Log "PATH updated"
}

# 7. Remove desktop shortcuts
Write-Log "=== Removing shortcuts ==="

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

$ShortcutsToRemove = @(
    "$DesktopPath\VS Code (Local Vibe).lnk",
    "$DesktopPath\Visual Studio Code.lnk",
    "$DesktopPath\LM Studio.lnk",
    "$StartMenuPath\Local Vibe Coding Stack.lnk"
)

foreach ($Shortcut in $ShortcutsToRemove) {
    if (Test-Path $Shortcut) {
        Remove-Item -Path $Shortcut -Force
        Write-Log "Removed shortcut: $Shortcut"
    }
}

# Cleanup
Write-Log "=== Uninstallation Complete ==="
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Local Vibe Coding Stack Uninstalled" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

if (-not $RemoveModels) {
    Write-Host "Note: AI models were preserved. To remove them, run:" -ForegroundColor Yellow
    Write-Host "  Remove-Item -Path '$env:USERPROFILE\.cache\lm-studio' -Recurse -Force" -ForegroundColor Cyan
    Write-Host ""
}

if (-not $RemoveSettings) {
    Write-Host "Note: VS Code settings were preserved. To remove them, run:" -ForegroundColor Yellow
    Write-Host "  Remove-Item -Path '$env:APPDATA\Code' -Recurse -Force" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Uninstallation log saved to: $LogFile" -ForegroundColor Yellow
Write-Host ""

Write-Log "Uninstallation script completed successfully"

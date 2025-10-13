# Local Vibe Coding Stack - Installation Script
# This script automates the installation of VS Code, Cline, LM Studio, and AI model

#Requires -RunAsAdministrator

param(
    [string]$ConfigPath = "$PSScriptRoot\..\assets\installer-config.json",
    [switch]$OfflineMode = $false,
    [switch]$SkipModelDownload = $false
)

# Set error handling
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Initialize logging
$LogFile = "$env:TEMP\LocalVibeCodingStack-install.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

Write-Log "=== Local Vibe Coding Stack Installation Started ==="
Write-Log "Log file: $LogFile"

# Load configuration
try {
    Write-Log "Loading configuration from: $ConfigPath"
    $Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    Write-Log "Configuration loaded successfully"
} catch {
    Write-Log "Failed to load configuration: $_" "ERROR"
    exit 1
}

# Create temp directory for downloads
$TempDir = "$env:TEMP\LocalVibeCodingStack"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
    Write-Log "Created temporary directory: $TempDir"
}

# Function to download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description
    )
    
    try {
        Write-Log "Downloading $Description from: $Url"
        Write-Host "Downloading $Description... This may take a while."
        
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($Url, $OutputPath)
        
        Write-Log "Downloaded successfully to: $OutputPath"
        return $true
    } catch {
        Write-Log "Failed to download $Description: $_" "ERROR"
        return $false
    }
}

# Function to check if software is installed
function Test-SoftwareInstalled {
    param([string]$Name, [string]$Path)
    
    if ($Path -and (Test-Path ([Environment]::ExpandEnvironmentVariables($Path)))) {
        Write-Log "$Name is already installed at: $Path"
        return $true
    }
    return $false
}

# 1. Install VS Code
if ($Config.components.vscode.enabled) {
    Write-Log "=== Installing VS Code ==="
    
    $VSCodePath = [Environment]::ExpandEnvironmentVariables($Config.components.vscode.installPath)
    
    if (Test-SoftwareInstalled "VS Code" "$VSCodePath\Code.exe") {
        Write-Log "VS Code already installed, skipping..."
    } else {
        $VSCodeInstaller = Join-Path $TempDir "VSCodeSetup.msi"
        
        if (Download-File -Url $Config.components.vscode.downloadUrl -OutputPath $VSCodeInstaller -Description "VS Code") {
            Write-Log "Installing VS Code..."
            $InstallArgs = @(
                "/i"
                "`"$VSCodeInstaller`""
                "/qn"
                "/norestart"
                "ADDLOCAL=ALL"
                "ALLUSERS=0"
            )
            
            Start-Process "msiexec.exe" -ArgumentList $InstallArgs -Wait -NoNewWindow
            Write-Log "VS Code installation completed"
            
            # Add to PATH
            $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
            $CodePath = "$VSCodePath\bin"
            if ($UserPath -notlike "*$CodePath*") {
                [Environment]::SetEnvironmentVariable("Path", "$UserPath;$CodePath", "User")
                Write-Log "Added VS Code to PATH"
            }
        } else {
            Write-Log "Failed to download VS Code" "ERROR"
        }
    }
} else {
    Write-Log "VS Code installation is disabled in config"
}

# Wait for VS Code to be available
Start-Sleep -Seconds 5

# 2. Install Cline Extension
if ($Config.components.cline.enabled) {
    Write-Log "=== Installing Cline Extension ==="
    
    $VSCodePath = [Environment]::ExpandEnvironmentVariables($Config.components.vscode.installPath)
    $CodeExe = "$VSCodePath\bin\code.cmd"
    
    if (-not (Test-Path $CodeExe)) {
        # Try alternative locations
        $CodeExe = "code"
    }
    
    try {
        Write-Log "Installing Cline extension: $($Config.components.cline.extensionId)"
        
        # Install extension
        $Process = Start-Process -FilePath $CodeExe `
            -ArgumentList "--install-extension", $Config.components.cline.extensionId, "--force" `
            -NoNewWindow -Wait -PassThru
        
        if ($Process.ExitCode -eq 0) {
            Write-Log "Cline extension installed successfully"
        } else {
            Write-Log "Cline extension installation returned code: $($Process.ExitCode)" "WARN"
        }
    } catch {
        Write-Log "Failed to install Cline extension: $_" "ERROR"
    }
} else {
    Write-Log "Cline extension installation is disabled in config"
}

# 3. Install LM Studio
if ($Config.components.lmstudio.enabled) {
    Write-Log "=== Installing LM Studio ==="
    
    $LMStudioPath = [Environment]::ExpandEnvironmentVariables($Config.components.lmstudio.installPath)
    
    if (Test-SoftwareInstalled "LM Studio" "$LMStudioPath\LM Studio.exe") {
        Write-Log "LM Studio already installed, skipping..."
    } else {
        $LMStudioInstaller = Join-Path $TempDir "LMStudioSetup.exe"
        
        if (Download-File -Url $Config.components.lmstudio.downloadUrl -OutputPath $LMStudioInstaller -Description "LM Studio") {
            Write-Log "Installing LM Studio..."
            
            # LM Studio installer is NSIS-based, use silent install
            $Process = Start-Process -FilePath $LMStudioInstaller `
                -ArgumentList "/S" `
                -Wait -PassThru -NoNewWindow
            
            if ($Process.ExitCode -eq 0) {
                Write-Log "LM Studio installation completed"
            } else {
                Write-Log "LM Studio installation returned code: $($Process.ExitCode)" "WARN"
            }
        } else {
            Write-Log "Failed to download LM Studio" "ERROR"
        }
    }
} else {
    Write-Log "LM Studio installation is disabled in config"
}

# 4. Download AI Model
if ($Config.components.model.enabled -and -not $SkipModelDownload) {
    Write-Log "=== Downloading AI Model ==="
    
    $ModelDir = "$env:USERPROFILE\.cache\lm-studio\models\$($Config.components.model.huggingfaceRepo)"
    if (-not (Test-Path $ModelDir)) {
        New-Item -ItemType Directory -Path $ModelDir -Force | Out-Null
        Write-Log "Created model directory: $ModelDir"
    }
    
    $ModelPath = Join-Path $ModelDir $Config.components.model.filename
    
    if (Test-Path $ModelPath) {
        Write-Log "Model already downloaded: $ModelPath"
    } else {
        Write-Log "Downloading model: $($Config.components.model.name) (Size: $($Config.components.model.size))"
        Write-Host "Model download may take 15-30 minutes depending on your connection..."
        
        if (Download-File -Url $Config.components.model.downloadUrl -OutputPath $ModelPath -Description "AI Model") {
            Write-Log "Model downloaded successfully: $ModelPath"
        } else {
            Write-Log "Failed to download model. You can download it manually in LM Studio." "WARN"
        }
    }
} else {
    if ($SkipModelDownload) {
        Write-Log "Model download skipped by user"
    } else {
        Write-Log "Model download is disabled in config"
    }
}

# 5. Configure Cline to use LM Studio
Write-Log "=== Configuring Cline ==="

$VSCodeSettingsPath = "$env:APPDATA\Code\User"
if (-not (Test-Path $VSCodeSettingsPath)) {
    New-Item -ItemType Directory -Path $VSCodeSettingsPath -Force | Out-Null
    Write-Log "Created VS Code settings directory"
}

$SettingsFile = Join-Path $VSCodeSettingsPath "settings.json"

# Read existing settings or create new
$Settings = @{}
if (Test-Path $SettingsFile) {
    try {
        $Settings = Get-Content -Path $SettingsFile -Raw | ConvertFrom-Json -AsHashtable
        Write-Log "Loaded existing VS Code settings"
    } catch {
        Write-Log "Could not parse existing settings, creating new" "WARN"
        $Settings = @{}
    }
}

# Add/Update Cline configuration
$ClineConfig = $Config.clineConfig
$Settings["cline.apiProvider"] = $ClineConfig.apiProvider
$Settings["cline.lmstudioUrl"] = $ClineConfig.lmstudioUrl
$Settings["cline.modelId"] = $ClineConfig.modelName
$Settings["cline.temperature"] = $ClineConfig.temperature
$Settings["cline.maxTokens"] = $ClineConfig.maxTokens

# Save settings
try {
    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsFile -Encoding UTF8
    Write-Log "Cline configuration saved to: $SettingsFile"
} catch {
    Write-Log "Failed to save Cline configuration: $_" "ERROR"
}

# Create desktop shortcut for VS Code (optional)
if ($Config.installer.createDesktopShortcut) {
    Write-Log "Creating desktop shortcut..."
    
    $WScriptShell = New-Object -ComObject WScript.Shell
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $ShortcutPath = Join-Path $DesktopPath "VS Code (Local Vibe).lnk"
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    
    $VSCodePath = [Environment]::ExpandEnvironmentVariables($Config.components.vscode.installPath)
    $Shortcut.TargetPath = "$VSCodePath\Code.exe"
    $Shortcut.Description = "VS Code with Local AI Assistant"
    $Shortcut.Save()
    
    Write-Log "Desktop shortcut created: $ShortcutPath"
}

# Cleanup temp files (optional)
Write-Log "Cleaning up temporary files..."
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Temporary files cleaned up"
} catch {
    Write-Log "Could not clean up all temporary files" "WARN"
}

# Final instructions
Write-Log "=== Installation Complete ==="
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Local Vibe Coding Stack Installed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Launch LM Studio and start the server (http://localhost:1234)"
Write-Host "2. Load your model in LM Studio: $($Config.components.model.name)"
Write-Host "3. Open VS Code"
Write-Host "4. Press Ctrl+Shift+P and type 'Cline' to start"
Write-Host ""
Write-Host "Installation log saved to: $LogFile" -ForegroundColor Yellow
Write-Host ""

Write-Log "Installation script completed successfully"

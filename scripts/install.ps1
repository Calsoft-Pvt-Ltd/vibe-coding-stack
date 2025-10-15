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

$TotalSteps = 6

function Start-Step {
    param(
        [int]$Number,
        [string]$Title
    )

    $Message = "[Step $Number/$TotalSteps] $Title"
    Write-Log $Message
    $Message | Set-Content -Path "$LogFile.step" -Encoding UTF8
}

function Complete-Step {
    param(
        [int]$Number,
        [string]$Title,
        [string]$Status = "Completed"
    )

    $Message = "[Step $Number/$TotalSteps] $Title - $Status"
    Write-Log $Message
    $Message | Set-Content -Path "$LogFile.step" -Encoding UTF8
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
        Write-Log "Failed to download ${Description}: $_" "ERROR"
        return $false
    }
}

# Function to update Cline settings in VS Code SQLite database
function Update-ClineSettings {
    param(
        [string]$StateDbPath,
        [hashtable]$LmStudioConfig
    )
    
    try {
        # Try to load System.Data.SQLite
        try {
            Add-Type -AssemblyName "System.Data.SQLite" -ErrorAction Stop
            Write-Log "Using System.Data.SQLite assembly"
        } catch {
            Write-Log "System.Data.SQLite not available" "ERROR"
            Write-Log "Please ensure .NET Framework or System.Data.SQLite is installed" "ERROR"
            return $false
        }
        
        # Connect to database
        $ConnectionString = "Data Source=$StateDbPath;Version=3;"
        $Connection = New-Object System.Data.SQLite.SQLiteConnection($ConnectionString)
        $Connection.Open()
        Write-Log "Connected to VS Code state database"
        
        # Read existing Cline configuration
        $ReadCommand = $Connection.CreateCommand()
        $ReadCommand.CommandText = "SELECT value FROM ItemTable WHERE key = 'saoudrizwan.claude-dev'"
        $ExistingValue = $ReadCommand.ExecuteScalar()
        
        $ClineSettings = @{}
        
        if ($null -eq $ExistingValue) {
            Write-Log "No existing Cline configuration found, creating new entry"
            # Create default structure
            $ClineSettings = @{
                actModeApiProvider = "lmstudio"
                planModeApiProvider = "lmstudio"
                actModeLmStudioModelId = $LmStudioConfig.modelId
                planModeLmStudioModelId = $LmStudioConfig.modelId
                lmStudioBaseUrl = $LmStudioConfig.baseUrl
                lmStudioMaxTokens = $LmStudioConfig.maxTokens
            }
        } else {
            Write-Log "Found existing Cline configuration, updating LM Studio fields"
            
            # Parse existing JSON
            try {
                $ExistingJson = $ExistingValue | ConvertFrom-Json -AsHashtable
                $ClineSettings = $ExistingJson
                Write-Log "Successfully parsed existing Cline configuration"
            } catch {
                Write-Log "Could not parse existing configuration, creating new" "WARN"
                $ClineSettings = @{}
            }
            
            # Update only LM Studio related fields
            $ClineSettings["actModeApiProvider"] = "lmstudio"
            $ClineSettings["planModeApiProvider"] = "lmstudio"
            $ClineSettings["actModeLmStudioModelId"] = $LmStudioConfig.modelId
            $ClineSettings["planModeLmStudioModelId"] = $LmStudioConfig.modelId
            $ClineSettings["lmStudioBaseUrl"] = $LmStudioConfig.baseUrl
            $ClineSettings["lmStudioMaxTokens"] = $LmStudioConfig.maxTokens
            
            Write-Log "Updated Cline configuration with LM Studio settings:"
            Write-Log "  - API Provider: lmstudio"
            Write-Log "  - Model ID: $($LmStudioConfig.modelId)"
            Write-Log "  - Base URL: $($LmStudioConfig.baseUrl)"
            Write-Log "  - Max Tokens: $($LmStudioConfig.maxTokens)"
        }
        
        # Convert back to JSON
        $UpdatedJson = $ClineSettings | ConvertTo-Json -Compress -Depth 10
        
        # Save to database using INSERT OR REPLACE
        $UpdateCommand = $Connection.CreateCommand()
        $UpdateCommand.CommandText = "INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('saoudrizwan.claude-dev', @value)"
        $UpdateCommand.Parameters.AddWithValue("@value", $UpdatedJson) | Out-Null
        $RowsAffected = $UpdateCommand.ExecuteNonQuery()
        
        $Connection.Close()
        
        if ($RowsAffected -gt 0) {
            Write-Log "Cline settings updated successfully in database"
            return $true
        } else {
            Write-Log "No rows were updated in database" "WARN"
            return $false
        }
        
    } catch {
        Write-Log "Failed to update Cline settings: $_" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
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
$StepNumber = 1
$StepTitle = "Install VS Code"
Start-Step -Number $StepNumber -Title $StepTitle
if ($Config.components.vscode.enabled) {
    Write-Log "=== Installing VS Code ==="
    
    $VSCodePath = [Environment]::ExpandEnvironmentVariables($Config.components.vscode.installPath)
    
    if (Test-SoftwareInstalled "VS Code" "$VSCodePath\Code.exe") {
        Write-Log "VS Code already installed, skipping..."
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Already installed"
    } else {
        $VSCodeInstaller = Join-Path $TempDir "VSCodeSetup.exe"
        
        if (Download-File -Url $Config.components.vscode.downloadUrl -OutputPath $VSCodeInstaller -Description "VS Code") {
            Write-Log "Installing VS Code (EXE installer)..."
            Write-Log "Running: `"$VSCodeInstaller`" /VERYSILENT /NORESTART /MERGETASKS=!runcode"
            
            # VS Code user installer supports these silent install parameters
            $InstallArgs = @(
                "/VERYSILENT"           # Run installer silently
                "/NORESTART"            # Don't restart after installation
                "/MERGETASKS=!runcode"  # Don't launch VS Code after install
                "/SUPPRESSMSGBOXES"     # Suppress message boxes
            )
            
            $Process = Start-Process -FilePath $VSCodeInstaller -ArgumentList $InstallArgs -Wait -NoNewWindow -PassThru
            
            if ($Process.ExitCode -eq 0) {
                Write-Log "VS Code installation completed successfully"
            } else {
                Write-Log "VS Code installation returned exit code: $($Process.ExitCode)" "WARN"
                Write-Log "Installation may have encountered issues. Common causes:"
                Write-Log "  - Installer file corrupted or incomplete download"
                Write-Log "  - Insufficient permissions"
                Write-Log "  - Another installation in progress"
                Write-Log "  - Antivirus blocking the installer"
            }
            
            Write-Log "VS Code installation process finished"
            
            # Wait for VS Code installation to fully complete and files to be written
            Write-Log "Waiting for VS Code to be fully installed..."
            $MaxRetries = 30
            $RetryCount = 0
            $VSCodeReady = $false
            
            while (-not $VSCodeReady -and $RetryCount -lt $MaxRetries) {
                Start-Sleep -Seconds 2
                if ((Test-Path "$VSCodePath\Code.exe") -and (Test-Path "$VSCodePath\bin\code.cmd")) {
                    $VSCodeReady = $true
                    Write-Log "VS Code binaries found and ready"
                } else {
                    $RetryCount++
                    Write-Log "Waiting for VS Code files... ($RetryCount/$MaxRetries)"
                }
            }
            
            if (-not $VSCodeReady) {
                Write-Log "VS Code installation may not have completed successfully" "WARN"
            }
            
            # Add to PATH
            $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
            $CodePath = "$VSCodePath\bin"
            if ($UserPath -notlike "*$CodePath*") {
                [Environment]::SetEnvironmentVariable("Path", "$UserPath;$CodePath", "User")
                Write-Log "Added VS Code to PATH"
                
                # Refresh PATH in current session
                $env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + [Environment]::GetEnvironmentVariable("Path", "Machine")
                Write-Log "Refreshed PATH in current session"
            }

            Complete-Step -Number $StepNumber -Title $StepTitle
        } else {
            $Message = "Failed to download VS Code"
            Write-Log $Message "ERROR"
            Complete-Step -Number $StepNumber -Title $StepTitle -Status "Failed: Download error"
        }
    }
} else {
    Write-Log "VS Code installation is disabled in config"
    Complete-Step -Number $StepNumber -Title $StepTitle -Status "Skipped"
}

# 2. Install Cline Extension
$StepNumber = 2
$StepTitle = "Install Cline extension"
Start-Step -Number $StepNumber -Title $StepTitle
if ($Config.components.cline.enabled) {
    Write-Log "=== Installing Cline Extension ==="
    
    $VSCodePath = [Environment]::ExpandEnvironmentVariables($Config.components.vscode.installPath)
    $CodeExe = "$VSCodePath\bin\code.cmd"
    
    # Verify VS Code is installed and accessible
    if (-not (Test-Path $CodeExe)) {
        Write-Log "code.cmd not found at: $CodeExe" "WARN"
        Write-Log "Searching for VS Code in PATH..."
        
        # Try to find code in PATH
        $CodeInPath = Get-Command "code" -ErrorAction SilentlyContinue
        if ($CodeInPath) {
            $CodeExe = $CodeInPath.Source
            Write-Log "Found code at: $CodeExe"
        } else {
            Write-Log "VS Code not found in PATH. Trying direct path..." "WARN"
            # Last resort: use full path to code.exe
            $CodeExe = "$VSCodePath\bin\code.cmd"
        }
    }
    
    Write-Log "Using VS Code at: $CodeExe"
    
    try {
        Write-Log "Installing Cline extension: $($Config.components.cline.extensionId)"
        
        # Verify code.cmd exists
        if (-not (Test-Path $CodeExe)) {
            throw "VS Code executable not found at $CodeExe. Please ensure VS Code is installed correctly."
        }
        
        # Install extension
        $Process = Start-Process -FilePath $CodeExe `
            -ArgumentList "--install-extension", $Config.components.cline.extensionId, "--force" `
            -NoNewWindow -Wait -PassThru
        
        if ($Process.ExitCode -eq 0) {
            Write-Log "Cline extension installed successfully"
            Complete-Step -Number $StepNumber -Title $StepTitle
        } else {
            $Status = "Exit code $($Process.ExitCode)"
            Write-Log "Cline extension installation returned code: $($Process.ExitCode)" "WARN"
            Complete-Step -Number $StepNumber -Title $StepTitle -Status "Completed with warning: $Status"
        }
    } catch {
        Write-Log "Failed to install Cline extension: $_" "ERROR"
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Failed: $($_.Exception.Message)"
    }
} else {
    Write-Log "Cline extension installation is disabled in config"
    Complete-Step -Number $StepNumber -Title $StepTitle -Status "Skipped"
}

# 3. Install LM Studio
$StepNumber = 3
$StepTitle = "Install LM Studio"
Start-Step -Number $StepNumber -Title $StepTitle
if ($Config.components.lmstudio.enabled) {
    Write-Log "=== Installing LM Studio ==="
    
    $LMStudioPath = [Environment]::ExpandEnvironmentVariables($Config.components.lmstudio.installPath)
    
    if (Test-SoftwareInstalled "LM Studio" "$LMStudioPath\LM Studio.exe") {
        Write-Log "LM Studio already installed, skipping..."
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Already installed"
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
                Complete-Step -Number $StepNumber -Title $StepTitle
            } else {
                Write-Log "LM Studio installation returned code: $($Process.ExitCode)" "WARN"
                Complete-Step -Number $StepNumber -Title $StepTitle -Status "Completed with warning: Exit code $($Process.ExitCode)"
            }
        } else {
            Write-Log "Failed to download LM Studio" "ERROR"
            Complete-Step -Number $StepNumber -Title $StepTitle -Status "Failed: Download error"
        }
    }
} else {
    Write-Log "LM Studio installation is disabled in config"
    Complete-Step -Number $StepNumber -Title $StepTitle -Status "Skipped"
}

# 4. Download AI Model
$StepNumber = 4
$StepTitle = "Download AI model"
Start-Step -Number $StepNumber -Title $StepTitle
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
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Already present"
    } else {
        Write-Log "Downloading model: $($Config.components.model.name) (Size: $($Config.components.model.size))"
        Write-Host "Model download may take 15-30 minutes depending on your connection..."
        
        if (Download-File -Url $Config.components.model.downloadUrl -OutputPath $ModelPath -Description "AI Model") {
            Write-Log "Model downloaded successfully: $ModelPath"
            Complete-Step -Number $StepNumber -Title $StepTitle
        } else {
            Write-Log "Failed to download model. You can download it manually in LM Studio." "WARN"
            Complete-Step -Number $StepNumber -Title $StepTitle -Status "Failed: Download error"
        }
    }
} else {
    if ($SkipModelDownload) {
        Write-Log "Model download skipped by user"
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Skipped by user"
    } else {
        Write-Log "Model download is disabled in config"
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Skipped"
    }
}

# 5. Configure Cline to use LM Studio
$StepNumber = 5
$StepTitle = "Configure Cline settings"
Start-Step -Number $StepNumber -Title $StepTitle
Write-Log "=== Configuring Cline ==="

try {
    # VS Code stores extension state in SQLite database
    $VSCodeGlobalStatePath = "$env:APPDATA\Code\User\globalStorage"
    $StateDbPath = Join-Path $VSCodeGlobalStatePath "state.vscdb"
    
    if (-not (Test-Path $StateDbPath)) {
        Write-Log "VS Code state database not found at: $StateDbPath" "WARN"
        Write-Log "Database will be created when VS Code first runs with Cline extension"
        Write-Log "Skipping Cline configuration - you'll need to configure it manually in VS Code"
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Skipped: Database not found"
    } else {
        Write-Log "Found VS Code state database: $StateDbPath"
        
        # Prepare LM Studio configuration
        $ClineConfig = $Config.clineConfig
        $LmStudioConfig = @{
            modelId = $ClineConfig.modelName
            baseUrl = $ClineConfig.lmstudioUrl
            maxTokens = $ClineConfig.maxTokens
        }
        
        Write-Log "LM Studio configuration:"
        Write-Log "  - Model: $($LmStudioConfig.modelId)"
        Write-Log "  - Base URL: $($LmStudioConfig.baseUrl)"
        Write-Log "  - Max Tokens: $($LmStudioConfig.maxTokens)"
        
        # Update Cline settings in database
        $UpdateResult = Update-ClineSettings -StateDbPath $StateDbPath -LmStudioConfig $LmStudioConfig
        
        if ($UpdateResult) {
            Write-Log "Cline configuration saved successfully"
            Complete-Step -Number $StepNumber -Title $StepTitle
        } else {
            Write-Log "Failed to save Cline configuration automatically" "WARN"
            Write-Log "You will need to configure Cline manually in VS Code" "WARN"
            Complete-Step -Number $StepNumber -Title $StepTitle -Status "Completed with warning: Manual config needed"
        }
    }
} catch {
    Write-Log "Failed to configure Cline: $_" "ERROR"
    Write-Log "Error details: $($_.Exception.Message)" "ERROR"
    Write-Log "You will need to configure Cline manually in VS Code"
    Complete-Step -Number $StepNumber -Title $StepTitle -Status "Failed: $($_.Exception.Message)"
}

# 6. Create shortcuts (optional)
$StepNumber = 6
$StepTitle = "Create desktop shortcut"
Start-Step -Number $StepNumber -Title $StepTitle
if ($Config.installer.createDesktopShortcut) {
    Write-Log "Creating desktop shortcut..."
    
    try {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $DesktopPath = [Environment]::GetFolderPath("Desktop")
        $ShortcutPath = Join-Path $DesktopPath "VS Code (Local Vibe).lnk"
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
        
        $VSCodePath = [Environment]::ExpandEnvironmentVariables($Config.components.vscode.installPath)
        $Shortcut.TargetPath = "$VSCodePath\Code.exe"
        $Shortcut.Description = "VS Code with Local AI Assistant"
        $Shortcut.Save()
        
        Write-Log "Desktop shortcut created: $ShortcutPath"
        Complete-Step -Number $StepNumber -Title $StepTitle
    } catch {
        Write-Log "Failed to create desktop shortcut: $_" "WARN"
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Completed with warning"
    }
} else {
    Write-Log "Desktop shortcut creation disabled in config"
    Complete-Step -Number $StepNumber -Title $StepTitle -Status "Skipped"
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

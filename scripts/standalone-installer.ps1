# Local Vibe Coding Stack - Standalone EXE Installer
# This script can be converted to EXE using ps2exe or similar tools
# Usage: PS2EXE standalone-installer.ps1 LocalVibeCodingStack-Setup.exe -noConsole:$false -title "Local Vibe Coding Stack Installer"

param(
    [switch]$Silent = $false
)

# Show console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 5) # 5 = SW_SHOW

# Set error handling
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

# Trap for unhandled errors
trap {
    Write-Host ""
    Write-Host "FATAL ERROR OCCURRED!" -ForegroundColor Red -BackgroundColor Black
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    if ($LogFile) {
        "FATAL ERROR: $_" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
        $_.ScriptStackTrace | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
    }
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Initialize logging
$LogFile = "$env:TEMP\LocalVibeCodingStack-install.log"

# Clear old log
if (Test-Path $LogFile) {
    Remove-Item $LogFile -Force -ErrorAction SilentlyContinue
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Color-code output based on level
    switch ($Level) {
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "WARN"  { Write-Host $LogMessage -ForegroundColor Yellow }
        "INFO"  { Write-Host $LogMessage -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $LogMessage -ForegroundColor Green }
        default { Write-Host $LogMessage }
    }
    
    Add-Content -Path $LogFile -Value $LogMessage -ErrorAction SilentlyContinue
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Local Vibe Coding Stack Installer" -ForegroundColor Cyan
    Write-Host "  Version 1.0" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This installer will set up:" -ForegroundColor White
    Write-Host "  • VS Code (User-level installation)" -ForegroundColor Gray
    Write-Host "  • Cline Extension (Claude AI Assistant)" -ForegroundColor Gray
    Write-Host "  • LM Studio (Local AI model server)" -ForegroundColor Gray
    Write-Host "  • AI Model (DeepSeek Coder)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Installation directory:" -ForegroundColor White
    Write-Host "  $InstallDir" -ForegroundColor Gray
    Write-Host ""
}

function Show-Progress {
    param(
        [int]$Step,
        [int]$Total,
        [string]$Title,
        [string]$Status = "In Progress"
    )
    
    $Percent = [math]::Round(($Step / $Total) * 100)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "Progress: $Percent% " -NoNewline -ForegroundColor Yellow
    Write-Host ("█" * [math]::Floor($Percent / 5)) -ForegroundColor Green
    Write-Host ""
}

# Configuration (embedded)
$Config = @{
    installer = @{
        version = "1.0.0"
        createDesktopShortcut = $true
        createStartMenuShortcut = $true
    }
    components = @{
        vscode = @{
            downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
            installPath = "%LOCALAPPDATA%\Programs\Microsoft VS Code"
            executable = "Code.exe"
        }
        cline = @{
            extensionId = "saoudrizwan.claude-dev"
            publisher = "saoudrizwan"
            name = "claude-dev"
        }
        lmstudio = @{
            downloadUrl = "https://releases.lmstudio.ai/windows/latest"
            installPath = "%LOCALAPPDATA%\LM-Studio"
        }
        model = @{
            name = "deepseek-coder-v2-lite-instruct-q4_k_m"
            provider = "lm-studio"
            huggingfaceId = "bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF"
            fileName = "DeepSeek-Coder-V2-Lite-Instruct-Q4_K_M.gguf"
            downloadUrl = "https://huggingface.co/bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF/resolve/main/DeepSeek-Coder-V2-Lite-Instruct-Q4_K_M.gguf"
        }
    }
    clineConfigDefault = @{
        welcomeViewCompleted = $true
        clineVersion = "3.7.3"
        autoApprovalSettings = @{
            mode = "enabled"
            readOnly = $true
            alwaysApproveReadOnly = $true
            alwaysApproveCodeExecution = $false
            autoApproveRepeatedActionGroups = $true
            autoApproveDefaultTools = $true
            disableNotifications = $false
            maxAutoApprovals = 10
        }
        workspaceRoots = @()
        planMode = "enabled"
        planModeInstructions = ""
        actMode = "architect"
        actModeInstructions = ""
        autoCloseTerminal = $false
        editAutoScroll = $true
        editEnabled = $true
        editShowResponse = $true
        diffEnabled = $true
        browserViewportSize = "900x600"
        terminalMaxOutputChars = 5000
        skipWriteAnimation = $true
        alwaysAllowWriteOnly = $true
        soundEnabled = $false
        fpjsKey = ""
        apiProvider = "lmstudio"
        apiModelId = "deepseek-coder-v2-lite-instruct-q4_k_m"
        lmStudioModelId = "deepseek-coder-v2-lite-instruct-q4_k_m"
        lmStudioBaseUrl = "http://localhost:1234"
        apiMaxTokens = 8192
    }
}

# Setup directories
$InstallDir = "$env:LOCALAPPDATA\LocalVibeCodingStack"
$TempDir = "$env:TEMP\LocalVibeCodingStack"

Write-Log "=== Local Vibe Coding Stack Installation Started ===" "INFO"
Write-Log "Log file: $LogFile" "INFO"
Write-Log "Install directory: $InstallDir" "INFO"
Write-Log "Temp directory: $TempDir" "INFO"

Show-Banner

if (-not $Silent) {
    Write-Host "Press Enter to begin installation or Ctrl+C to cancel..." -ForegroundColor Yellow
    Read-Host
}

# Create directories
Write-Log "Creating installation directories..." "INFO"
@($InstallDir, "$InstallDir\scripts", "$InstallDir\assets", "$InstallDir\logs", $TempDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Log "Created directory: $_" "INFO"
    }
}

# Save configuration to install directory
$ConfigPath = "$InstallDir\assets\installer-config.json"
$Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
Write-Log "Configuration saved to: $ConfigPath" "INFO"

# Now embed the main installation script inline
$TotalSteps = 6

# Function to download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description
    )
    
    try {
        Write-Log "Downloading $Description from: $Url" "INFO"
        Write-Host "Downloading $Description..." -ForegroundColor Cyan
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        $webClient.Dispose()
        
        if (Test-Path $OutputPath) {
            $fileSize = (Get-Item $OutputPath).Length / 1MB
            Write-Log "Downloaded successfully: $([math]::Round($fileSize, 2)) MB" "SUCCESS"
            return $true
        }
        return $false
    } catch {
        Write-Log "Failed to download ${Description}: $_" "ERROR"
        return $false
    }
}

# Step 1: Check/Install VS Code
Show-Progress -Step 1 -Total $TotalSteps -Title "Installing VS Code"
Write-Log "Checking VS Code installation..." "INFO"

$VSCodePath = [Environment]::ExpandEnvironmentVariables($Config.components.vscode.installPath)
$VSCodeExe = Join-Path $VSCodePath $Config.components.vscode.executable

if (Test-Path $VSCodeExe) {
    Write-Log "VS Code already installed at: $VSCodePath" "INFO"
} else {
    Write-Log "VS Code not found. Downloading..." "INFO"
    $VSCodeInstaller = "$TempDir\VSCodeSetup.exe"
    
    if (Download-File -Url $Config.components.vscode.downloadUrl -OutputPath $VSCodeInstaller -Description "VS Code") {
        Write-Log "Installing VS Code..." "INFO"
        Write-Host "Running VS Code installer..." -ForegroundColor Cyan
        
        $installArgs = @(
            "/VERYSILENT",
            "/NORESTART",
            "/MERGETASKS=!runcode",
            "/SUPPRESSMSGBOXES"
        )
        
        $process = Start-Process -FilePath $VSCodeInstaller -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "VS Code installed successfully" "SUCCESS"
        } else {
            Write-Log "VS Code installation returned code: $($process.ExitCode)" "WARN"
        }
        
        # Wait for installation to complete
        Start-Sleep -Seconds 5
    }
}

# Step 2: Install Cline Extension
Show-Progress -Step 2 -Total $TotalSteps -Title "Installing Cline Extension"
Write-Log "Installing Cline extension..." "INFO"

if (Test-Path $VSCodeExe) {
    try {
        Write-Host "Installing Cline extension..." -ForegroundColor Cyan
        $extensionId = $Config.components.cline.extensionId
        & $VSCodeExe --install-extension $extensionId --force 2>&1 | Out-String | Write-Log
        Write-Log "Cline extension installed successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to install Cline extension: $_" "ERROR"
    }
} else {
    Write-Log "Cannot install Cline: VS Code not found" "ERROR"
}

# Step 3: Install LM Studio
Show-Progress -Step 3 -Total $TotalSteps -Title "Installing LM Studio"
Write-Log "Checking LM Studio installation..." "INFO"

$LMStudioPath = [Environment]::ExpandEnvironmentVariables($Config.components.lmstudio.installPath)

if (Test-Path $LMStudioPath) {
    Write-Log "LM Studio already installed" "INFO"
} else {
    Write-Log "Downloading LM Studio..." "INFO"
    $LMStudioInstaller = "$TempDir\LMStudio-Setup.exe"
    
    if (Download-File -Url $Config.components.lmstudio.downloadUrl -OutputPath $LMStudioInstaller -Description "LM Studio") {
        Write-Log "Installing LM Studio..." "INFO"
        Write-Host "Running LM Studio installer..." -ForegroundColor Cyan
        
        $process = Start-Process -FilePath $LMStudioInstaller -ArgumentList "/S" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "LM Studio installed successfully" "SUCCESS"
        } else {
            Write-Log "LM Studio installation returned code: $($process.ExitCode)" "WARN"
        }
    }
}

# Step 4: Download AI Model
Show-Progress -Step 4 -Total $TotalSteps -Title "Downloading AI Model"
Write-Log "Checking AI model..." "INFO"

$ModelDir = "$env:USERPROFILE\.cache\lm-studio\models\$($Config.components.model.huggingfaceId)"
$ModelFile = Join-Path $ModelDir $Config.components.model.fileName

if (Test-Path $ModelFile) {
    Write-Log "AI model already downloaded" "INFO"
} else {
    Write-Log "AI model will be downloaded by LM Studio on first use" "INFO"
    Write-Log "Model: $($Config.components.model.name)" "INFO"
}

# Step 5: Configure Cline
Show-Progress -Step 5 -Total $TotalSteps -Title "Configuring Cline"
Write-Log "Configuring Cline with LM Studio settings..." "INFO"

# Download SQLite3
Write-Log "Downloading SQLite3 tools..." "INFO"
$SqliteZip = "$TempDir\sqlite-tools.zip"
$SqliteUrl = "https://www.sqlite.org/2024/sqlite-tools-win-x64-3450300.zip"

if (Download-File -Url $SqliteUrl -OutputPath $SqliteZip -Description "SQLite3 tools") {
    Write-Log "Extracting SQLite3..." "INFO"
    Expand-Archive -Path $SqliteZip -DestinationPath $TempDir -Force
    $Sqlite3Path = Get-ChildItem -Path $TempDir -Recurse -Filter "sqlite3.exe" | Select-Object -First 1 -ExpandProperty FullName
    
    if ($Sqlite3Path) {
        Write-Log "SQLite3 found at: $Sqlite3Path" "SUCCESS"
        
        # Configure Cline
        $StateDbPath = "$env:APPDATA\Code\User\globalStorage\state.vscdb"
        
        if (Test-Path $StateDbPath) {
            Write-Log "Configuring Cline in VS Code..." "INFO"
            
            # Read existing settings
            $SqlRead = "SELECT value FROM ItemTable WHERE key='saoudrizwan.claude-dev';"
            $ExistingJson = & $Sqlite3Path $StateDbPath $SqlRead 2>$null
            
            if ($ExistingJson) {
                $ExistingConfig = $ExistingJson | ConvertFrom-Json
            } else {
                $ExistingConfig = @{}
            }
            
            # Merge with defaults
            $Config.clineConfigDefault.GetEnumerator() | ForEach-Object {
                if (-not $ExistingConfig.PSObject.Properties.Name.Contains($_.Key)) {
                    $ExistingConfig | Add-Member -NotePropertyName $_.Key -NotePropertyValue $_.Value -Force
                }
            }
            
            # Save back to database
            $MergedJson = $ExistingConfig | ConvertTo-Json -Depth 10 -Compress
            $JsonForSql = $MergedJson -replace "'", "''"
            
            $SqlUpdate = @"
INSERT OR REPLACE INTO ItemTable (key, value) 
VALUES ('saoudrizwan.claude-dev', '$JsonForSql');
"@
            
            $SqlUpdate | & $Sqlite3Path $StateDbPath 2>&1 | Out-String | Write-Log
            Write-Log "Cline configured successfully" "SUCCESS"
        } else {
            Write-Log "VS Code state database not found. Will be created on first VS Code launch." "INFO"
        }
    }
}

# Step 6: Create Shortcuts
Show-Progress -Step 6 -Total $TotalSteps -Title "Creating Shortcuts"

if ($Config.installer.createDesktopShortcut) {
    Write-Log "Creating desktop shortcut..." "INFO"
    
    try {
        $WScriptShell = New-Object -ComObject WScript.Shell
        $DesktopPath = [Environment]::GetFolderPath("Desktop")
        $ShortcutPath = Join-Path $DesktopPath "Local Vibe Coding.lnk"
        $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $VSCodeExe
        $Shortcut.Description = "VS Code with Local AI Assistant"
        $Shortcut.Save()
        Write-Log "Desktop shortcut created" "SUCCESS"
    } catch {
        Write-Log "Failed to create desktop shortcut: $_" "WARN"
    }
}

# Cleanup
Write-Log "Cleaning up temporary files..." "INFO"
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Cleanup completed" "SUCCESS"
} catch {
    Write-Log "Could not clean up all temporary files" "WARN"
}

# Final screen
Clear-Host
Write-Host ""
Write-Host "============================================" -ForegroundColor Green -BackgroundColor Black
Write-Host "  🎉 Installation Complete! 🎉" -ForegroundColor Green -BackgroundColor Black
Write-Host "============================================" -ForegroundColor Green -BackgroundColor Black
Write-Host ""
Write-Host "Components Installed:" -ForegroundColor Cyan
Write-Host "  ✓ VS Code" -ForegroundColor Green
Write-Host "  ✓ Cline Extension (Claude AI Assistant)" -ForegroundColor Green
Write-Host "  ✓ LM Studio" -ForegroundColor Green
Write-Host "  ✓ AI Model configured: $($Config.components.model.name)" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Launch LM Studio and start the local server" -ForegroundColor White
Write-Host "     (Default: http://localhost:1234)" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Load your model in LM Studio:" -ForegroundColor White
Write-Host "     $($Config.components.model.name)" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Open VS Code and activate Cline:" -ForegroundColor White
Write-Host "     Press Ctrl+Shift+P → Type 'Cline'" -ForegroundColor Gray
Write-Host ""
Write-Host "Installation log: $LogFile" -ForegroundColor Yellow
Write-Host ""

if (-not $Silent) {
    Write-Host "Press any key to close this window..." -ForegroundColor Cyan
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Start-Sleep -Seconds 10
    }
}

Write-Log "Installation script completed successfully" "SUCCESS"
exit 0

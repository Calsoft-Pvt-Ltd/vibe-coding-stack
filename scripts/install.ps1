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

# Function to install SQLite3 CLI tool
function Install-SQLite3 {
    param(
        [string]$TempDir
    )
    
    try {
        Write-Log "=== Installing SQLite3 CLI Tool ==="
        Write-Log "This method avoids .NET dependencies completely"
        
        # Determine architecture
        if ([Environment]::Is64BitOperatingSystem) {
            $Architecture = "x64"
            $SqliteZipUrl = "https://www.sqlite.org/2024/sqlite-tools-win-x64-3450300.zip"
        } else {
            $Architecture = "x86"
            $SqliteZipUrl = "https://www.sqlite.org/2024/sqlite-tools-win32-x86-3450300.zip"
        }
        
        Write-Log "Detected OS architecture: $Architecture"
        Write-Log "SQLite3 download URL: $SqliteZipUrl"
        
        $SqliteZip = Join-Path $TempDir "sqlite-tools.zip"
        $SqliteExtractPath = Join-Path $TempDir "sqlite3"
        
        Write-Log "Download target: $SqliteZip"
        Write-Log "Extract target: $SqliteExtractPath"
        
        # Download SQLite tools
        Write-Log "Downloading SQLite3 tools..."
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($SqliteZipUrl, $SqliteZip)
        
        if (Test-Path $SqliteZip) {
            $FileSize = (Get-Item $SqliteZip).Length
            Write-Log "Downloaded SQLite3 tools successfully ($FileSize bytes)"
        } else {
            Write-Log "Download failed - file not found at $SqliteZip" "ERROR"
            return $null
        }
        
        # Extract the ZIP file
        if (Test-Path $SqliteExtractPath) {
            Write-Log "Removing existing SQLite3 directory..."
            Remove-Item -Path $SqliteExtractPath -Recurse -Force
        }
        Write-Log "Creating extract directory..."
        New-Item -ItemType Directory -Path $SqliteExtractPath -Force | Out-Null
        
        Write-Log "Extracting SQLite3 tools..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($SqliteZip, $SqliteExtractPath)
        Write-Log "Extracted SQLite3 tools successfully"
        
        # List extracted files
        $ExtractedFiles = Get-ChildItem -Path $SqliteExtractPath -Recurse -File
        Write-Log "Extracted files:"
        foreach ($File in $ExtractedFiles) {
            Write-Log "  - $($File.Name) ($($File.Length) bytes)"
        }
        
        # Find sqlite3.exe
        Write-Log "Searching for sqlite3.exe..."
        $Sqlite3Exe = Get-ChildItem -Path $SqliteExtractPath -Recurse -Filter "sqlite3.exe" | Select-Object -First 1
        
        if ($Sqlite3Exe) {
            Write-Log "SUCCESS: Found sqlite3.exe at: $($Sqlite3Exe.FullName)"
            
            # Test sqlite3.exe works
            try {
                $TestResult = & $Sqlite3Exe.FullName -version 2>&1
                Write-Log "SQLite3 version: $TestResult"
            } catch {
                Write-Log "Warning: Could not get SQLite3 version: $_" "WARN"
            }
            
            return $Sqlite3Exe.FullName
        } else {
            Write-Log "ERROR: sqlite3.exe not found in extracted files" "ERROR"
            Write-Log "Searched in: $SqliteExtractPath"
            return $null
        }
        
    } catch {
        Write-Log "Failed to install SQLite3: $_" "ERROR"
        Write-Log "Error type: $($_.Exception.GetType().FullName)" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        return $null
    }
}

# Function to install System.Data.SQLite from NuGet (Legacy fallback)
function Install-SystemDataSQLite {
    param(
        [string]$TempDir
    )
    
    try {
        Write-Log "Attempting to install System.Data.SQLite..."
        
        # Download System.Data.SQLite NuGet package
        $SqliteVersion = "1.0.118"
        $NuGetUrl = "https://www.nuget.org/api/v2/package/System.Data.SQLite.Core/$SqliteVersion"
        $NuGetZip = Join-Path $TempDir "System.Data.SQLite.zip"
        $SqliteExtractPath = Join-Path $TempDir "sqlite"
        
        Write-Log "Downloading System.Data.SQLite from NuGet..."
        Write-Log "URL: $NuGetUrl"
        Write-Log "Target: $NuGetZip"
        
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($NuGetUrl, $NuGetZip)
        
        if (Test-Path $NuGetZip) {
            $FileSize = (Get-Item $NuGetZip).Length
            Write-Log "Downloaded System.Data.SQLite package ($FileSize bytes)"
        } else {
            Write-Log "Download failed - file not found at $NuGetZip" "ERROR"
            return $false
        }
        
        # Extract the NuGet package (it's a ZIP file)
        if (Test-Path $SqliteExtractPath) {
            Remove-Item -Path $SqliteExtractPath -Recurse -Force
        }
        
        Write-Log "Extracting NuGet package to: $SqliteExtractPath"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($NuGetZip, $SqliteExtractPath)
        Write-Log "Extracted System.Data.SQLite package"
        
        # List contents to verify extraction
        $ExtractedFiles = Get-ChildItem -Path $SqliteExtractPath -Recurse -File | Select-Object -First 10
        Write-Log "Sample of extracted files:"
        foreach ($File in $ExtractedFiles) {
            Write-Log "  - $($File.FullName.Replace($SqliteExtractPath, ''))"
        }
        
        # Determine architecture
        if ([Environment]::Is64BitProcess) {
            $Architecture = "x64"
        } else {
            $Architecture = "x86"
        }
        Write-Log "Detected architecture: $Architecture"
        
        # Try multiple possible paths for the DLL (package structure varies)
        $PossibleDllPaths = @(
            "lib\net46\System.Data.SQLite.dll",
            "lib\net45\System.Data.SQLite.dll",
            "lib\net40\System.Data.SQLite.dll",
            "lib\netstandard2.0\System.Data.SQLite.dll",
            "lib\netstandard2.1\System.Data.SQLite.dll"
        )
        
        $DllPath = $null
        foreach ($RelativePath in $PossibleDllPaths) {
            $TestPath = Join-Path $SqliteExtractPath $RelativePath
            Write-Log "Checking for DLL at: $TestPath"
            if (Test-Path $TestPath) {
                $DllPath = $TestPath
                Write-Log "Found System.Data.SQLite.dll at: $DllPath"
                break
            }
        }
        
        # If still not found, search recursively
        if (-not $DllPath) {
            Write-Log "DLL not found at any expected path, searching recursively..." "WARN"
            $FoundDlls = Get-ChildItem -Path $SqliteExtractPath -Recurse -Filter "System.Data.SQLite.dll" -ErrorAction SilentlyContinue
            if ($FoundDlls) {
                Write-Log "Found System.Data.SQLite.dll at alternate location(s):"
                foreach ($Dll in $FoundDlls) {
                    Write-Log "  - $($Dll.FullName)"
                }
                $DllPath = $FoundDlls[0].FullName
                Write-Log "Using: $DllPath"
            } else {
                Write-Log "System.Data.SQLite.dll not found anywhere in package" "ERROR"
                Write-Log "This package may not contain the managed assembly" "ERROR"
                Write-Log "Trying alternative package: System.Data.SQLite (not Core)" "WARN"
                
                # Try the full package instead of Core
                $FullPackageUrl = "https://www.nuget.org/api/v2/package/System.Data.SQLite/2.0.2"
                $FullPackageZip = Join-Path $TempDir "System.Data.SQLite.Full.zip"
                $FullExtractPath = Join-Path $TempDir "sqlite-full"
                
                Write-Log "Downloading full System.Data.SQLite package..."
                $WebClient.DownloadFile($FullPackageUrl, $FullPackageZip)
                
                if (Test-Path $FullExtractPath) {
                    Remove-Item -Path $FullExtractPath -Recurse -Force
                }
                
                [System.IO.Compression.ZipFile]::ExtractToDirectory($FullPackageZip, $FullExtractPath)
                Write-Log "Extracted full package"
                
                # Search in full package
                $FoundDlls = Get-ChildItem -Path $FullExtractPath -Recurse -Filter "System.Data.SQLite.dll" -ErrorAction SilentlyContinue
                if ($FoundDlls) {
                    $DllPath = $FoundDlls[0].FullName
                    Write-Log "Found DLL in full package: $DllPath"
                    $SqliteExtractPath = $FullExtractPath
                } else {
                    Write-Log "System.Data.SQLite.dll not found in either package" "ERROR"
                    return $false
                }
            }
        }
        
        # Load the assembly
        Write-Log "Loading assembly from: $DllPath"
        [System.Reflection.Assembly]::LoadFrom($DllPath) | Out-Null
        Write-Log "Successfully loaded System.Data.SQLite from NuGet package"
        
        # Find and handle the native interop DLL
        Write-Log "Searching for native SQLite.Interop.dll..."
        
        $PossibleInteropPaths = @(
            "build\net46\$Architecture\SQLite.Interop.dll",
            "build\net45\$Architecture\SQLite.Interop.dll",
            "build\net40\$Architecture\SQLite.Interop.dll",
            "runtimes\win-$Architecture\native\SQLite.Interop.dll",
            "runtimes\win\native\SQLite.Interop.dll",
            "lib\net46\$Architecture\SQLite.Interop.dll",
            "lib\net45\$Architecture\SQLite.Interop.dll",
            "content\net46\$Architecture\SQLite.Interop.dll",
            "content\net45\$Architecture\SQLite.Interop.dll"
        )
        
        $InteropDllPath = $null
        foreach ($RelativePath in $PossibleInteropPaths) {
            $TestPath = Join-Path $SqliteExtractPath $RelativePath
            Write-Log "  Checking: $TestPath"
            if (Test-Path $TestPath) {
                $InteropDllPath = $TestPath
                Write-Log "Found native interop DLL at: $InteropDllPath"
                break
            }
        }
        
        # If not found in expected paths, do a recursive search
        if (-not $InteropDllPath) {
            Write-Log "Not found in expected paths, performing recursive search..." "WARN"
            $FoundInterop = Get-ChildItem -Path $SqliteExtractPath -Recurse -Filter "SQLite.Interop.dll" -ErrorAction SilentlyContinue
            
            if ($FoundInterop) {
                Write-Log "Found SQLite.Interop.dll at:"
                # Filter by architecture if possible
                $ArchSpecificInterop = $null
                foreach ($Interop in $FoundInterop) {
                    Write-Log "  - $($Interop.FullName)"
                    # Try to find one matching our architecture
                    if ($Interop.DirectoryName -like "*$Architecture*") {
                        $ArchSpecificInterop = $Interop
                        Write-Log "    ^ Matches architecture $Architecture"
                    }
                }
                
                # Use arch-specific if found, otherwise use first one
                if ($ArchSpecificInterop) {
                    $InteropDllPath = $ArchSpecificInterop.FullName
                    Write-Log "Using architecture-specific interop DLL: $InteropDllPath"
                } elseif ($FoundInterop.Count -gt 0) {
                    $InteropDllPath = $FoundInterop[0].FullName
                    Write-Log "Using first found interop DLL: $InteropDllPath"
                }
            }
        }
        
        # Copy the interop DLL if found
        if ($InteropDllPath -and (Test-Path $InteropDllPath)) {
            $ManagedDllDir = Split-Path $DllPath -Parent
            
            # Copy to same directory as managed DLL
            $TargetInteropPath = Join-Path $ManagedDllDir "SQLite.Interop.dll"
            Copy-Item -Path $InteropDllPath -Destination $TargetInteropPath -Force
            Write-Log "Copied native SQLite.Interop.dll to: $TargetInteropPath"
            
            # Also copy to architecture-specific subdirectory
            $ArchSubDir = Join-Path $ManagedDllDir $Architecture
            if (-not (Test-Path $ArchSubDir)) {
                New-Item -ItemType Directory -Path $ArchSubDir -Force | Out-Null
                Write-Log "Created architecture subdirectory: $ArchSubDir"
            }
            $ArchInteropPath = Join-Path $ArchSubDir "SQLite.Interop.dll"
            Copy-Item -Path $InteropDllPath -Destination $ArchInteropPath -Force
            Write-Log "Copied native DLL to architecture subdirectory: $ArchInteropPath"
            
            Write-Log "Native interop DLL setup completed successfully"
        } else {
            Write-Log "SQLite.Interop.dll not found in package" "WARN"
            Write-Log "This may indicate the package has an embedded native library" "INFO"
            Write-Log "Database operations will be attempted - they may still work" "INFO"
        }
        
        return $true
        
    } catch {
        Write-Log "Failed to install System.Data.SQLite: $_" "ERROR"
        Write-Log "Error type: $($_.Exception.GetType().FullName)" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        return $false
    }
}

# Function to update Cline settings using SQLite3 CLI
function Update-ClineSettingsWithCLI {
    param(
        [string]$StateDbPath,
        [hashtable]$LmStudioConfig,
        [string]$Sqlite3Path
    )
    
    try {
        Write-Log "Using SQLite3 CLI to update Cline settings"
        Write-Log "SQLite3 path: $Sqlite3Path"
        Write-Log "Database path: $StateDbPath"
        
        # Read existing configuration
        $ReadQuery = "SELECT value FROM ItemTable WHERE key = 'saoudrizwan.claude-dev';"
        $ReadResult = & $Sqlite3Path $StateDbPath $ReadQuery 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to read from database. Exit code: $LASTEXITCODE" "ERROR"
            Write-Log "Error output: $ReadResult" "ERROR"
            return $false
        }
        
        $ClineSettings = @{}
        
        if ($ReadResult -and $ReadResult.Trim() -ne "") {
            Write-Log "Found existing Cline configuration"
            try {
                # Parse existing JSON (compatible with PowerShell 5.1)
                $ExistingObject = $ReadResult | ConvertFrom-Json
                
                # Convert PSCustomObject to Hashtable manually (PS 5.1 compatible)
                $ClineSettings = @{}
                $ExistingObject.PSObject.Properties | ForEach-Object {
                    $ClineSettings[$_.Name] = $_.Value
                }
                
                Write-Log "Successfully parsed existing configuration"
            } catch {
                Write-Log "Could not parse existing configuration, creating new" "WARN"
                Write-Log "Parse error: $_" "WARN"
                $ClineSettings = @{}
            }
        } else {
            Write-Log "No existing Cline configuration found, creating new entry"
        }
        
        # Update LM Studio settings
        $ClineSettings["actModeApiProvider"] = "lmstudio"
        $ClineSettings["planModeApiProvider"] = "lmstudio"
        $ClineSettings["actModeLmStudioModelId"] = $LmStudioConfig.modelId
        $ClineSettings["planModeLmStudioModelId"] = $LmStudioConfig.modelId
        $ClineSettings["lmStudioBaseUrl"] = $LmStudioConfig.baseUrl
        $ClineSettings["lmStudioMaxTokens"] = $LmStudioConfig.maxTokens
        
        Write-Log "Updated Cline configuration:"
        Write-Log "  - API Provider: lmstudio"
        Write-Log "  - Model ID: $($LmStudioConfig.modelId)"
        Write-Log "  - Base URL: $($LmStudioConfig.baseUrl)"
        Write-Log "  - Max Tokens: $($LmStudioConfig.maxTokens)"
        
        # Convert to JSON
        $UpdatedJson = $ClineSettings | ConvertTo-Json -Compress -Depth 10
        
        Write-Log "Generated JSON configuration (length: $($UpdatedJson.Length) chars)"
        Write-Log "Saving configuration to database..."
        
        # In SQLite, string literals use SINGLE quotes, not double quotes
        # Escape single quotes by doubling them
        $JsonForSql = $UpdatedJson -replace "'", "''"
        
        $SqlCommand = @"
DELETE FROM ItemTable WHERE key = 'saoudrizwan.claude-dev';
INSERT INTO ItemTable (key, value) VALUES ('saoudrizwan.claude-dev', '$JsonForSql');
"@
        
        Write-Log "Executing SQL via stdin..."
        
        # Pipe SQL directly to sqlite3 via stdin
        $UpdateResult = $SqlCommand | & $Sqlite3Path $StateDbPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Cline settings updated successfully using SQLite3 CLI"
            
            # Verify the saved data
            $VerifyQuery = "SELECT value FROM ItemTable WHERE key = 'saoudrizwan.claude-dev';"
            $VerifyResult = & $Sqlite3Path $StateDbPath $VerifyQuery 2>&1
            Write-Log "Verification: Saved JSON length = $($VerifyResult.Length) chars"
            
            # Check if JSON is valid
            try {
                $VerifyResult | ConvertFrom-Json | Out-Null
                Write-Log "SUCCESS: Saved JSON is valid and parseable"
            } catch {
                Write-Log "ERROR: Saved JSON is corrupted: $_" "ERROR"
                Write-Log "First 500 chars: $($VerifyResult.Substring(0, [Math]::Min(500, $VerifyResult.Length)))" "ERROR"
                return $false
            }
            
            return $true
        } else {
            Write-Log "Failed to update database. Exit code: $LASTEXITCODE" "ERROR"
            Write-Log "Error output: $UpdateResult" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Failed to update Cline settings with CLI: $_" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        return $false
    }
}

# Function to update Cline settings in VS Code SQLite database (Legacy .NET method)
function Update-ClineSettings {
    param(
        [string]$StateDbPath,
        [hashtable]$LmStudioConfig,
        [string]$TempDir
    )
    
    try {
        # Try to load System.Data.SQLite
        $SqliteLoaded = $false
        try {
            Add-Type -AssemblyName "System.Data.SQLite" -ErrorAction Stop
            Write-Log "Using System.Data.SQLite assembly"
            $SqliteLoaded = $true
        } catch {
            Write-Log "System.Data.SQLite not available in GAC, attempting to install..." "WARN"
            
            # Try to install from NuGet
            $InstallResult = Install-SystemDataSQLite -TempDir $TempDir
            
            if ($InstallResult) {
                $SqliteLoaded = $true
            } else {
                Write-Log "Failed to install System.Data.SQLite automatically" "ERROR"
                Write-Log "Please install manually: Install-Package System.Data.SQLite.Core" "ERROR"
                return $false
            }
        }
        
        if (-not $SqliteLoaded) {
            Write-Log "System.Data.SQLite could not be loaded" "ERROR"
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
            
            # Parse existing JSON (compatible with PowerShell 5.1)
            try {
                $ExistingObject = $ExistingValue | ConvertFrom-Json
                
                # Convert PSCustomObject to Hashtable manually (PS 5.1 compatible)
                $ClineSettings = @{}
                $ExistingObject.PSObject.Properties | ForEach-Object {
                    $ClineSettings[$_.Name] = $_.Value
                }
                
                Write-Log "Successfully parsed existing Cline configuration"
            } catch {
                Write-Log "Could not parse existing configuration, creating new" "WARN"
                Write-Log "Parse error: $_" "WARN"
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
    $LMStudioExe = "$LMStudioPath\LM Studio.exe"
    
    # Check multiple possible installation paths
    $AlternatePaths = @(
        $LMStudioExe,
        "$env:LOCALAPPDATA\Programs\LM Studio\LM Studio.exe",
        "$env:ProgramFiles\LM Studio\LM Studio.exe",
        "${env:ProgramFiles(x86)}\LM Studio\LM Studio.exe"
    )
    
    $LMStudioFound = $false
    foreach ($Path in $AlternatePaths) {
        if (Test-Path $Path) {
            Write-Log "LM Studio found at: $Path"
            $LMStudioFound = $true
            break
        }
    }
    
    if ($LMStudioFound) {
        Write-Log "LM Studio already installed, skipping download and installation..."
        Complete-Step -Number $StepNumber -Title $StepTitle -Status "Already installed"
    } else {
        Write-Log "LM Studio not found, proceeding with download and installation..."
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
        
        # Try SQLite3 CLI approach first (simpler and more reliable)
        Write-Log "=== Attempting to use SQLite3 CLI method ===" "INFO"
        Write-Log "This is the preferred method - no .NET dependencies needed"
        $Sqlite3Path = Install-SQLite3 -TempDir $TempDir
        
        $UpdateResult = $false
        
        if ($Sqlite3Path) {
            Write-Log "SUCCESS: SQLite3 CLI installed successfully at: $Sqlite3Path"
            Write-Log "Using SQLite3 CLI to configure Cline (no .NET method needed)"
            $UpdateResult = Update-ClineSettingsWithCLI -StateDbPath $StateDbPath -LmStudioConfig $LmStudioConfig -Sqlite3Path $Sqlite3Path
            
            if ($UpdateResult) {
                Write-Log "SUCCESS: Cline configured successfully using SQLite3 CLI"
            } else {
                Write-Log "FAILED: SQLite3 CLI method failed to configure Cline" "ERROR"
            }
        } else {
            Write-Log "WARNING: SQLite3 CLI installation failed" "WARN"
            Write-Log "Falling back to .NET method (will download System.Data.SQLite)" "WARN"
            $UpdateResult = Update-ClineSettings -StateDbPath $StateDbPath -LmStudioConfig $LmStudioConfig -TempDir $TempDir
            
            if ($UpdateResult) {
                Write-Log "SUCCESS: Cline configured successfully using .NET method"
            } else {
                Write-Log "FAILED: .NET method also failed" "ERROR"
            }
        }
        
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

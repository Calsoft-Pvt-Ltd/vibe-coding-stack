# Building EXE Installer

This guide explains how to build the standalone EXE installer as an alternative to the MSI installer.

## Why EXE Instead of MSI?

**Advantages:**
- ✅ No Windows Installer service dependencies
- ✅ No admin rights required
- ✅ Simpler installation process
- ✅ Full control over UI and error handling
- ✅ Visible console output
- ✅ Single file distribution
- ✅ Works on all Windows versions

**MSI Issues (solved by EXE):**
- Complex custom actions with limited debugging
- Windows Installer service conflicts
- Impersonation and privilege issues
- Hidden execution makes debugging difficult

## Prerequisites

### Option 1: Using PS2EXE (Recommended)

1. Install PS2EXE module:
   ```powershell
   Install-Module -Name ps2exe -Scope CurrentUser -Force
   ```

2. Build the installer:
   ```powershell
   .\build-exe.ps1
   ```

The EXE will be created in `.\dist\LocalVibeCodingStack-Setup.exe`

### Option 2: Using IExpress (Built into Windows)

IExpress is included with Windows and requires no additional tools.

1. Run the IExpress wizard:
   ```cmd
   iexpress
   ```

2. Follow these steps:
   - Select "Create new Self Extraction Directive file"
   - Choose "Extract files and run an installation command"
   - Package title: "Local Vibe Coding Stack"
   - Confirmation prompt: "Would you like to install Local Vibe Coding Stack?"
   - License agreement: (optional) Select README.md
   - Add files:
     - `scripts\standalone-installer.ps1`
   - Install program: 
     ```
     powershell.exe -NoProfile -ExecutionPolicy Bypass -File standalone-installer.ps1
     ```
   - Window style: "Default (Recommended)"
   - Finished message: "Installation completed!"
   - Save SED file: `.\installer-config.sed`
   - Output file: `.\dist\LocalVibeCodingStack-Setup.exe`

3. Or use the automated script:
   ```powershell
   .\build-exe-iexpress.ps1
   ```

### Option 3: Using Inno Setup (Most Professional)

For the most professional installer with GUI:

1. Download Inno Setup: https://jrsoftware.org/isdl.php

2. Use the provided script:
   ```powershell
   .\build-inno.ps1
   ```

## Build Process

### Automated Build (PS2EXE)

```powershell
# Simple build
.\build-exe.ps1

# Custom output directory
.\build-exe.ps1 -OutputDir "C:\MyBuilds"
```

### Manual Build (PS2EXE)

```powershell
Invoke-ps2exe `
    -inputFile .\scripts\standalone-installer.ps1 `
    -outputFile .\dist\LocalVibeCodingStack-Setup.exe `
    -title "Local Vibe Coding Stack Installer" `
    -description "Automated installer for VS Code, Cline, LM Studio" `
    -version "1.0.0.0" `
    -noConsole:$false `
    -requireAdmin:$false
```

## Testing the EXE

### Quick Test
```powershell
.\dist\LocalVibeCodingStack-Setup.exe
```

### Silent Installation (for automation)
```powershell
.\dist\LocalVibeCodingStack-Setup.exe -Silent
```

## What the EXE Does

1. **Shows Welcome Screen**
   - Lists components to be installed
   - Shows installation directory
   - Waits for user confirmation

2. **Installs Components**
   - VS Code (user-level, no admin needed)
   - Cline extension
   - LM Studio
   - Downloads SQLite3 for configuration

3. **Configures Cline**
   - Automatically sets up LM Studio connection
   - Configures model settings
   - Enables auto-approval features

4. **Creates Shortcuts**
   - Desktop shortcut (optional)
   - Start menu entry (optional)

5. **Shows Completion**
   - Success message
   - Next steps
   - Installation log location

## Distribution

### Single EXE
Simply distribute the generated EXE file:
```
LocalVibeCodingStack-Setup.exe
```

No other files needed! Everything is embedded in the EXE.

### With Installer Package
If you want to include documentation:
```
LocalVibeCodingStack/
  ├── LocalVibeCodingStack-Setup.exe
  ├── README.md
  └── LICENSE
```

## User Installation

### Standard Installation
1. Double-click `LocalVibeCodingStack-Setup.exe`
2. Read the welcome screen
3. Press Enter to continue
4. Wait for installation (5-10 minutes)
5. Press any key to close when complete

### Silent Installation (for IT deployment)
```cmd
LocalVibeCodingStack-Setup.exe -Silent
```

### Installation Locations
- **VS Code**: `%LOCALAPPDATA%\Programs\Microsoft VS Code`
- **LM Studio**: `%LOCALAPPDATA%\LM-Studio`
- **Cline Config**: `%APPDATA%\Code\User\globalStorage\state.vscdb`
- **Installer Files**: `%LOCALAPPDATA%\LocalVibeCodingStack`
- **Log File**: `%TEMP%\LocalVibeCodingStack-install.log`

## Troubleshooting

### "ps2exe not found"
```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Import-Module ps2exe
```

### "Execution policy" error when running EXE
The EXE doesn't require execution policy changes. If you see this error, you're running the .ps1 file directly. Use the EXE instead.

### Installation fails
1. Check the log file:
   ```
   %TEMP%\LocalVibeCodingStack-install.log
   ```

2. Run in non-silent mode to see progress:
   ```cmd
   LocalVibeCodingStack-Setup.exe
   ```

3. Check if antivirus is blocking downloads

### EXE build fails
1. Make sure PS2EXE is properly installed:
   ```powershell
   Get-Module -ListAvailable ps2exe
   ```

2. Try importing the module first:
   ```powershell
   Import-Module ps2exe
   .\build-exe.ps1
   ```

3. Use IExpress as alternative (no installation required)

## Comparison: EXE vs MSI

| Feature | EXE | MSI |
|---------|-----|-----|
| Admin required | ❌ No | ⚠️ Sometimes |
| Visible output | ✅ Yes | ❌ Usually hidden |
| Easy debugging | ✅ Yes | ❌ Difficult |
| Single file | ✅ Yes | ✅ Yes |
| Windows Installer | ❌ Not needed | ✅ Required |
| Uninstall UI | ❌ Custom only | ✅ Built-in |
| Corporate deployment | ✅ Via GPO | ✅ Native |
| Build complexity | ✅ Simple | ⚠️ Complex |
| Size | ~50KB-500KB | ~100KB-1MB |

## Advanced Configuration

### Customize Installation
Edit `scripts\standalone-installer.ps1` and change the `$Config` hashtable:

```powershell
$Config = @{
    installer = @{
        createDesktopShortcut = $true  # Change to $false to skip
        createStartMenuShortcut = $true
    }
    components = @{
        model = @{
            name = "your-preferred-model"  # Change model
            downloadUrl = "https://..."
        }
    }
    clineConfigDefault = @{
        apiMaxTokens = 8192  # Customize settings
        # ... more settings
    }
}
```

### Add Custom Steps
Add code before the final completion screen in `standalone-installer.ps1`

### Change Installation Directory
Edit the `$InstallDir` variable:
```powershell
$InstallDir = "$env:LOCALAPPDATA\YourCompany\YourProduct"
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Build EXE Installer
  run: |
    Install-Module -Name ps2exe -Force -Scope CurrentUser
    .\build-exe.ps1
    
- name: Upload Artifact
  uses: actions/upload-artifact@v3
  with:
    name: installer
    path: dist\LocalVibeCodingStack-Setup.exe
```

### Azure DevOps
```yaml
- powershell: |
    Install-Module -Name ps2exe -Force -Scope CurrentUser
    .\build-exe.ps1
  displayName: 'Build EXE Installer'

- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: 'dist'
    artifactName: 'installer'
```

## Security Notes

### Code Signing (Recommended for Production)
Sign the EXE to avoid SmartScreen warnings:

```powershell
# After building the EXE
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -FilePath ".\dist\LocalVibeCodingStack-Setup.exe" -Certificate $cert
```

### Antivirus False Positives
PS2EXE executables may trigger antivirus warnings. To minimize:
1. Sign the EXE with a valid certificate
2. Submit to antivirus vendors for whitelisting
3. Use IExpress instead (Microsoft tool, fewer warnings)

## Next Steps

1. Build the EXE:
   ```powershell
   .\build-exe.ps1
   ```

2. Test locally:
   ```powershell
   .\dist\LocalVibeCodingStack-Setup.exe
   ```

3. Distribute to users

4. (Optional) Set up automated builds in CI/CD

## Support

If you encounter issues:
1. Check `%TEMP%\LocalVibeCodingStack-install.log`
2. Run installer in non-silent mode
3. Verify prerequisites are met
4. Check antivirus isn't blocking downloads

For MSI-related issues that led to using EXE, see `INSTALLER_FIXES.md`.

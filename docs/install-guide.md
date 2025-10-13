# Installation Guide - Local Vibe Coding Stack

## Overview

This guide covers the installation, configuration, and troubleshooting of the Local Vibe Coding Stack.

## System Requirements

### Minimum Requirements
- **OS**: Windows 10 (64-bit) or Windows 11
- **RAM**: 8GB (16GB recommended for better model performance)
- **Storage**: 15GB free space
  - VS Code: ~500MB
  - LM Studio: ~1GB
  - AI Model: 4-8GB (depending on model size)
  - Temporary files: ~2GB
- **CPU**: Multi-core processor (Intel i5/AMD Ryzen 5 or better)
- **GPU**: Optional (CUDA-compatible GPU for faster inference)
- **Internet**: Required for initial download

### Software Requirements
- Windows PowerShell 5.1+ (pre-installed on Windows 10/11)
- .NET Framework 4.7.2+
- Administrator privileges

## Pre-Installation

### 1. Check PowerShell Execution Policy

```powershell
# Check current policy
Get-ExecutionPolicy

# If it's "Restricted", temporarily allow scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Verify Disk Space

```powershell
Get-PSDrive C | Select-Object Used,Free
```

### 3. Close Running Applications
- Close VS Code if running
- Close LM Studio if running
- Close any other code editors

## Installation

### Method 1: MSI Installer (Recommended)

1. **Download** `LocalVibeCodingStack.msi`
2. **Right-click** and select "Run as Administrator"
3. **Follow** the installation wizard:
   - Accept license agreement
   - Choose installation directory (default recommended)
   - Select components (all enabled by default)
   - Click "Install"
4. **Wait** for installation to complete (10-30 minutes depending on internet speed)
5. **Launch** VS Code when prompted

### Method 2: PowerShell Script (Advanced)

```powershell
# Navigate to the scripts directory
cd path\to\local-vibe-coding-stack\scripts

# Run the installation script
.\install.ps1
```

## Post-Installation

### Verify Installation

1. **VS Code**
   ```powershell
   code --version
   ```

2. **Cline Extension**
   - Open VS Code
   - Click Extensions icon (Ctrl+Shift+X)
   - Search for "Cline" - should show as installed

3. **LM Studio**
   - Check Start Menu for "LM Studio"
   - Or run: `Start-Process "$env:LOCALAPPDATA\LM-Studio\LM Studio.exe"`

4. **Model Downloaded**
   ```powershell
   # Check LM Studio models directory
   Get-ChildItem "$env:USERPROFILE\.cache\lm-studio\models" -Recurse
   ```

### Configure Cline (Auto-configured by installer)

The installer automatically creates `%APPDATA%\Code\User\settings.json` with:

```json
{
  "cline.apiProvider": "lmstudio",
  "cline.lmstudioUrl": "http://localhost:1234/v1",
  "cline.modelId": "deepseek-coder-6.7b-instruct",
  "cline.temperature": 0.7,
  "cline.maxTokens": 4096
}
```

### Start LM Studio Server

1. Open LM Studio
2. Load your model from the left panel
3. Click "Start Server" (default: http://localhost:1234)
4. Verify status indicator shows "Running"

## Usage

### First Time Using Cline

1. Open VS Code
2. Open any code project or create a new file
3. Press `Ctrl+Shift+P` and type "Cline"
4. Select "Cline: Start Chat"
5. Type your coding question or request

### Example Prompts

- "Create a Python function to parse JSON files"
- "Refactor this code to use async/await"
- "Add error handling to this function"
- "Explain what this code does"

## Troubleshooting

### Issue: VS Code doesn't start

**Solution:**
```powershell
# Repair VS Code installation
code --install-extension ms-vscode.vscode-language-pack-en --force
```

### Issue: Cline extension not found

**Solution:**
```powershell
# Manually install Cline
code --install-extension saoudrizwan.claude-dev
```

### Issue: LM Studio can't find model

**Solution:**
1. Open LM Studio
2. Go to "Search" tab
3. Manually download the model from Hugging Face
4. Or check `%USERPROFILE%\.cache\lm-studio\models`

### Issue: Cline can't connect to LM Studio

**Solution:**
1. Verify LM Studio server is running (http://localhost:1234)
2. Check Windows Firewall isn't blocking localhost connections
3. Restart both VS Code and LM Studio
4. Verify Cline settings:
   ```powershell
   code "$env:APPDATA\Code\User\settings.json"
   ```

### Issue: Model inference is slow

**Solution:**
1. Use a smaller/quantized model (e.g., Q4_K_M instead of Q8)
2. Enable GPU acceleration in LM Studio settings
3. Close other heavy applications
4. Reduce `maxTokens` in Cline settings

### Issue: Installation failed

**Solution:**
1. Check install logs:
   ```powershell
   Get-Content "$env:TEMP\LocalVibeCodingStack-install.log"
   ```
2. Run uninstall script and retry:
   ```powershell
   .\scripts\uninstall.ps1
   .\scripts\install.ps1
   ```

## Uninstallation

### Method 1: Windows Settings

1. Open "Settings" > "Apps" > "Apps & features"
2. Search for "Local Vibe Coding Stack"
3. Click "Uninstall"

### Method 2: PowerShell

```powershell
# Run uninstall script
.\scripts\uninstall.ps1

# Or use msiexec
msiexec /x {PRODUCT-GUID} /qn
```

### Clean Uninstall (Remove all data)

```powershell
# Remove VS Code settings
Remove-Item "$env:APPDATA\Code" -Recurse -Force

# Remove LM Studio models
Remove-Item "$env:USERPROFILE\.cache\lm-studio" -Recurse -Force
```

## Advanced Configuration

### Custom Model

Edit `assets\installer-config.json` before building:

```json
{
  "model": {
    "name": "your-model-name",
    "huggingfaceRepo": "username/repo-name",
    "filename": "model-file.gguf",
    "downloadUrl": "https://huggingface.co/..."
  }
}
```

### Offline Installation

1. Pre-download all components
2. Place in `assets\offline\` directory
3. Set `"offlineMode": true` in config
4. Build and run installer

## Support

- **GitHub Issues**: https://github.com/yourusername/local-vibe-coding-stack/issues
- **Documentation**: https://github.com/yourusername/local-vibe-coding-stack/wiki
- **Community**: Discord/Forums (if available)

## FAQ

**Q: Can I use a different model?**
A: Yes, edit the config file and rebuild the installer, or manually download in LM Studio.

**Q: Does this work on macOS/Linux?**
A: Not currently. This is Windows-only.

**Q: Is my code sent to the cloud?**
A: No, everything runs locally. Your code never leaves your machine.

**Q: Can I use multiple models?**
A: Yes, download additional models in LM Studio and switch in Cline settings.

**Q: How do I update components?**
A: Uninstall and reinstall with the latest version, or update manually via each app.

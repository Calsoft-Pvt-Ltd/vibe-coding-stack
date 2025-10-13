# Quick Start Guide - Local Vibe Coding Stack

## Overview

The Local Vibe Coding Stack is a complete Windows installer that sets up everything you need for local AI-assisted coding:

- ✅ **VS Code** - Your code editor
- ✅ **Cline** - AI coding assistant extension  
- ✅ **LM Studio** - Runs AI models locally
- ✅ **AI Model** - Pre-configured and downloaded
- ✅ **Auto-configured** - Everything connected and ready to use

## For End Users

### Installation

1. **Download** `LocalVibeCodingStack.msi` from the [releases page](https://github.com/yourusername/local-vibe-coding-stack/releases)

2. **Run the installer**
   - Double-click the MSI file
   - Or run: `msiexec /i LocalVibeCodingStack.msi`
   - Follow the wizard
   - Wait 15-30 minutes for everything to download and install

3. **Launch the stack**
   - Open LM Studio (Start Menu)
   - Click "Start Server" (it will run on http://localhost:1234)
   - Open VS Code
   - Press `Ctrl+Shift+P` and type "Cline" to start

### First Use

1. In VS Code, open any project or create a new file
2. Click the Cline icon in the sidebar (or press `Ctrl+Shift+P` → "Cline: Start Chat")
3. Try asking: "Create a hello world function in Python"
4. Watch Cline generate code using your local AI model!

### System Requirements

- Windows 10/11 (64-bit)
- 8GB RAM minimum (16GB recommended)
- 15GB free disk space
- Internet for initial download

## For Developers

### Prerequisites

1. **Install WiX Toolset**
   ```powershell
   # Download from: https://wixtoolset.org/releases/
   # Or use Chocolatey:
   choco install wixtoolset
   ```

2. **Install Git**
   ```powershell
   choco install git
   ```

3. **PowerShell 5.1+** (included in Windows 10/11)

### Building the Installer

```powershell
# Clone the repository
git clone https://github.com/yourusername/local-vibe-coding-stack.git
cd local-vibe-coding-stack

# Build the MSI
.\build.ps1

# Output: .\output\LocalVibeCodingStack.msi
```

### Project Structure

```
local-vibe-coding-stack/
├── assets/
│   ├── installer-config.json    # Configuration for all components
│   ├── license.rtf               # License text for installer
│   └── icon.ico                  # Application icon
├── scripts/
│   ├── install.ps1               # Installation automation script
│   └── uninstall.ps1             # Uninstallation script
├── src/
│   └── installer/
│       └── Product.wxs           # WiX installer definition
├── docs/
│   └── install-guide.md          # Detailed installation guide
├── .github/
│   └── workflows/
│       └── build-msi.yml         # CI/CD workflow
├── build.ps1                     # Build script for MSI
├── package.json                  # NPM scripts
├── README.md                     # Main documentation
└── LICENSE                       # MIT License
```

### Customizing the Stack

#### Change the AI Model

Edit `assets/installer-config.json`:

```json
{
  "components": {
    "model": {
      "name": "your-model-name",
      "huggingfaceRepo": "username/repo-name",
      "filename": "model-file.gguf",
      "downloadUrl": "https://huggingface.co/.../resolve/main/model.gguf"
    }
  }
}
```

#### Add New Components

1. Add to `installer-config.json`
2. Update `scripts/install.ps1` with installation logic
3. Update `scripts/uninstall.ps1` with cleanup logic
4. Rebuild: `.\build.ps1`

#### Brand the Installer

Replace these files in `assets/`:
- `icon.ico` - Application icon (any size)
- `banner.bmp` - Installer banner (493×58 pixels)
- `dialog.bmp` - Installer dialog (493×312 pixels)
- `license.rtf` - Your custom license

### Testing

```powershell
# Test installation without downloading large model
.\scripts\install.ps1 -SkipModelDownload

# Full test on clean VM
.\scripts\install.ps1

# Test uninstallation
.\scripts\uninstall.ps1 -Force
```

### GitHub Actions CI/CD

The repository includes automated builds:

- **On push to main/develop**: Builds MSI and uploads as artifact
- **On pull request**: Builds and validates MSI
- **On version tag (v*)**: Creates GitHub release with MSI

To create a release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow will automatically build and attach the MSI to the release.

### Development Workflow

```powershell
# 1. Make changes to scripts or config
# 2. Test locally
.\build.ps1 -Clean
.\scripts\install.ps1

# 3. Commit and push
git add .
git commit -m "feat: Add new feature"
git push

# 4. CI will automatically build and test
```

## Configuration Reference

### installer-config.json

```json
{
  "version": "1.0.0",
  "components": {
    "vscode": {
      "enabled": true,
      "downloadUrl": "VS Code MSI URL",
      "installPath": "%LOCALAPPDATA%\\Programs\\Microsoft VS Code"
    },
    "cline": {
      "enabled": true,
      "extensionId": "saoudrizwan.claude-dev"
    },
    "lmstudio": {
      "enabled": true,
      "downloadUrl": "LM Studio installer URL"
    },
    "model": {
      "enabled": true,
      "name": "model-name",
      "downloadUrl": "https://huggingface.co/..."
    }
  },
  "clineConfig": {
    "apiProvider": "lmstudio",
    "lmstudioUrl": "http://localhost:1234/v1",
    "modelName": "your-model-name"
  }
}
```

## Troubleshooting

### Build Issues

**Error: WiX Toolset not found**
```powershell
# Install WiX Toolset
choco install wixtoolset
# Or download from: https://wixtoolset.org/releases/
```

**Error: Compilation failed**
```powershell
# Check WiX XML syntax in src/installer/Product.wxs
# Ensure all file paths in the WiX file are correct
```

### Installation Issues

**Error: PowerShell execution policy**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Installation hangs**
- Check internet connection
- Monitor `%TEMP%\LocalVibeCodingStack-install.log`
- Model downloads can take 15-30 minutes

**Cline can't connect to LM Studio**
- Ensure LM Studio server is running (http://localhost:1234)
- Verify model is loaded in LM Studio
- Check Cline settings in VS Code

## GitHub Actions Costs

### Public Repository
- **Free** - Unlimited build minutes

### Private Repository
- Free tier: 2,000 Windows minutes/month
- Additional minutes: $0.008/minute
- Typical build time: 10-15 minutes

**Monthly costs for private repo:**
- 10 builds/month: Free (150 minutes)
- 100 builds/month: ~$8 (1,500 minutes)
- 200 builds/month: ~$24 (3,000 minutes)

## Support

- **Documentation**: [docs/install-guide.md](docs/install-guide.md)
- **Issues**: [GitHub Issues](https://github.com/yourusername/local-vibe-coding-stack/issues)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT License - See [LICENSE](LICENSE) file

## Credits

- **VS Code** - Microsoft
- **Cline** - Cline team
- **LM Studio** - LM Studio team
- **WiX Toolset** - WiX community

---

**Happy local AI coding! 🚀**

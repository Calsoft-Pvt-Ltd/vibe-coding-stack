# Project Summary - Local Vibe Coding Stack

## What This Project Does

The **Local Vibe Coding Stack** is a complete, automated Windows installer that sets up a local AI coding environment. With a single MSI installation, users get:

1. **VS Code** - Industry-standard code editor
2. **Cline Coding Agent** - AI-powered coding assistant
3. **LM Studio** - Local LLM runtime (no cloud, no subscriptions)
4. **AI Model** - Pre-downloaded and configured
5. **Complete Integration** - Everything connected and ready to use

## Key Features

✅ **One-Click Installation** - MSI installer handles everything
✅ **Fully Local** - No cloud dependencies, your code stays private
✅ **Auto-Configured** - Works out of the box, no manual setup
✅ **Production Ready** - Proper Windows integration, uninstaller included
✅ **Customizable** - Easy to configure different models or components
✅ **CI/CD Ready** - GitHub Actions builds installer automatically

## Technical Stack

- **Installer Framework**: WiX Toolset 6 CLI (generates MSI)
- **Automation**: PowerShell scripts
- **Configuration**: JSON-based
- **CI/CD**: GitHub Actions
- **Platform**: Windows 10/11

## Project Structure

```
local-vibe-coding-stack/
├── 📄 README.md                     # Main documentation
├── 📄 QUICKSTART.md                 # Quick start guide for users & developers
├── 📄 CHANGELOG.md                  # Version history
├── 📄 CONTRIBUTING.md               # Contribution guidelines
├── 📄 LICENSE                       # MIT License
├── 📄 package.json                  # NPM scripts for convenience
├── 📄 .gitignore                    # Git ignore rules
├── 🔨 build.ps1                     # MSI build script
│
├── 📁 assets/                       # Configuration & branding
│   └── installer-config.json        # Component URLs, versions, settings
│   └── license.rtf                  # Installer license text
│   └── icon.ico                     # App icon (optional)
│   └── banner.bmp                   # Installer banner (optional)
│   └── dialog.bmp                   # Installer dialog (optional)
│
├── 📁 scripts/                      # PowerShell automation
│   ├── install.ps1                  # Main installation logic
│   └── uninstall.ps1                # Cleanup & removal logic
│
├── 📁 src/                          # Installer source
│   └── installer/
│       └── Product.wxs              # WiX XML definition (MSI structure)
│
├── 📁 docs/                         # Documentation
│   └── install-guide.md             # Detailed installation guide
│
└── 📁 .github/                      # CI/CD
    └── workflows/
        └── build-msi.yml            # GitHub Actions workflow
```

## How It Works

### Installation Flow

```
User runs MSI
    ↓
MSI extracts scripts & config
    ↓
PowerShell install.ps1 runs
    ↓
Downloads VS Code MSI → Installs
    ↓
Installs Cline extension via VS Code CLI
    ↓
Downloads LM Studio EXE → Installs
    ↓
Downloads AI model from Hugging Face
    ↓
Configures Cline to use LM Studio
    ↓
Creates shortcuts
    ↓
Installation complete!
```

### Build Flow

```
Developer runs build.ps1
    ↓
WiX Toolset compiles Product.wxs
    ↓
Includes scripts & assets in MSI
    ↓
Generates LocalVibeCodingStack.msi
    ↓
Ready to distribute!
```

### CI/CD Flow

```
Developer pushes to GitHub
    ↓
GitHub Actions triggers
    ↓
Windows runner installs WiX
    ↓
Runs build.ps1
    ↓
Uploads MSI as artifact
    ↓
(If tagged) Creates GitHub Release
```

## Configuration

The entire stack is configured via `assets/installer-config.json`:

```json
{
  "components": {
    "vscode": { "enabled": true, "downloadUrl": "..." },
    "cline": { "enabled": true, "extensionId": "..." },
    "lmstudio": { "enabled": true, "downloadUrl": "..." },
    "model": { "enabled": true, "downloadUrl": "..." }
  },
  "clineConfig": {
    "apiProvider": "lmstudio",
    "lmstudioUrl": "http://localhost:1234/v1"
  }
}
```

## For End Users

### Installation
1. Download `LocalVibeCodingStack.msi`
2. Double-click to install
3. Wait 15-30 minutes
4. Launch VS Code and start coding with AI!

### System Requirements
- Windows 10/11 (64-bit)
- 8GB RAM (16GB recommended)
- 15GB free disk space
- Internet connection (initial download only)

## For Developers

### Building the Installer

```powershell
# Prerequisites
# - Install WiX CLI 6.0+ (dotnet tool install --global wix --version 6.0.0)
# - Install PowerShell 5.1+ (included in Windows 10/11)

# Build
git clone <repo>
cd local-vibe-coding-stack
.\build.ps1

# Output: .\output\LocalVibeCodingStack.msi
```

### Testing

```powershell
# Quick test (skips model download)
.\scripts\install.ps1 -SkipModelDownload

# Full test
.\scripts\install.ps1

# Uninstall test
.\scripts\uninstall.ps1 -Force
```

### Customization

**Change AI Model:**
Edit `assets/installer-config.json` → Update model URL → Rebuild

**Add Components:**
Update `installer-config.json` + `install.ps1` + `uninstall.ps1` → Rebuild

**Brand Installer:**
Replace `assets/icon.ico`, `banner.bmp`, `dialog.bmp` → Rebuild

## Why WiX Instead of Inno Setup?

| Feature | WiX Toolset | Inno Setup |
|---------|-------------|------------|
| Output | MSI | EXE |
| Windows Integration | Native MSI support | Limited |
| Group Policy | ✅ Deployable | ❌ No |
| Rollback | ✅ Built-in | ⚠️ Limited |
| Customization | XML-based, very flexible | Script-based |
| Learning Curve | Steeper | Easier |
| **Best For** | **Enterprise/Professional** | Consumer apps |

For this project, MSI is better because:
- Professional appearance
- Proper Windows installer database
- Better uninstall support
- Corporate deployment ready

## GitHub Actions Costs

### Public Repo: FREE ✅

### Private Repo:
- Free tier: 2,000 Windows minutes/month
- Extra minutes: $0.008/min
- Typical build: 10-15 minutes

**Example costs:**
- 10 builds/month: FREE
- 100 builds/month: ~$8
- 200 builds/month: ~$24

## Future Enhancements

### v1.1.0
- Multiple model selection
- Offline installation mode
- Custom installation paths
- Silent mode improvements

### v1.2.0
- Additional AI assistants
- GPU acceleration setup
- Model quantization options
- Update mechanism

### v2.0.0
- macOS/Linux support
- Docker-based installation
- Web installer UI

## Success Metrics

A successful installation means:
- ✅ VS Code launches
- ✅ Cline extension visible in VS Code
- ✅ LM Studio installed and runs
- ✅ Model downloaded to correct path
- ✅ Cline connects to LM Studio
- ✅ AI code generation works
- ✅ Uninstaller removes everything cleanly

## Known Limitations

1. **Windows Only** - No macOS/Linux support (yet)
2. **Internet Required** - For initial component downloads
3. **Large Download** - 5-10GB depending on model
4. **Time** - 15-30 minutes installation time
5. **LM Studio** - Only available as EXE, not MSI

## Troubleshooting

### Build Issues
- Install WiX CLI: `dotnet tool install --global wix --version 6.0.0`
- Check PowerShell version: `$PSVersionTable.PSVersion`

### Install Issues
- Check logs: `%TEMP%\LocalVibeCodingStack-install.log`
- Verify internet connection
- Ensure 15GB+ free space

### Runtime Issues
- Start LM Studio server first
- Check LM Studio is on port 1234
- Verify Cline settings in VS Code

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code style guidelines
- Testing procedures
- Pull request process

## License

MIT License - see [LICENSE](LICENSE)

## Support

- 📖 [Documentation](docs/install-guide.md)
- 🐛 [Report Issues](https://github.com/yourusername/local-vibe-coding-stack/issues)
- 💬 [Discussions](https://github.com/yourusername/local-vibe-coding-stack/discussions)

---

**Built with ❤️ for developers who value privacy and local-first AI**

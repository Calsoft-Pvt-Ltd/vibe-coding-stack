# Local Vibe Coding Stack

An automated Windows installer that sets up a complete local AI code assistant environment.

## What's Included

1. **VS Code** - Microsoft Visual Studio Code editor
2. **Cline Coding Agent** - AI coding assistant extension for VS Code
3. **LM Studio** - Local LLM runtime environment
4. **AI Model** - Automatically downloads and configures your chosen model
5. **Auto Configuration** - Cline is automatically configured to use the local model via LM Studio

## Prerequisites

- Windows 10/11 (64-bit)
- Administrator privileges
- 10GB+ free disk space (for models)
- Internet connection (for initial download)

## Building the Installer

### Requirements

1. Install [.NET SDK 6.0+](https://dotnet.microsoft.com/download) (required for WiX CLI)
2. Install WiX Toolset 6 CLI:
	```powershell
	dotnet tool install --global wix --version 6.0.0
	```
3. PowerShell 5.1+ (included in Windows 10/11)

### Build Steps

```powershell
# Clone the repository
git clone https://github.com/yourusername/local-vibe-coding-stack.git
cd local-vibe-coding-stack

# Build the MSI
.\build.ps1
```

The MSI installer will be generated in the `output` directory.

## Installation

1. Run `LocalVibeCodingStack.msi`
2. Follow the installation wizard
3. Wait for all components to download and install (15-30 minutes)
4. Launch VS Code when complete

**Installation Logs**: If the installation encounters issues, check the detailed logs at:
- `%LOCALAPPDATA%\LocalVibeCodingStack\logs\install.log`

You can also run the MSI with verbose logging:
```powershell
msiexec /i LocalVibeCodingStack.msi /l*v install-verbose.log
```

## Configuration

Edit `assets\installer-config.json` to customize:

- Model to download
- Installation paths
- Component versions
- Download URLs

## Usage

After installation:

1. Open VS Code
2. Cline extension is pre-installed and configured
3. LM Studio is running with your chosen model
4. Start coding with AI assistance!

## Uninstallation

Use Windows "Add or Remove Programs" or run:

```powershell
msiexec /x {PRODUCT-GUID} /qn
```

**Uninstall Logs**: Check uninstallation logs at:
- `%LOCALAPPDATA%\LocalVibeCodingStack\logs\uninstall.log`

## Troubleshooting

If installation fails:

1. **Check installation logs**: Open `%LOCALAPPDATA%\LocalVibeCodingStack\logs\install.log` to see detailed error messages
2. **Run with verbose MSI logging**: 
   ```powershell
   msiexec /i LocalVibeCodingStack.msi /l*v msi-install.log
   ```
3. **Verify prerequisites**:
   - Windows 10/11 (64-bit)
   - Administrator privileges
   - 10GB+ free disk space
   - Internet connection active
   - PowerShell 5.1+: Check with `$PSVersionTable.PSVersion`

4. **Common issues**:
   - Network timeouts during downloads - Retry installation
   - Insufficient disk space - Free up space and retry
   - Antivirus blocking - Temporarily disable and retry

## License

MIT License

## Support

For issues, visit: https://github.com/yourusername/local-vibe-coding-stack/issues

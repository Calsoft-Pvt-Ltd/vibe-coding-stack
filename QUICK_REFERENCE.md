# Quick Reference - Building EXE Installer

## TL;DR - Fastest Path

```powershell
# Option 1: Use IExpress (built into Windows, no installation needed)
.\build-exe-iexpress.ps1

# Option 2: Use PS2EXE (smaller files, need to install first)
Install-Module ps2exe -Scope CurrentUser -Force
.\build-exe.ps1
```

Output: `.\dist\LocalVibeCodingStack-Setup.exe`

## Commands Cheat Sheet

### Building

| Method | Command | Pros | Cons |
|--------|---------|------|------|
| **IExpress** | `.\build-exe-iexpress.ps1` | No tools needed | Larger file |
| **PS2EXE** | `.\build-exe.ps1` | Smaller file | Need to install module |
| **MSI** | `.\build.ps1` | Enterprise friendly | Complex, Error 1722 issues |

### Testing

```powershell
# Check if you can build
.\test-exe-build.ps1

# Test the EXE locally
.\dist\LocalVibeCodingStack-Setup.exe

# Silent installation (for testing automation)
.\dist\LocalVibeCodingStack-Setup.exe -Silent
```

### Installing Prerequisites

```powershell
# For PS2EXE method
Install-Module -Name ps2exe -Scope CurrentUser -Force

# For MSI method (legacy)
dotnet tool install --global wix --version 6.0.0
```

## File Locations

| What | Where |
|------|-------|
| **Main installer script** | `scripts\standalone-installer.ps1` |
| **Built EXE** | `dist\LocalVibeCodingStack-Setup.exe` |
| **Installation log** | `%TEMP%\LocalVibeCodingStack-install.log` |
| **VS Code** | `%LOCALAPPDATA%\Programs\Microsoft VS Code` |
| **LM Studio** | `%LOCALAPPDATA%\LM-Studio` |
| **Cline Config** | `%APPDATA%\Code\User\globalStorage\state.vscdb` |

## Troubleshooting Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| **ps2exe not found** | `Install-Module ps2exe -Force` then retry |
| **IExpress fails** | Run as admin or use PS2EXE instead |
| **Antivirus blocks EXE** | Use IExpress instead of PS2EXE |
| **Installation hangs** | Check log at `%TEMP%\LocalVibeCodingStack-install.log` |
| **VS Code won't install** | Already installed? Check `%LOCALAPPDATA%\Programs\Microsoft VS Code` |
| **Error 1722 (MSI)** | Use EXE instead |

## One-Liners

```powershell
# Clone, build, and test in one go
git clone <repo> && cd local-vibe-coding-stack && .\build-exe-iexpress.ps1 && .\dist\LocalVibeCodingStack-Setup.exe

# Build both MSI and EXE
.\build.ps1; .\build-exe-iexpress.ps1

# Clean and rebuild
rm -r dist -Force; .\build-exe-iexpress.ps1

# Install PS2EXE and build
Install-Module ps2exe -Force -Scope CurrentUser; .\build-exe.ps1
```

## Key Differences

### EXE (Recommended)
- ✅ No admin needed
- ✅ Visible progress
- ✅ Easy debugging
- ✅ Simple build
- ⚠️ No Add/Remove Programs entry

### MSI (Enterprise)
- ✅ GPO deployment
- ✅ Add/Remove Programs
- ⚠️ Sometimes needs admin
- ⚠️ Error 1722 issues
- ❌ Hidden execution

## Documentation

- **Complete guide**: `docs\BUILD_EXE.md`
- **Comparison**: `docs\EXE_VS_MSI.md`
- **Implementation**: `EXE_IMPLEMENTATION.md`
- **MSI fixes**: `INSTALLER_FIXES.md`
- **Main README**: `README.md`

## Decision Tree

```
Need installer?
    ├─ For end users? → Use EXE (IExpress)
    ├─ For developers? → Use EXE (PS2EXE)
    ├─ For small team? → Use EXE (either)
    └─ For enterprise (GPO)? → Use MSI
```

## Success Checklist

Build:
- [ ] Run `.\test-exe-build.ps1` - all pass
- [ ] Build EXE with chosen method
- [ ] Verify EXE created in `dist\`
- [ ] File size reasonable (< 1MB)

Test:
- [ ] Run EXE on clean VM
- [ ] Console window visible
- [ ] All steps complete with ✓
- [ ] No admin prompt
- [ ] VS Code launches
- [ ] Cline installed
- [ ] LM Studio installed

Distribute:
- [ ] Test on Windows 10
- [ ] Test on Windows 11
- [ ] Sign EXE (optional but recommended)
- [ ] Upload to distribution point
- [ ] Update documentation

## Quick Links

- **WiX Toolset**: https://wixtoolset.org/
- **PS2EXE**: https://github.com/MScholtes/PS2EXE
- **IExpress**: Built into Windows (`iexpress.exe`)
- **Inno Setup**: https://jrsoftware.org/isinfo.php

---

**Bottom Line**: Use `.\build-exe-iexpress.ps1` for fastest, easiest build with no prerequisites!

# Build Fixes Applied

## Issues Fixed

### 1. CustomAction Property Attribute Missing
**Error:**
```
error CNDL0037 : The CustomAction/@Value attribute can only be specified with one of the following attributes: Directory or Property present.
```

**Fix:**
Added `Property="ProgressText"` attribute to CustomAction elements that set progress text.

```xml
<!-- Before -->
<CustomAction Id="SetInstallProgressText" 
              Value="Installing VS Code..." />

<!-- After -->
<CustomAction Id="SetInstallProgressText" 
              Property="ProgressText"
              Value="Installing VS Code..." />
```

### 2. Duplicate ARPNOREPAIR and ARPNOMODIFY Properties
**Error:**
```
error LGHT0091 : Duplicate symbol 'Property:ARPNOMODIFY' found.
```

**Fix:**
Removed duplicate property definitions that were already defined by `WixUI_InstallDir` extension.

```xml
<!-- Removed these lines -->
<Property Id="ARPNOREPAIR" Value="yes" Secure="yes" />
<Property Id="ARPNOMODIFY" Value="yes" Secure="yes" />
```

### 3. Missing Asset Files (icon.ico, banner.bmp, dialog.bmp, license.rtf)
**Error:**
```
error LGHT0103 : The system cannot find the file 'assets\banner.bmp'.
error LGHT0103 : The system cannot find the file 'assets\dialog.bmp'.
```

**Fix:**
Removed all references to optional asset files that don't exist in the repository:
- Removed `Icon` element and `ARPPRODUCTICON` property
- Removed `Icon="icon.ico"` from shortcuts
- Removed `WixVariable` elements for banner.bmp, dialog.bmp, and license.rtf

The installer now builds without requiring any custom branding assets.

### 4. Updated GitHub URLs
**Fix:**
Changed placeholder URLs to actual repository:
```xml
<!-- Before -->
<Property Id="ARPHELPLINK" Value="https://github.com/yourusername/local-vibe-coding-stack" />

<!-- After -->
<Property Id="ARPHELPLINK" Value="https://github.com/Calsoft-Pvt-Ltd/vibe-coding-stack" />
```

### 5. Simplified Build Script
**Fix:**
Removed code that tried to create placeholder assets (icon, license, banner, dialog) since they're no longer referenced by the WiX file.

## Result

The MSI installer now builds successfully without requiring any custom branding assets. The installer uses:
- Default Windows UI (WixUI_InstallDir)
- No custom icons
- Default license text from WiX
- Standard installer appearance

## Optional Enhancements (Future)

To add custom branding later, create these files in the `assets/` folder and update Product.wxs:

1. **icon.ico** - Application icon (any size)
   ```xml
   <Icon Id="icon.ico" SourceFile="assets\icon.ico"/>
   <Property Id="ARPPRODUCTICON" Value="icon.ico" />
   ```

2. **banner.bmp** - Installer banner (493×58 pixels)
   ```xml
   <WixVariable Id="WixUIBannerBmp" Value="assets\banner.bmp" />
   ```

3. **dialog.bmp** - Installer dialog background (493×312 pixels)
   ```xml
   <WixVariable Id="WixUIDialogBmp" Value="assets\dialog.bmp" />
   ```

4. **license.rtf** - Custom license text (RTF format)
   ```xml
   <WixVariable Id="WixUILicenseRtf" Value="assets\license.rtf" />
   ```

## Build Command

```powershell
.\build.ps1
```

The MSI will be created at: `.\output\LocalVibeCodingStack.msi`

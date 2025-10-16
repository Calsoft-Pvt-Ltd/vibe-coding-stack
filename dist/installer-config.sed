[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles

[Strings]
InstallPrompt=Would you like to install Local Vibe Coding Stack? This will install VS Code, Cline, LM Studio, and configure your AI assistant.
DisplayLicense=
FinishMessage=Installation completed! Check your desktop for the shortcut.
TargetName=D:\projects\personal\vibe-coding-stack\dist\LocalVibeCodingStack-Setup.exe
FriendlyName=Local Vibe Coding Stack Installer
AppLaunched=cmd /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File standalone-installer.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="standalone-installer.ps1"

[SourceFiles]
SourceFiles0=D:\projects\personal\vibe-coding-stack\scripts

[SourceFiles0]
%FILE0%=

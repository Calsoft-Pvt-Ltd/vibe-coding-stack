# Architecture & Flow Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Local Vibe Coding Stack                   │
│                    Windows MSI Installer                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     WiX Toolset (MSI)                        │
│  • Product.wxs (XML definition)                              │
│  • Custom Actions (PowerShell triggers)                      │
│  • UI Dialogs                                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  PowerShell Installer                        │
│                  (install.ps1)                               │
│  ┌────────────────────────────────────────────────┐         │
│  │ 1. VS Code MSI Installation                    │         │
│  │ 2. Cline Extension via VS Code CLI             │         │
│  │ 3. LM Studio EXE Installation                  │         │
│  │ 4. AI Model Download (Hugging Face)            │         │
│  │ 5. Cline Configuration (settings.json)         │         │
│  └────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Installed Components                        │
│                                                               │
│  ┌───────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   VS Code     │  │    Cline     │  │   LM Studio     │  │
│  │   (Editor)    │  │  (AI Agent)  │  │  (LLM Server)   │  │
│  └───────┬───────┘  └──────┬───────┘  └────────┬────────┘  │
│          │                  │                    │           │
│          └──────────────────┼────────────────────┘           │
│                             │                                │
│                      ┌──────▼───────┐                        │
│                      │   AI Model   │                        │
│                      │ (Local GGUF) │                        │
│                      └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## Installation Flow

```
┌──────────────────────────────────────────────────────────────┐
│                  User Action: Run MSI                         │
└──────────────────┬───────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────┐
│            WiX Installer Initialization                       │
│  • Check prerequisites (Windows 10+, PowerShell 5.1+)         │
│  • Show welcome dialog                                        │
│  • License agreement                                          │
│  • Choose installation directory                              │
└──────────────────┬───────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────┐
│              Extract Files to Install Dir                     │
│  • scripts/install.ps1                                        │
│  • scripts/uninstall.ps1                                      │
│  • assets/installer-config.json                               │
└──────────────────┬───────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────┐
│          Execute Custom Action: install.ps1                   │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Step 1: Download & Install VS Code                 │     │
│  │    • Fetch VS Code MSI from Microsoft                │     │
│  │    • Silent install: msiexec /i                      │     │
│  │    • Add to PATH                                      │     │
│  └─────────────────────────────────────────────────────┘     │
│                      ▼                                        │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Step 2: Install Cline Extension                    │     │
│  │    • Wait for VS Code to be ready                    │     │
│  │    • Run: code --install-extension                   │     │
│  │    • Verify installation                              │     │
│  └─────────────────────────────────────────────────────┘     │
│                      ▼                                        │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Step 3: Download & Install LM Studio               │     │
│  │    • Fetch LM Studio EXE                             │     │
│  │    • Silent install: /S                              │     │
│  │    • Verify installation                              │     │
│  └─────────────────────────────────────────────────────┘     │
│                      ▼                                        │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Step 4: Download AI Model                          │     │
│  │    • Create model directory                          │     │
│  │    • Download from Hugging Face                      │     │
│  │    • Save to ~/.cache/lm-studio/models/              │     │
│  │    • Verify file integrity (optional)                │     │
│  └─────────────────────────────────────────────────────┘     │
│                      ▼                                        │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Step 5: Configure Cline                            │     │
│  │    • Create %APPDATA%\Code\User\                     │     │
│  │    • Generate settings.json                          │     │
│  │    • Set LM Studio URL (localhost:1234)              │     │
│  │    • Set model name                                  │     │
│  └─────────────────────────────────────────────────────┘     │
│                      ▼                                        │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Step 6: Create Shortcuts                           │     │
│  │    • Desktop shortcut to VS Code                     │     │
│  │    • Start Menu shortcuts                            │     │
│  └─────────────────────────────────────────────────────┘     │
└──────────────────┬───────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────┐
│              MSI Finalization                                 │
│  • Register in Add/Remove Programs                            │
│  • Create uninstaller                                         │
│  • Show completion message                                    │
└──────────────────┬───────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────┐
│                Installation Complete!                         │
│  User can launch VS Code and start using Cline               │
└──────────────────────────────────────────────────────────────┘
```

## Runtime Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Developer                             │
│                  (Writing Code in VS Code)                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Types prompt
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                     VS Code + Cline                          │
│  ┌────────────────────────────────────────────────┐         │
│  │  Cline Extension                               │         │
│  │  • Receives user prompt                        │         │
│  │  • Formats API request                         │         │
│  │  • Reads settings.json for LM Studio URL       │         │
│  └────────────────┬───────────────────────────────┘         │
└───────────────────┼─────────────────────────────────────────┘
                    │
                    │ HTTP POST /v1/chat/completions
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   LM Studio Server                           │
│              (http://localhost:1234)                         │
│  ┌────────────────────────────────────────────────┐         │
│  │  API Server                                    │         │
│  │  • Receives API request                        │         │
│  │  • Loads model from cache                      │         │
│  │  • Performs inference                          │         │
│  └────────────────┬───────────────────────────────┘         │
└───────────────────┼─────────────────────────────────────────┘
                    │
                    │ Loads model
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   AI Model (GGUF)                            │
│        ~/.cache/lm-studio/models/                            │
│  ┌────────────────────────────────────────────────┐         │
│  │  deepseek-coder-6.7b-instruct.Q4_K_M.gguf     │         │
│  │  • Loaded into memory                          │         │
│  │  • Performs token generation                   │         │
│  │  • Returns completion                          │         │
│  └────────────────┬───────────────────────────────┘         │
└───────────────────┼─────────────────────────────────────────┘
                    │
                    │ Returns JSON response
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   LM Studio Server                           │
│  • Formats response                                          │
│  • Sends back to Cline                                       │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    │ HTTP 200 OK + generated code
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     VS Code + Cline                          │
│  • Receives AI response                                      │
│  • Displays generated code                                   │
│  • Applies changes to files (if requested)                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                        Developer                             │
│                  (Reviews generated code)                    │
└─────────────────────────────────────────────────────────────┘
```

## Build Pipeline (CI/CD)

```
┌─────────────────────────────────────────────────────────────┐
│                  Developer: git push                         │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Repository                          │
│  • Receives commit                                           │
│  • Triggers workflow: .github/workflows/build-msi.yml        │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions (Windows Runner)                 │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Job: build                                         │    │
│  │                                                      │    │
│  │  Step 1: Checkout code                              │    │
│  │    • actions/checkout@v4                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                      ▼                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Step 2: Install WiX Toolset                        │    │
│  │    • Download wix314.exe                            │    │
│  │    • Silent install                                 │    │
│  └─────────────────────────────────────────────────────┘    │
│                      ▼                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Step 3: Build MSI                                  │    │
│  │    • Run: .\build.ps1                               │    │
│  │    • WiX compiles Product.wxs                       │    │
│  │    • Generates LocalVibeCodingStack.msi             │    │
│  └─────────────────────────────────────────────────────┘    │
│                      ▼                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Step 4: Calculate checksums                        │    │
│  │    • SHA256 hash                                    │    │
│  │    • MD5 hash                                       │    │
│  │    • File size                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                      ▼                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Step 5: Upload artifacts                           │    │
│  │    • actions/upload-artifact@v4                     │    │
│  │    • MSI file                                       │    │
│  │    • Checksums                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                      ▼                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Step 6: Create Release (if tagged)                 │    │
│  │    • Detect version tag (v*)                        │    │
│  │    • softprops/action-gh-release@v1                 │    │
│  │    • Attach MSI + checksums                         │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Release / Artifacts                      │
│  • LocalVibeCodingStack.msi available for download           │
│  • CHECKSUMS.txt for verification                            │
│  • Artifacts retained for 90 days                            │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Flow

```
┌─────────────────────────────────────────────────────────────┐
│          assets/installer-config.json                        │
│  {                                                           │
│    "components": {                                           │
│      "vscode": { "downloadUrl": "...", ... },                │
│      "cline": { "extensionId": "...", ... },                 │
│      "lmstudio": { "downloadUrl": "...", ... },              │
│      "model": { "downloadUrl": "...", ... }                  │
│    },                                                        │
│    "clineConfig": { "apiProvider": "lmstudio", ... }         │
│  }                                                           │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Read by
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                  scripts/install.ps1                         │
│  • Loads configuration                                       │
│  • Extracts download URLs                                    │
│  • Extracts version info                                     │
│  • Uses settings for installation                            │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Downloads components
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                External Download Sources                     │
│  • Microsoft (VS Code MSI)                                   │
│  • VS Code Marketplace (Cline extension)                     │
│  • LM Studio (installer)                                     │
│  • Hugging Face (AI model)                                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Installs & configures
                   ▼
┌─────────────────────────────────────────────────────────────┐
│             Generated Configuration Files                    │
│                                                               │
│  %APPDATA%\Code\User\settings.json                           │
│  {                                                           │
│    "cline.apiProvider": "lmstudio",                          │
│    "cline.lmstudioUrl": "http://localhost:1234/v1",          │
│    "cline.modelId": "deepseek-coder-6.7b-instruct",          │
│    ...                                                       │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

## File System Layout (Post-Installation)

```
C:\Users\[Username]\
│
├── AppData\
│   ├── Local\
│   │   ├── Programs\
│   │   │   └── Microsoft VS Code\          [VS Code Installation]
│   │   │       ├── Code.exe
│   │   │       └── bin\code.cmd
│   │   │
│   │   ├── LM-Studio\                       [LM Studio Installation]
│   │   │   ├── LM Studio.exe
│   │   │   └── resources\
│   │   │
│   │   └── LocalVibeCodingStack\            [Installer Files]
│   │       ├── scripts\
│   │       │   ├── install.ps1
│   │       │   └── uninstall.ps1
│   │       └── assets\
│   │           └── installer-config.json
│   │
│   └── Roaming\
│       └── Code\                            [VS Code Settings]
│           └── User\
│               ├── settings.json            [Cline Configuration]
│               └── extensions\
│                   └── saoudrizwan.claude-dev-*/
│
└── .cache\
    └── lm-studio\
        └── models\                          [Downloaded Models]
            └── TheBloke\
                └── deepseek-coder-6.7b-instruct-GGUF\
                    └── deepseek-coder-6.7b-instruct.Q4_K_M.gguf

Desktop\
└── VS Code (Local Vibe).lnk                 [Desktop Shortcut]

Start Menu\
└── Programs\
    └── Local Vibe Coding Stack\              [Start Menu Folder]
        ├── Local Vibe Coding Stack.lnk
        └── Uninstall.lnk
```

## Component Communication

```
┌──────────────┐      REST API         ┌──────────────┐
│              │◄──────────────────────►│              │
│   VS Code    │  http://localhost:1234 │  LM Studio   │
│   + Cline    │    /v1/chat/           │   Server     │
│              │    completions          │              │
└──────────────┘                        └──────┬───────┘
       ▲                                       │
       │                                       │
       │ Reads config                          │ Loads model
       │                                       │
       │                                       ▼
┌──────┴────────────────────┐      ┌─────────────────────┐
│  %APPDATA%\Code\User\     │      │  ~/.cache/lm-studio/│
│  settings.json            │      │  models/*.gguf      │
│                           │      │                     │
│  {                        │      │  [AI Model File]    │
│    "cline.lmstudioUrl":   │      │  4-8GB binary       │
│    "localhost:1234"       │      │                     │
│  }                        │      │                     │
└───────────────────────────┘      └─────────────────────┘
```

---

## Key Design Decisions

### 1. Why MSI over EXE?
- **Professional**: Proper Windows Installer standard
- **Enterprise-ready**: Group Policy deployment
- **Better uninstall**: Windows manages lifecycle
- **Rollback support**: Built-in transaction support

### 2. Why WiX Toolset?
- **Industry standard**: Used by Microsoft
- **XML-based**: Version control friendly
- **Flexible**: Full control over MSI structure
- **Open source**: No licensing costs

### 3. Why PowerShell for automation?
- **Native**: Included in Windows
- **Powerful**: Full Windows API access
- **Scriptable**: Easy to test and debug
- **Logging**: Built-in error handling

### 4. Why LM Studio?
- **User-friendly**: GUI for model management
- **OpenAI-compatible**: Standard API
- **Local**: No cloud dependencies
- **Free**: Open source

### 5. Why JSON configuration?
- **Human-readable**: Easy to edit
- **Structured**: Schema validation possible
- **Standard**: PowerShell native support
- **Flexible**: Easy to extend

---

**End of Architecture Documentation**

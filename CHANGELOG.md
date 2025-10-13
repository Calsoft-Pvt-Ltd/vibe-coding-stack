# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- WiX-based MSI installer
- Automated installation scripts for VS Code, Cline, LM Studio
- Automatic AI model download
- Auto-configuration of Cline to use LM Studio
- GitHub Actions CI/CD workflow
- Comprehensive documentation

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

## [1.0.0] - 2025-10-13

### Added
- Complete Windows installer stack
- VS Code MSI installation
- Cline extension auto-install
- LM Studio integration
- Default AI model (DeepSeek Coder 6.7B)
- Desktop and Start Menu shortcuts
- Installation and uninstallation scripts
- Build automation with WiX Toolset
- GitHub Actions workflow for automated builds
- Comprehensive documentation:
  - README.md
  - QUICKSTART.md
  - install-guide.md
  - CONTRIBUTING.md

### Features
- One-click installation of complete AI coding stack
- Automatic configuration of all components
- Support for custom AI models
- Configurable via JSON
- Unattended installation support
- Proper Windows integration (Add/Remove Programs)
- Installation logging

### Technical
- PowerShell-based automation
- WiX Toolset 3.14+ for MSI generation
- GitHub Actions for CI/CD
- Configurable component system

---

## Version History

### How to Read This Changelog

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security vulnerability fixes

### Release Naming

- **Major version (X.0.0)**: Breaking changes, major new features
- **Minor version (1.X.0)**: New features, backwards compatible
- **Patch version (1.0.X)**: Bug fixes, small improvements

---

## Future Roadmap

### v1.1.0 (Planned)
- [ ] Support for multiple AI models
- [ ] Model selection UI during installation
- [ ] Offline installation mode
- [ ] Custom installation paths
- [ ] Silent installation mode improvements

### v1.2.0 (Planned)
- [ ] Support for additional AI coding assistants
- [ ] GPU acceleration configuration
- [ ] Model quantization options
- [ ] Update mechanism for installed components

### v2.0.0 (Future)
- [ ] Cross-platform support (macOS, Linux)
- [ ] Docker-based alternative installation
- [ ] Web-based installer UI
- [ ] Automatic model recommendations

---

[Unreleased]: https://github.com/yourusername/local-vibe-coding-stack/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/local-vibe-coding-stack/releases/tag/v1.0.0

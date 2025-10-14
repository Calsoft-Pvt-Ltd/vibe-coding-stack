# Contributing to Local Vibe Coding Stack

Thank you for your interest in contributing! Here's how you can help.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/local-vibe-coding-stack.git`
3. Create a branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- Windows 10/11
- PowerShell 5.1+
- WiX Toolset 6 CLI (`dotnet tool install --global wix --version 6.0.0`)
- Git

### Building Locally

```powershell
# Build the MSI installer
.\build.ps1

# Test installation (skips model download)
npm run test
```

## Making Changes

### Code Style

- Use 4 spaces for indentation in PowerShell
- Use 2 spaces for indentation in JSON/XML
- Follow existing code patterns
- Add comments for complex logic

### Configuration Changes

When modifying `assets/installer-config.json`:
- Verify all URLs are valid
- Test with different configurations
- Update documentation

### Script Changes

When modifying PowerShell scripts:
- Test on clean Windows VM
- Check for proper error handling
- Update log messages
- Test both install and uninstall paths

### WiX Changes

When modifying `src/installer/Product.wxs`:
- Validate XML syntax
- Test MSI builds successfully
- Verify installation/uninstallation
- Check Add/Remove Programs behavior

## Testing

### Manual Testing

1. Build the MSI: `.\build.ps1`
2. Install on a clean Windows VM
3. Verify all components installed:
   - VS Code
   - Cline extension
   - LM Studio
   - AI model downloaded
   - Cline configured correctly
4. Test Cline functionality
5. Uninstall and verify cleanup

### Test Checklist

- [ ] MSI builds without errors
- [ ] Installation completes successfully
- [ ] VS Code launches
- [ ] Cline extension is installed and visible
- [ ] LM Studio is installed
- [ ] Model is downloaded to correct location
- [ ] Cline settings point to LM Studio
- [ ] Shortcuts created (desktop, start menu)
- [ ] Uninstallation removes all components
- [ ] No leftover files (except optional settings/models)

## Pull Request Process

1. Update documentation for any changed functionality
2. Test your changes thoroughly
3. Update the CHANGELOG.md if applicable
4. Create a pull request with a clear description:
   - What changes were made
   - Why the changes were necessary
   - How to test the changes
   - Screenshots if UI changes

### PR Title Format

- `feat: Add new feature`
- `fix: Fix bug description`
- `docs: Update documentation`
- `refactor: Code refactoring`
- `test: Add or update tests`
- `chore: Maintenance tasks`

## Reporting Issues

### Bug Reports

Include:
- Windows version
- PowerShell version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Installation logs (from `%TEMP%\LocalVibeCodingStack-install.log`)
- Screenshots if applicable

### Feature Requests

Include:
- Clear description of the feature
- Use case / motivation
- Proposed implementation (optional)
- Alternatives considered

## Component Version Updates

To update component versions:

1. Edit `assets/installer-config.json`
2. Update download URLs
3. Update version numbers
4. Test installation with new versions
5. Update README.md with new version info

## Adding New Components

To add a new component to the stack:

1. Add configuration to `assets/installer-config.json`
2. Update `scripts/install.ps1` with installation logic
3. Update `scripts/uninstall.ps1` with removal logic
4. Update `src/installer/Product.wxs` if needed
5. Update documentation
6. Test thoroughly

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

## Questions?

Open an issue with the `question` label or start a discussion.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

# Contributing to MediaKeyControls

Thank you for your interest in contributing! This project welcomes contributions, especially those focused on security, stability, and code quality.

## AI Development Notice

This project was built with assistance from Claude Code. We especially welcome contributions that:
- Review and improve AI-generated code
- Add comprehensive tests
- Identify and fix security vulnerabilities
- Improve error handling and edge cases

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the issue template (if available)
3. Include:
   - macOS version
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs or screenshots

### Suggesting Enhancements

1. Open an issue describing your idea
2. Explain the use case and benefit
3. Discuss implementation approach before coding

### Security Vulnerabilities

**DO NOT** report security issues publicly. See [SECURITY.md](SECURITY.md) for instructions.

## Pull Request Process

### Before You Start

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. For major changes, open an issue first to discuss

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/MediaKeyControls.git
cd MediaKeyControls

# Open in Xcode
open MediaKeyControls.xcodeproj
```

### Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Code Guidelines

1. **Swift Style**
   - Follow Swift API Design Guidelines
   - Use meaningful variable names
   - Add comments for complex logic
   - Keep functions focused and small

2. **Security First**
   - Review all accessibility permission usage
   - Validate all user inputs
   - Avoid hardcoded credentials
   - Follow principle of least privilege

3. **Testing**
   - Test on multiple macOS versions if possible
   - Verify accessibility permissions work correctly
   - Check for memory leaks
   - Test edge cases

4. **Documentation**
   - Update README if needed
   - Add inline comments for complex code
   - Update CHANGELOG.md (if it exists)

### Commit Messages

- Use clear, descriptive messages
- Start with a verb (Add, Fix, Update, Remove)
- Reference issue numbers if applicable

Examples:
```
Add volume control support (#123)
Fix crash when media player not found
Update README with new features
```

### Pull Request Checklist

- [ ] Code builds without warnings
- [ ] Tested on macOS (specify version)
- [ ] Added/updated tests if applicable
- [ ] Updated documentation if needed
- [ ] Followed code style guidelines
- [ ] No sensitive data in commits
- [ ] Branch is up to date with main

### Review Process

1. Maintainer will review your PR
2. Address any requested changes
3. Once approved, your PR will be merged
4. Delete your feature branch after merge

## Priority Contributions

We especially welcome:

- **Security audits and fixes** - Review AI-generated code
- **Test coverage** - Unit tests, integration tests
- **Bug fixes** - Stability improvements
- **macOS compatibility** - Testing on different versions
- **Performance optimizations** - Memory and CPU efficiency
- **Documentation** - Code comments, README improvements

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on the code, not the person
- Assume good intentions
- Keep discussions on topic

## Questions?

- Open an issue for questions
- Use GitHub Discussions if enabled
- Check existing issues/PRs first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make this project better and more secure!

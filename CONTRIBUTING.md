# Contributing to Pagy

Thank you for your interest in contributing to Pagy! We welcome contributions from the community.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on [GitHub Issues](https://github.com/hayatkhan67/pagy/issues) with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Flutter and Dart versions
- Any relevant code snippets or error messages

### Suggesting Enhancements

Feature requests are welcome! Please open an issue with:
- Clear description of the feature
- Use cases and examples
- Why this would be useful to other users

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Run `flutter test` to ensure all tests pass
6. Run `flutter analyze` to check for linting issues
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to your branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/pagy.git
cd pagy

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run example app
cd example
flutter run
```

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions small and focused
- Write tests for new features

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb in present tense (Add, Fix, Update, Remove)
- Reference issues when applicable (#123)

Example:
```
Add support for custom error messages

- Allows users to override default error messages
- Adds new configuration parameter
- Updates documentation

Fixes #123
```

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to make Pagy better!

## Questions?

Feel free to reach out:
- GitHub Issues: For bugs and features
- Email: hayatkhan626225@gmail.com
- LinkedIn: [Hayat Khan](https://www.linkedin.com/in/hayat-khan-263217281/)

Thank you for contributing to Pagy! 🎉

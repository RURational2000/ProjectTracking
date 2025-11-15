# Contributing to Project Tracking App

Thank you for your interest in contributing to the Project Tracking App! This document provides guidelines for creating and submitting pull requests.

## How to Initiate a Pull Request

### 1. Fork and Clone the Repository

First, fork the repository on GitHub, then clone your fork:

```bash
git clone https://github.com/YOUR-USERNAME/ProjectTracking.git
cd ProjectTracking
```

Add the upstream repository:

```bash
git remote add upstream https://github.com/RURational2000/ProjectTracking.git
```

### 2. Set Up Your Development Environment

Install dependencies:

```bash
flutter pub get
```

Verify the setup by running the app:

```bash
# For desktop
flutter run -d windows
# or
flutter run -d linux
```

### 3. Create a Feature Branch

Always create a new branch for your changes:

```bash
git checkout -b feature/your-feature-name
# or for bug fixes
git checkout -b fix/bug-description
```

Branch naming conventions:
- `feature/` - for new features
- `fix/` - for bug fixes
- `docs/` - for documentation changes
- `refactor/` - for code refactoring
- `test/` - for test additions/improvements

### 4. Make Your Changes

Follow the project's architecture patterns (see `.github/copilot-instructions.md`):
- **Dual-Write Consistency**: Database writes must have corresponding file logs
- **State Management**: Use Provider pattern with `TrackingProvider`
- **Empty Note Validation**: Validate notes before saving
- **Time Accumulation**: Update project totals when ending instances

Key files to understand:
- `lib/models/` - Data models
- `lib/services/` - Database and file logging
- `lib/providers/` - State management
- `lib/screens/` - UI screens
- `lib/widgets/` - Reusable UI components

### 5. Test Your Changes

Run tests to ensure nothing is broken:

```bash
flutter test
```

Run the app and manually verify your changes:

```bash
flutter run -d windows  # or your preferred platform
```

### 6. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git add .
git commit -m "Add feature: brief description of what you added"
```

Good commit message examples:
- `Add: Project export functionality`
- `Fix: Instance timing calculation bug`
- `Docs: Update README with installation steps`
- `Refactor: Simplify database query logic`

### 7. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 8. Create the Pull Request

1. Go to your fork on GitHub
2. Click the "Compare & pull request" button that appears after pushing
3. Ensure the base repository is `RURational2000/ProjectTracking` and base branch is correct (usually `main`)
4. Fill in the PR template with:
   - **Title**: Clear, concise description of the change
   - **Description**: What changes were made and why
   - **Related Issues**: Reference any related issue numbers using `#issue-number`
   - **Testing**: Describe how you tested the changes
   - **Screenshots**: Include screenshots for UI changes
5. Click "Create pull request"

### 9. Respond to Review Feedback

- Address reviewer comments promptly
- Make requested changes in new commits
- Push updates to the same branch (they'll automatically appear in the PR)
- Re-request review after addressing feedback

## Code Quality Guidelines

### Code Style

Follow Dart/Flutter best practices:
- Use `flutter analyze` to check for issues
- Format code with `dart format .`
- Follow the existing code style in the project

### Documentation

- Add comments for complex logic
- Update README.md if adding new features
- Update `.github/copilot-instructions.md` for architectural changes

### Testing

- Add tests for new features
- Ensure existing tests pass
- Test on multiple platforms if possible (Windows, Linux, Android)

## Pull Request Checklist

Before submitting your PR, verify:

- [ ] Code follows the project's architecture patterns
- [ ] All tests pass (`flutter test`)
- [ ] Code is formatted (`dart format .`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Commit messages are clear and descriptive
- [ ] PR description explains what and why
- [ ] Documentation is updated if needed
- [ ] Screenshots included for UI changes
- [ ] Branch is up to date with upstream main

## Getting Help

If you have questions:
- Check the [README.md](README.md) for project overview
- Review `.github/copilot-instructions.md` for architecture details
- Open an issue for discussion before major changes
- Ask questions in your PR if you need clarification

## Code of Conduct

- Be respectful and constructive in all interactions
- Focus on the code, not the person
- Welcome newcomers and help them learn
- Assume good intentions

Thank you for contributing! 🎉

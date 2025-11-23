# Project Tracking App - AI Coding Agent Instructions

## Quick Reference

**Essential Commands:**
```bash
flutter pub get              # Install dependencies
flutter analyze              # Check for issues
dart format .                # Format code
flutter test                 # Run tests
flutter run -d windows       # Run on Windows
flutter run -d linux         # Run on Linux
```

## Architecture Overview

This is a **Flutter/Dart cross-platform time tracking app** with dual-storage architecture:

1. **SQLite Database** (`DatabaseService`): Structured relational storage for queries
2. **Text File Logs** (`FileLoggingService`): Human-readable audit trail per project

### Core Data Model (3-tier hierarchy)
- **Project**: Container entity with accumulated time from all instances
- **Instance**: Single work session with start/end timestamps (one active at a time)
- **Note**: Text entries linked to instances (multiple notes per instance allowed)

**Critical Business Rule**: Starting a new project automatically ends the previous active instance. This is handled in `TrackingProvider.startProject()`.

## Project Structure & Key Files

```
lib/
├── models/               # Plain Dart classes with toMap/fromMap for DB serialization
├── services/
│   ├── database_service.dart        # All SQLite operations, schema defined in _onCreate()
│   └── file_logging_service.dart    # Parallel logging to {ProjectName}_log.txt files
├── providers/
│   └── tracking_provider.dart       # State management: coordinates DB + file logging in sync
├── screens/
│   └── home_screen.dart             # Main layout with conditional ActiveTrackingPanel
└── widgets/                         # UI components using Consumer<TrackingProvider>
```

## Code Style & Conventions

### Dart/Flutter Style
- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format .` to auto-format code
- Run `flutter analyze` before committing to catch issues
- Enable the linter rules defined in `analysis_options.yaml`:
  - `prefer_const_constructors`: Use const constructors where possible
  - `prefer_const_literals_to_create_immutables`: Use const for immutable collections
  - `prefer_final_fields`: Make fields final when they don't change
  - `unnecessary_this`: Avoid using `this` when not needed

### Naming Conventions
- **Files**: Use snake_case (e.g., `tracking_provider.dart`)
- **Classes**: Use PascalCase (e.g., `TrackingProvider`, `DatabaseService`)
- **Variables/Methods**: Use camelCase (e.g., `startProject`, `currentInstance`)
- **Constants**: Use lowerCamelCase (e.g., `defaultTimeout`)
- **Private members**: Prefix with underscore (e.g., `_onCreate`, `_addNote`)

### Import Organization
1. Dart/Flutter SDK imports
2. Package imports
3. Relative imports
4. Separate groups with a blank line

Example:
```dart
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../services/database_service.dart';
```

## Critical Implementation Patterns

### 1. Dual-Write Consistency
**Every database write MUST have a corresponding file log**. See `TrackingProvider`:
- `startProject()`: DB insert → file log
- `endCurrentInstance()`: DB update (instance + project totals) → file log with all notes
- `addNote()`: DB insert → file log

### 2. Time Accumulation Strategy
Time is accumulated at the **Project** level, not calculated on-the-fly:
- Instance duration calculated: `endTime.difference(startTime).inMinutes`
- Stored in `Instance.durationMinutes` 
- Added to `Project.totalMinutes` in `endCurrentInstance()`

### 3. Empty Note Validation
Notes are **only saved when non-empty**:
- `DatabaseService.insertNote()` throws `ArgumentError` if `content.trim().isEmpty`
- UI validation in `ActiveTrackingPanel._addNote()` before calling provider

### 4. State Management Pattern
Use **Provider** with `ChangeNotifier`:
- `TrackingProvider` is the single source of truth
- UI uses `Consumer<TrackingProvider>` for reactive updates
- Always call `notifyListeners()` after state changes

### 5. Error Handling
Follow consistent error handling patterns:
- **Database errors**: Catch and log, show user-friendly message via SnackBar
- **File I/O errors**: Log to console, continue operation (file logging is supplementary)
- **Validation errors**: Throw `ArgumentError` with descriptive message (e.g., empty notes)
- **UI errors**: Use `try-catch` in event handlers, show error to user
- **Async operations**: Always handle errors in `async` methods

Example pattern:
```dart
try {
  await databaseService.insertNote(note);
  await fileLoggingService.logNote(note);
  notifyListeners();
} catch (e) {
  debugPrint('Error adding note: $e');
  // Show error to user via SnackBar
  rethrow; // or handle gracefully
}
```

## Development Workflows

### Initial Setup
```bash
# Install dependencies
flutter pub get
```

### Code Quality & Linting
```bash
# Run analyzer to check for issues
flutter analyze

# Format code according to Dart style guide
dart format .

# Check formatting without making changes
dart format --output=none --set-exit-if-changed .
```

### Building the App
```bash
# Build for Android
flutter build apk           # Debug APK
flutter build apk --release # Release APK
flutter build appbundle     # Android App Bundle for Play Store

# Build for Windows
flutter build windows --release

# Build for Linux
flutter build linux --release

# Build for iOS (requires macOS with Xcode)
flutter build ios --release
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Running the App
```bash
# Desktop
flutter run -d windows
flutter run -d linux

# Mobile (requires emulator/device)
flutter run -d android
flutter run -d ios

# List available devices
flutter devices
```

### Adding New Features
1. **Model changes**: Update model class → update `DatabaseService._onCreate()` schema → migration logic
2. **UI changes**: Create widget in `lib/widgets/` → use `Consumer<TrackingProvider>`
3. **Business logic**: Add method to `TrackingProvider` → coordinate DB + file service → call `notifyListeners()`

### Testing Database Changes
- Delete app data to recreate DB with new schema during development
- Check SQLite files in platform-specific locations (see README.md)
- Verify text logs in `{AppDocuments}/ProjectTrackingLogs/` directory

## Debugging & Troubleshooting

### Common Issues
1. **Build failures after adding dependencies**: Run `flutter pub get` and restart IDE
2. **Hot reload not working**: Use hot restart (`Shift+R` in terminal) or full restart
3. **Database schema errors**: Delete app data to recreate database with new schema
4. **Platform-specific build errors**: 
   - Windows: Ensure Visual Studio 2022 with C++ tools installed
   - Linux: Install GTK development libraries (`sudo apt-get install libgtk-3-dev`)
   - Android: Check Android SDK configuration in Android Studio

### Debugging Tools
```bash
# Enable verbose logging
flutter run --verbose

# Debug with DevTools
flutter run --observatory-port=8888
# Then open Chrome DevTools

# View device logs
flutter logs

# Clear build cache (if build issues persist)
flutter clean
flutter pub get
```

### Database Inspection
- **Desktop**: Use SQLite browser tools to inspect database files
- **Android**: Use ADB to pull database file
  ```bash
  adb pull /data/data/com.example.project_tracking/databases/project_tracking.db
  ```
- **Log files**: Check `ProjectTrackingLogs/` directory in app documents for human-readable logs

## Dependencies & Platform-Specific Notes

### Key Packages
- `sqflite`: Cross-platform SQLite (desktop support via `sqflite_common_ffi`)
- `path_provider`: Platform-specific storage paths
- `provider`: State management
- `intl`: Date formatting for log files

### Platform Considerations
- **Android**: Requires storage permissions in `AndroidManifest.xml` (already configured)
- **Windows**: Set app title in `windows/runner/main.cpp` 
- **iOS**: Configure in `Info.plist` (not created yet - run `flutter create .` to generate)
- **Linux**: GTK dependencies required on host system

## Common Tasks

### Extending the Data Model
1. Add field to model class (e.g., `Project.description`)
2. Update `toMap()` and `fromMap()` methods
3. Update `DatabaseService._onCreate()` CREATE TABLE statement
4. Update corresponding `insert`/`update` methods if needed
5. Add to file logging format in `FileLoggingService`

### Adding a New Screen
1. Create file in `lib/screens/`
2. Import `TrackingProvider` and use `Consumer` widget
3. Navigate using `Navigator.push()` from existing screen
4. Access provider: `Provider.of<TrackingProvider>(context, listen: false)` for actions

### Modifying Log File Format
Edit `FileLoggingService.logInstanceStart/End()` methods. Format uses:
- `DateFormat('yyyy-MM-dd HH:mm:ss')` for timestamps
- Separator lines: `===` (80 chars) for instance boundaries
- Separator lines: `---` for note sections

## Architecture Decisions (The "Why")

1. **Dual Storage**: Database for app queries + text files for user verification/backup without needing DB tools
2. **Auto-End Previous Instance**: Prevents multiple active instances which would complicate time tracking
3. **Minute-Based Timing**: Simpler than seconds, sufficient granularity for work tracking
4. **Provider Pattern**: Flutter-native state management, simpler than BLoC for this app size
5. **Per-Project Log Files**: Easier to find/share logs than single monolithic file

## Contributing

### Pull Request Process
1. Create a feature branch from `main`: `git checkout -b feature/description`
2. Make minimal, focused changes following the patterns above
3. Run quality checks before committing:
   ```bash
   flutter analyze
   dart format .
   flutter test
   ```
4. Commit with clear messages: `"Add: feature description"` or `"Fix: bug description"`
5. Push to your fork and create PR
6. Fill out PR template with description, testing notes, and screenshots (for UI changes)

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

### Before Submitting PR
- [ ] Code follows architecture patterns (dual-write, state management, etc.)
- [ ] Tests pass: `flutter test`
- [ ] Code formatted: `dart format .`
- [ ] No analyzer warnings: `flutter analyze`
- [ ] Documentation updated if needed
- [ ] Screenshots included for UI changes

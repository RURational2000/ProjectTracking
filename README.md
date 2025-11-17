# Project Tracking App

A cross-platform time tracking application for managing projects with instance-based logging and notes.

## Features

- **Project Management**: Create and select projects to track
- **Instance Tracking**: Start/stop work sessions (instances) with automatic time accumulation
- **Multiple Notes**: Add multiple notes per instance, saved only when non-empty
- **Dual Storage**: SQLite database for querying + text file logs for verification
- **Cross-Platform**: Runs on Android, iOS, Windows, and Linux

## Architecture

### Data Model
- **Project**: Container with accumulated time across all instances
- **Instance**: Single work session with start/end timestamps
- **Note**: Text entry associated with an instance

### Storage Strategy
1. **SQLite Database** (`DatabaseService`): Primary storage for structured queries and relationships
2. **Text File Logs** (`FileLoggingService`): Human-readable audit trail per project

### Key Behaviors
- Starting a new project automatically ends the previous active instance
- Notes are validated (non-empty) before saving to database and log files
- Time is accumulated at the project level from completed instances
- Each project gets its own log file: `{ProjectName}_log.txt`

## Project Structure

```
.gitignore - files and folders to ignore, including build, auto-generated, and deployment items
README.md - main instructions for the app
pubspec.yaml - flutter configuration file
.dart_tool - local repository of tools and dependencies used by the flutter pub command
.github - workflows and git hub specific instructions
.idea - folder containing android development studio artifacts; needed for development
android - gradle build items
ios - iOS xcode build items
windows - build items for windows
linux - build items for linux
test - container Project Tracking unit tests
lib/
├── main.dart                          # App initialization with service setup
├── models/                            # Data models (Project, Instance, Note)
├── services/
│   ├── database_service.dart         # SQLite operations
│   └── file_logging_service.dart     # Text file logging
├── providers/
│   └── tracking_provider.dart        # State management & business logic
├── screens/
│   └── home_screen.dart              # Main screen layout
└── widgets/                           # UI components
    ├── active_tracking_panel.dart    # Current instance display & note input
    ├── project_list.dart             # Project selection list
    └── new_project_dialog.dart       # Project creation dialog
```

## Development

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+

### Setup
```bash
flutter pub get
```

### Run
```bash
# Desktop (Windows/Linux)
flutter run -d windows
flutter run -d linux

# Mobile
flutter run -d android
flutter run -d ios
```

### Database Location
- **Android**: `/data/data/com.example.project_tracking/databases/`
- **iOS**: App's Documents directory
- **Windows**: `%APPDATA%\com.example\project_tracking\databases\`
- **Linux**: `~/.local/share/project_tracking/databases/`

### Log Files Location
- **All platforms**: Application Documents directory under `ProjectTrackingLogs/`

## Testing
```bash
flutter test
```

## Build
```bash
# Android APK
flutter build apk

# Windows
flutter build windows

# iOS (requires macOS)
flutter build ios
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on how to:
- Set up your development environment
- Create and submit pull requests
- Follow code quality standards
- Test your changes

## License

This project is open source. Please check the repository for license details.

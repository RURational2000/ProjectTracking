# Project Tracking App

A cross-platform time tracking application for managing projects with
instance-based logging and notes.

## Features

- **Project Management**: Create and select projects to track with status tracking
- **Instance Tracking**: Start/stop work sessions (instances) with automatic
  time accumulation
- **Time Display Modes**: View project time as current instance, daily, weekly,
  monthly, or complete totals
- **Multiple Notes**: Add multiple notes per instance, saved only when non-empty
- **Cloud Storage**: Supabase-powered PostgreSQL database with real-time synchronization
- **Multi-User Support**: Individual user identification with Row-Level Security
- **Dual Storage**: Cloud database for querying + text file logs for local verification
- **Cross-Platform**: Runs on Android, iOS, Windows, and Linux

### Time Display Modes

The app includes a global time display mode selector (clock icon in the
app bar) that allows you to view project time in different contexts:

#### Available Modes

1. **Instance Mode**
   - Shows the duration of the currently active instance
   - Updates every 30 seconds for real-time tracking
   - Only active project shows time (others show 0)
   - Label format: "Instance: Xh Ym"

2. **Day Mode**
   - Shows total time worked on each project today
   - Includes all completed instances that started today
   - Label format: "Day: Xh Ym"

3. **Week Mode**
   - Shows total time worked this week (Monday-Sunday)
   - Includes all completed instances from the current week
   - Label format: "Week: Xh Ym"

4. **Month Mode**
   - Shows total time worked this month
   - Includes all completed instances from the current month
   - Label format: "Month: Xh Ym"

5. **Project Mode** (Default)
   - Shows the complete accumulated time for each project
   - This is the original behavior
   - Label format: "Project: Xh Ym"

#### How to Use

1. Tap the clock icon (⏰) in the top-right corner of the app bar
2. Select your desired display mode from the popup menu
3. The selected mode is indicated with a checkmark (✓)
4. Project times update automatically to reflect the selected view
5. Mode selection persists in memory until the app is restarted

## Architecture

### Data Model

- **Project**: Container with accumulated time across all instances, owned by a user
- **Instance**: Single work session with start/end timestamps
- **Note**: Text entry associated with an instance

### Storage Strategy

1. **Supabase (PostgreSQL)** (`DatabaseService`): Cloud-based primary storage for structured
   queries, relationships, and multi-user support with real-time synchronization
2. **Text File Logs** (`FileLoggingService`): Human-readable audit trail
   per project (local device storage)

### Key Behaviors

- Starting a new project automatically ends the previous active instance
- Notes are validated (non-empty) before saving to database and log files
- Time is accumulated at the project level from completed instances
- Each project gets its own log file: `{ProjectName}_log.txt`

### Time Display Implementation

The time display modes feature uses efficient database queries to calculate
time based on the selected view:

- **Instance Mode**: Calculates duration from active instance start time
  (no database query needed)
- **Day/Week/Month Modes**: SQL `SUM(durationMinutes)` queries with date
  range filters
- **Project Mode**: Uses pre-accumulated `totalMinutes` from project table
- All queries use existing database indexes for optimal performance
- Only completed instances (with `endTime`) are included in calculations

## Project Structure

```text
.gitignore - files and folders to ignore, including build, auto-generated,
             and deployment items
README.md - main instructions for the app
pubspec.yaml - flutter configuration file
.dart_tool - local repository of tools and dependencies used by the
             flutter pub command
.github - workflows and git hub specific instructions
.idea - folder containing android development studio artifacts; needed for development
android - gradle build items
ios - iOS xcode build items
windows - build items for windows
linux - build items for linux
test - container Project Tracking unit tests
lib/
├── main.dart                          # App initialization with service setup
├── models/                            # Data models
│   ├── project.dart                   # Project model
│   ├── instance.dart                  # Instance model
│   ├── note.dart                      # Note model
│   └── time_display_mode.dart         # Time display mode enum
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

**Supabase Cloud Database:**

- Centralized PostgreSQL database hosted on Supabase
- Accessible from all devices with internet connection
- Provides authentication, real-time sync, and Row-Level Security
- See [implementation-quick-start.md](docs/implementation-quick-start.md) for setup details

### Log Files Location

- **All platforms**: Application Documents directory under
  `ProjectTrackingLogs/`
-- Windows Location: C:\Users\<user name>\OneDrive\Documents\ProjectTrackingLogs
-- Android Location: Android/data/com.example.project_tracking/files/ProjectTrackingLogs/

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

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for
detailed guidelines on how to:

- Set up your development environment
- Create and submit pull requests
- Follow code quality standards
- Test your changes

## License

This project is open source. Please check the repository for license details.

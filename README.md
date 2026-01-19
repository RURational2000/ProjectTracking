# Project Tracking App

A cross-platform time tracking application for managing projects and time with
instance-based logging and notes.  Text based note files (not available on the web-
based version) are designed for easy user augmentation using Notepad (or similar
text editor) independent of the app.

## Features

- **Project Management**: Create and select projects to track time spent.
  Projects may also be regular blocks of time such as 'Morning Chores' or
  'Catch Up on Emails'. Projects may be renamed or deleted.
- **Instance Tracking**: Start/stop work sessions (instances) with automatic
  time accumulation.
- **Time Display Modes**: View project time as current instance, daily, weekly,
  monthly, or complete totals.
- **Multiple Notes**: Add multiple notes per instance, saved only when non-empty.
- **Export Capability**: Export project time logs and notes in CSV or text format
  with preview before saving.
- **Cloud Storage**: Supabase-powered PostgreSQL database with real-time synchronization.
- **Multi-User Support**: Individual user identification with Row-Level Security.
- **Dual Storage**: Cloud database for querying + text file logs for local
  verification and additional notes.
- **Cross-Platform**: Runs on Android, iOS, Windows, and Linux.  A web version
  is available for demo purposes where separate text logging is not supported.
- **Adjustable End Time**: Click on the end time to adjust length of instance,
  e.g. when instance was not properly closed.
  
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

### Export Capability

The app provides comprehensive export functionality for project data, allowing you to extract time logs and notes for analysis, reporting, or archival purposes.

#### Export Formats

1. **Time Log (CSV)**
   - One line per instance in descending chronological order (most recent first)
   - Columns: Date, Start Time, End Time, Duration (minutes), Duration (hours), Description, Week, Month
   - Description field contains the last note from each instance
   - Includes weekly summaries section (total minutes and hours per week)
   - Includes monthly summaries section (total minutes and hours per month)
   - Compatible with Excel, Google Sheets, and other spreadsheet applications

2. **Notes (Text)**
   - All notes grouped by instance
   - Instances displayed in descending chronological order
   - Each instance shows: date/time range, duration, and all associated notes
   - Notes include timestamps for when they were created
   - Human-readable format ideal for review and documentation

#### How to Export

1. Locate the project you want to export in the project list
2. Click the download icon (📥) next to the project name
3. In the export dialog:
   - Select your desired export format (Time Log CSV or Notes Text)
   - Review the preview to ensure data is correct
   - Click "Export" to save the file
4. Files are saved to the `ProjectTrackingExports` directory:
   - **Windows**: `C:\Users\<username>\Documents\ProjectTrackingExports\`
   - **Linux**: `~/Documents/ProjectTrackingExports/`
   - **Android**: `/storage/emulated/0/Android/data/com.example.project_tracking/files/ProjectTrackingExports/`
   - **iOS**: `<App Container>/Documents/ProjectTrackingExports/`
5. Filenames include the project name and timestamp: `ProjectName_2024-01-15T10-30-00.csv`

#### Use Cases

- **Client Billing**: Export time logs to calculate billable hours
- **Project Analysis**: Analyze time spent across different periods
- **Record Keeping**: Archive project data for future reference
- **Reporting**: Import into spreadsheets for custom reports and visualizations
- **Documentation**: Export notes for project documentation or handoffs

## Architecture

### Data Model

- **Project**: Container with accumulated time across all instances, owned by a user
- **Instance**: Single work session with start/end timestamps
- **Note**: Text entry associated with an instance
- **UserProfile**: User profile associated with the instance

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
.vscode - folder containing visual studio artifacts
android - gradle build items
build - contains build artifacts and also the web build for publishing
docs - supporting documents for the application 
ios - iOS xcode build items
linux - build items for linux
macos - macOS xcode build items
supabase - supabase database build items
test - container Project Tracking unit tests
web - web build items
windows - build items for windows
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

Log files are stored in platform-specific user-accessible locations:

- **Windows**: `C:\Users\<username>\Documents\ProjectTrackingLogs\`
  - Easily accessible via File Explorer
  
- **Linux**: `~/Documents/ProjectTrackingLogs/`
  - Accessible via file manager
  
- **Android**: External storage at `/storage/emulated/0/Android/data/com.example.project_tracking/files/ProjectTrackingLogs/`
  - Accessible via file manager apps (e.g., Files by Google, Samsung My Files)
  - Navigate to: Internal Storage → Android → data → com.example.project_tracking → files → ProjectTrackingLogs
  - Files persist after app updates but are removed on app uninstall
  
- **iOS**: `<App Container>/Documents/ProjectTrackingLogs/`
  - Accessible via Files app when file sharing is enabled
  - To enable file sharing, add these keys to `ios/Runner/Info.plist`:

    ```xml
    <key>UIFileSharingEnabled</key>
    <true/>
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
    ```

  - After enabling, logs can be accessed: Files app → On My iPhone → Project Tracking → ProjectTrackingLogs

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

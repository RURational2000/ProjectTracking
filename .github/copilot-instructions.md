# Project Tracking App - AI Coding Agent Instructions

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

## Development Workflows

### Running the App
```bash
# Desktop
flutter run -d windows
flutter run -d linux

# Mobile (requires emulator/device)
flutter run -d android
flutter run -d ios
```

### Adding New Features
1. **Model changes**: Update model class → update `DatabaseService._onCreate()` schema → migration logic
2. **UI changes**: Create widget in `lib/widgets/` → use `Consumer<TrackingProvider>`
3. **Business logic**: Add method to `TrackingProvider` → coordinate DB + file service → call `notifyListeners()`

### Testing Database Changes
- Delete app data to recreate DB with new schema during development
- Check SQLite files in platform-specific locations (see README.md)
- Verify text logs in `{AppDocuments}/ProjectTrackingLogs/` directory

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

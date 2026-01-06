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

**Supabase Setup:**
```bash
# View Supabase project configuration
cat supabase/README.md

# Apply database migrations (via Supabase CLI)
supabase db push

# View migration files
ls supabase/migrations/
```

**Essential Supabase Resources:**
- Supabase Dashboard: `https://supabase.com/dashboard/project/YOUR_PROJECT_REF/`
- Table Editor: View and edit data directly
- SQL Editor: Run queries and test migrations
- API Docs: Auto-generated based on your schema
- See `docs/implementation-quick-start.md` for detailed setup instructions

## Architecture Overview

This is a **Flutter/Dart cross-platform time tracking app** with dual-storage architecture:

1. **Supabase (PostgreSQL)** (`DatabaseService`): Cloud-based primary storage for structured queries, relationships, and multi-user support with real-time synchronization
2. **Text File Logs** (`FileLoggingService`): Human-readable audit trail per project (local device storage)

### Core Data Model (4-tier hierarchy with user ownership)
- **User Profile**: User authentication and profile information (managed by Supabase Auth)
- **Project**: Container entity with accumulated time from all instances, owned by a user
- **Instance**: Single work session with start/end timestamps (one active at a time per user)
- **Note**: Text entries linked to instances (multiple notes per instance allowed)

**Critical Business Rule**: Starting a new project automatically ends the previous active instance. This is handled in `TrackingProvider.startProject()`.

**Security Model**: Row-Level Security (RLS) ensures users can only access their own data at the database level.

## Project Structure & Key Files

```
lib/
├── models/               # Plain Dart classes with toMap/fromJson for Supabase serialization
├── services/
│   ├── database_service.dart        # All Supabase/PostgreSQL operations, schema in supabase/migrations/
│   └── file_logging_service.dart    # Parallel logging to {ProjectName}_log.txt files
├── providers/
│   └── tracking_provider.dart       # State management: coordinates Supabase + file logging in sync
├── screens/
│   └── home_screen.dart             # Main layout with conditional ActiveTrackingPanel
└── widgets/                         # UI components using Consumer<TrackingProvider>

supabase/
├── migrations/                      # PostgreSQL schema migrations with RLS policies
│   └── 001_initial_schema.sql      # Initial schema: projects, instances, notes, user_profiles
└── README.md                        # Supabase backend implementation guide
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
- **Private members**: Prefix with underscore (e.g., `_initialize`, `_addNote`)

**PostgreSQL/Supabase Database Naming:**
- **Tables**: Use snake_case (e.g., `projects`, `user_profiles`, `instances`)
- **Columns**: Use snake_case (e.g., `user_id`, `created_at`, `total_minutes`, `parent_project_id`)
- **Indexes**: Prefix with `idx_` and use snake_case (e.g., `idx_projects_user_id`, `idx_instances_startTime`)
- **Foreign Keys**: Prefix with `fk_` and use snake_case (e.g., `fk_instances_projects`, `fk_notes_instances`)
- **Functions**: Use snake_case (e.g., `handle_updated_at`)
- **Triggers**: Use snake_case (e.g., `on_user_profiles_updated`)
- **RLS Policies**: Use descriptive names with spaces (e.g., `"Users can view own projects"`)

**Mapping Between Dart and PostgreSQL:**
- Dart `camelCase` fields map to PostgreSQL `snake_case` columns
- Use `toMap()`/`fromJson()` methods in models to handle the conversion
- Example: Dart `userId` ↔ PostgreSQL `user_id`, Dart `createdAt` ↔ PostgreSQL `created_at`

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

## Supabase-Specific Best Practices

### Authentication and User Context
- **Always check auth state**: Verify user is authenticated before database operations
- **Handle auth state changes**: Listen for auth state changes and update UI accordingly
- **User ID propagation**: Always include `user_id` when creating records (projects, instances)
- **Token refresh**: Implement automatic token refresh to prevent session expiration
- **Logout handling**: Clear local state when user logs out

### Row-Level Security (RLS) Considerations
- **RLS is always active**: All queries are filtered by RLS policies automatically
- **Test with multiple users**: Create test accounts to verify data isolation
- **Empty results**: If queries return empty unexpectedly, check RLS policies first
- **Error messages**: RLS violations may appear as "permission denied" errors
- **Policy updates**: Changes to RLS policies require database migration

### Query Optimization
- **Use indexes**: Leverage existing indexes (see `supabase/migrations/001_initial_schema.sql`)
- **Limit results**: Use `.limit()` to prevent fetching unnecessary data
- **Select specific columns**: Use `.select('column1, column2')` instead of fetching all columns
- **Batch operations**: Group multiple inserts/updates when possible
- **Real-time subscriptions**: Use sparingly - they consume resources

### Error Handling Patterns
- **Network errors**: Handle offline scenarios gracefully
  ```dart
  try {
    await supabase.from('projects').insert(data);
  } on PostgrestException catch (e) {
    // Handle database-specific errors (RLS, constraints, etc.)
    debugPrint('Database error: ${e.message}');
  } catch (e) {
    // Handle network and other errors
    debugPrint('Error: $e');
  }
  ```
- **Constraint violations**: Handle unique constraints, foreign keys
- **RLS failures**: Inform user if they lack permission

### Data Synchronization
- **Optimistic updates**: Update UI immediately, rollback on error
- **Conflict resolution**: Handle concurrent edits by multiple users
- **Offline support**: Consider caching strategy for offline usage (future enhancement)

### Security Best Practices
- **Never expose service role key**: Only use anon key in client applications
- **Validate input**: Sanitize user input before database operations
- **Use parameterized queries**: Supabase client handles this automatically
- **Audit logging**: Use database triggers for sensitive operations (see user_profiles example)
- **Regular RLS review**: Periodically audit RLS policies for security gaps

## Critical Implementation Patterns

### 1. Dual-Write Consistency
**Every database write MUST have a corresponding file log**. See `TrackingProvider`:
- `startProject()`: Supabase insert → file log
- `endCurrentInstance()`: Supabase update (instance + project totals) → file log with all notes
- `addNote()`: Supabase insert → file log

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
- **Network errors**: Handle Supabase connection issues gracefully (offline mode considerations)
- **Authentication errors**: Handle auth state changes and token expiration

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

### 6. Row-Level Security (RLS) Awareness
**All database operations are subject to RLS policies**:
- Users can only access their own projects, instances, and notes
- RLS is enforced at the PostgreSQL level, not in application code
- Always include `user_id` when creating new records
- Failed RLS checks throw authorization errors - handle appropriately
- Test RLS policies with different user accounts to ensure proper isolation

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
1. **Model changes**: 
   - Update model class with new fields
   - Update `toMap()`/`fromJson()` methods to include new fields
   - Create a migration SQL file in `supabase/migrations/` (e.g., `002_add_field.sql`)
   - Apply migration via Supabase dashboard or CLI: `supabase db push`
   - Update corresponding service methods if needed
   - Add to file logging format in `FileLoggingService`
2. **UI changes**: Create widget in `lib/widgets/` → use `Consumer<TrackingProvider>`
3. **Business logic**: Add method to `TrackingProvider` → coordinate Supabase + file service → call `notifyListeners()`

### Testing Database Changes
- Use Supabase dashboard SQL editor to test queries and schema changes
- Test RLS policies by creating multiple test users and verifying data isolation
- Monitor real-time updates in Supabase dashboard while using the app
- Verify text logs in `{AppDocuments}/ProjectTrackingLogs/` directory
- Use Supabase's built-in table editor to inspect and modify data during development

## Debugging & Troubleshooting

### Common Issues
1. **Build failures after adding dependencies**: Run `flutter pub get` and restart IDE
2. **Hot reload not working**: Use hot restart (`Shift+R` in terminal) or full restart
3. **Database connection errors**: 
   - Check internet connectivity (Supabase requires active connection)
   - Verify Supabase project URL and anon key in environment configuration
   - Check Supabase dashboard for service status
4. **Authentication issues**:
   - Verify user is properly authenticated before database operations
   - Check token expiration and refresh logic
   - Review RLS policies if queries return empty results
5. **Platform-specific build errors**: 
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
- **Supabase Dashboard**: 
  - Use the Table Editor to view and edit data directly
  - SQL Editor for running custom queries and testing
  - Database > Roles to manage RLS and permissions
  - Logs section to monitor database activity and errors
- **PostgreSQL Tools**: 
  - Use tools like pgAdmin, DBeaver, or DataGrip to connect to Supabase PostgreSQL
  - Connection details available in Supabase dashboard > Project Settings > Database
  - Requires database password (set during project creation)
- **Log files**: Check `ProjectTrackingLogs/` directory in app documents for human-readable logs
- **Real-time Monitoring**: 
  - Use Supabase Realtime feature to watch database changes live
  - Monitor network requests in browser DevTools when testing web version

## Dependencies & Platform-Specific Notes

### Key Packages
- `supabase_flutter`: Supabase client for Flutter with auth, database, and realtime features
- `path_provider`: Platform-specific storage paths for local file logging
- `provider`: State management
- `intl`: Date formatting for log files
- **Note**: Previous SQLite dependencies (`sqflite`, `sqflite_common_ffi`) have been replaced by Supabase

### Platform Considerations
- **Android**: Requires internet permissions in `AndroidManifest.xml` for Supabase connectivity
- **Windows**: Set app title in `windows/runner/main.cpp` 
- **iOS**: Configure in `Info.plist` and ensure proper permissions for network access
- **Linux**: GTK dependencies required on host system
- **All platforms**: Require active internet connection for Supabase database operations

## Common Tasks

### Extending the Data Model
1. Add field to model class (e.g., `Project.description`)
2. Update `toMap()` and `fromJson()` methods to include the new field
3. Create a new migration file in `supabase/migrations/` (e.g., `00X_add_description.sql`):
   ```sql
   -- Migration: 00X_add_description.sql
   -- Description: Add description field to projects table
   BEGIN;
   ALTER TABLE projects ADD COLUMN description TEXT;
   COMMIT;
   ```
4. Apply migration via Supabase CLI or dashboard SQL editor
5. Update corresponding service methods if needed
6. Add to file logging format in `FileLoggingService`
7. Test with existing data to ensure backward compatibility

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

### Creating Database Migrations
1. **File naming**: Use sequential numbers: `00X_description.sql` (e.g., `002_add_status_field.sql`)
2. **Always use transactions**: Wrap changes in `BEGIN;` and `COMMIT;` to ensure atomicity
3. **Include metadata**: Add header comment with description, date, author, related PR
4. **Test first**: Test SQL in Supabase dashboard SQL editor before creating migration file
5. **Consider RLS**: Update RLS policies if adding new tables or changing access patterns
6. **Indexes**: Add indexes for new columns used in WHERE clauses or JOINs
7. **Backwards compatibility**: Consider impact on existing data and deployed apps

Example migration template:
```sql
-- Migration: 00X_feature_name.sql
-- Description: Brief description of changes
-- Date: YYYY-MM-DD
-- Author: Your name
-- Related PR: #XX

BEGIN;

-- Your schema changes here
ALTER TABLE table_name ADD COLUMN new_column TYPE;

-- Update indexes if needed
CREATE INDEX idx_table_newcolumn ON table_name(new_column);

-- Update RLS policies if needed

COMMIT;
```

## Architecture Decisions (The "Why")

1. **Supabase (PostgreSQL) Cloud Database**: 
   - Provides multi-user support with built-in authentication
   - Row-Level Security (RLS) for fine-grained access control at database level
   - Real-time synchronization capabilities for future enhancements
   - Managed infrastructure reduces operational complexity
   - Free tier suitable for initial deployment (500MB database, 2GB bandwidth)
2. **Dual Storage**: Cloud database for app queries + text files for user verification/backup without needing DB tools
3. **Auto-End Previous Instance**: Prevents multiple active instances which would complicate time tracking
4. **Minute-Based Timing**: Simpler than seconds, sufficient granularity for work tracking
5. **Provider Pattern**: Flutter-native state management, simpler than BLoC for this app size
6. **Per-Project Log Files**: Easier to find/share logs than single monolithic file
7. **snake_case for PostgreSQL**: Follows PostgreSQL/SQL standard conventions, different from Dart's camelCase

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
- [ ] Code follows architecture patterns (dual-write, state management, RLS awareness, etc.)
- [ ] Tests pass: `flutter test`
- [ ] Code formatted: `dart format .`
- [ ] No analyzer warnings: `flutter analyze`
- [ ] Database migrations tested in Supabase dashboard
- [ ] RLS policies verified with multiple test users (if applicable)
- [ ] Documentation updated if needed
- [ ] Screenshots included for UI changes
- [ ] Environment variables/secrets not committed to repository

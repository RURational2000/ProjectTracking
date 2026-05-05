# Flutter Export Service Test Documentation

## Overview

This document describes the test suite for the Flutter ProjectTracking application, with a focus on the export service functionality.

## Test Files

### Primary Test Suite
- **`test/export_service_test.dart`** - Complete test suite for the export service (15 tests)

### Supporting Test Files
- **`test/widget_test.dart`** - Widget integration tests
- **`test/duration_test.dart`** - Duration calculation tests  
- **`test/widget_active_tracking_flow_test.dart`** - Active tracking flow tests
- **`test/widget_new_project_dialog_test.dart`** - Project dialog tests

### Test Mocks
- **`test/mocks/fake_database_service.dart`** - In-memory database implementation for tests
- **`test/mocks/fake_file_logging_service.dart`** - Mock file logging service

## Export Service Test Suite Details

### Module: ExportService

The `ExportService` class provides functionality to export project time tracking data in multiple formats:

**Location:** `lib/services/export_service.dart`

**Dependencies:**
- Database service for data retrieval
- Models: Project, Instance, Note
- Dart's formatting libraries (intl)

### Test Cases

#### 1. CSV Export Tests

**Test:** `exportTimeLogAsCsv generates CSV with headers`
- **Purpose:** Verify CSV header generation
- **Setup:** Create a project with no instances
- **Assertions:** 
  - CSV contains proper headers: "Date,Start Time,End Time,Duration (minutes),Duration (hours),Description,Week,Month"
  - CSV contains section headers: "Weekly Summaries" and "Monthly Summaries"

**Test:** `exportTimeLogAsCsv includes completed instances`
- **Purpose:** Verify that completed time instances are included in export
- **Setup:**
  - Create project
  - Add instance from 2024-01-15 09:00 to 11:30 (150 minutes)
  - Add note "Test note content"
- **Assertions:**
  - CSV contains date: "2024-01-15"
  - CSV contains start time: "09:00"
  - CSV contains end time: "11:30"
  - CSV contains duration: "150" minutes
  - CSV contains note content: "Test note content"

**Test:** `exportTimeLogAsCsv excludes active instances`
- **Purpose:** Ensure active (ongoing) instances without end times are excluded
- **Setup:**
  - Create project
  - Add active instance (startTime set, endTime null)
- **Assertions:**
  - CSV has only header and summary sections
  - No data rows for active instances

**Test:** `exportTimeLogAsCsv sorts instances in descending order`
- **Purpose:** Verify instances are sorted from most recent to oldest
- **Setup:**
  - Create project
  - Add instance on 2024-01-10
  - Add instance on 2024-01-15 (more recent)
- **Assertions:**
  - First data row contains "2024-01-15"
  - Second data row contains "2024-01-10"

**Test:** `exportTimeLogAsCsv uses last note as description`
- **Purpose:** Verify that when multiple notes exist, the most recent one is used as description
- **Setup:**
  - Create instance
  - Add note "First note"
  - Add note "Last note"
- **Assertions:**
  - CSV contains "Last note"
  - CSV does not contain "First note" as description

**Test:** `CSV escapes special characters in notes`
- **Purpose:** Ensure proper CSV escaping for special characters
- **Setup:**
  - Create instance with note: 'Note with "quotes"'
- **Assertions:**
  - CSV contains properly escaped: `Note with ""quotes""`

#### 2. Text Export Tests

**Test:** `exportNotesAsText generates formatted text`
- **Purpose:** Verify notes export with proper formatting
- **Setup:** Create project with no instances
- **Assertions:**
  - Output contains "Notes Export for Project: Test Project"
  - Output contains "Generated:" timestamp

**Test:** `exportNotesAsText includes notes grouped by instance`
- **Purpose:** Verify notes are grouped by their associated instances
- **Setup:**
  - Create instance from 2024-01-15 09:00 to 11:30
  - Add multiple notes to the instance
- **Assertions:**
  - Output contains "Instance:"
  - Output contains "Duration: 2h 30m"
  - Output contains all notes: "First note" and "Second note"

**Test:** `exportNotesAsText excludes instances without notes`
- **Purpose:** Ensure instances that have no notes are excluded from export
- **Setup:**
  - Create instance without adding any notes
- **Assertions:**
  - Output contains "Notes Export for Project: Test Project"
  - Output does NOT contain "Instance:"

#### 3. Preview Tests

**Test:** `generatePreviewText returns preview for CSV`
- **Purpose:** Verify preview generation for CSV format
- **Setup:** Create empty project
- **Assertions:**
  - Preview contains CSV headers: "Date,Start Time,End Time"
  - Preview is not empty

**Test:** `generatePreviewText returns preview for notes`
- **Purpose:** Verify preview generation for notes format
- **Setup:** Create empty project
- **Assertions:**
  - Preview contains "Notes Export for Project: Test Project"
  - Preview is not empty

## Test Data Models

### Project Model
```dart
Project(name: String)
```

### Instance Model
```dart
Instance(
  id?: String,
  projectId: String,
  startTime: DateTime,
  endTime?: DateTime,
  durationMinutes?: int,
)
```

### Note Model
```dart
Note(
  instanceId: String,
  content: String,
)
```

## Test Infrastructure

### Fake Database Service
`FakeDatabaseService` provides an in-memory implementation of the database with the following operations:

**Project Operations:**
- `insertProject(Project)` → Future<String> (returns ID)
- `getProject(String id)` → Future<Project?>
- `updateProject(Project)` → Future<void>
- `deleteProject(String id)` → Future<void>

**Instance Operations:**
- `insertInstance(Instance)` → Future<String> (returns ID)
- `getInstancesByProject(String projectId)` → Future<List<Instance>>
- `updateInstance(Instance)` → Future<void>
- `deleteInstance(String id)` → Future<void>

**Note Operations:**
- `insertNote(Note)` → Future<String> (returns ID)
- `getNotesByInstance(String instanceId)` → Future<List<Note>>
- `deleteNote(String id)` → Future<void>

## Running the Tests

### Prerequisites
- Flutter SDK (stable channel)
- Dart SDK 3.0.0 or higher
- Git

### Installation

#### Option 1: Using flutter_action in GitHub Actions (Recommended)
```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: 'stable'
```

#### Option 2: Local Installation
1. Visit https://flutter.dev/docs/get-started/install
2. Follow platform-specific installation instructions
3. Run `flutter doctor` to verify installation

### Running Tests

```bash
# Get all dependencies
flutter pub get

# Run all tests with verbose output
flutter test --verbose

# Run specific test file
flutter test test/export_service_test.dart --verbose

# Run with coverage report
flutter test --coverage

# Run specific test case
flutter test test/export_service_test.dart -n "exportTimeLogAsCsv generates CSV with headers"
```

### Expected Output

```
00:00 +0: ExportService
00:01 +1: ExportService exportTimeLogAsCsv generates CSV with headers
00:02 +2: ExportService exportTimeLogAsCsv includes completed instances
00:03 +3: ExportService exportTimeLogAsCsv excludes active instances
00:04 +4: ExportService exportTimeLogAsCsv sorts instances in descending order
00:05 +5: ExportService exportTimeLogAsCsv uses last note as description
00:06 +6: ExportService exportNotesAsText generates formatted text
00:07 +7: ExportService exportNotesAsText includes notes grouped by instance
00:08 +8: ExportService exportNotesAsText excludes instances without notes
00:09 +9: ExportService generatePreviewText returns preview for CSV
00:10 +10: ExportService generatePreviewText returns preview for notes
00:11 +11: ExportService CSV escapes special characters in notes

All tests passed! (11 positive tests)
```

## Test Coverage

The test suite provides comprehensive coverage for the ExportService:

- **CSV Export:** 6 tests covering headers, data inclusion, sorting, notes handling, and special characters
- **Text Export:** 3 tests covering formatting, grouping, and filtering
- **Preview Generation:** 2 tests covering both CSV and notes previews

**Coverage Target:** 100% of public API methods

## CI/CD Integration

The tests are configured to run automatically via GitHub Actions on:
- Push to main and develop branches
- Pull requests targeting main and develop branches

See `.github/workflows/flutter_test.yml` for the full workflow configuration.

## Troubleshooting

### Issue: "Flutter not found"
**Solution:** Run `flutter doctor` and follow setup instructions

### Issue: "Cannot get dependencies"
**Solution:** 
```bash
flutter clean
flutter pub get
```

### Issue: "Test timeout"
**Solution:** Run tests with longer timeout:
```bash
flutter test --timeout=300s
```

### Issue: Network errors downloading Dart SDK
**Solution:** Use GitHub Actions with proper network access, or set proxy:
```bash
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080
```

## Future Enhancements

1. Add integration tests for file export operations
2. Add performance benchmarks for large datasets
3. Add locale-specific formatting tests
4. Expand coverage to edge cases and error handling

## References

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Dart Testing Package](https://pub.dev/packages/test)
- [ProjectTracking README](../README.md)

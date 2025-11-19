# Implementation Quick Start Guide (When Ready)

> **Note:** This is a quick reference guide for future implementation. The actual migration should only begin after reviewing and approving the recommendations in `DATABASE_MIGRATION_SUMMARY.md` and `docs/database-alternatives-consideration.md`.

## Pre-Implementation Checklist

- [ ] Review and approve database choice (MSSQL recommended)
- [ ] Confirm infrastructure availability (server for SQL Server Express or cloud account)
- [ ] Set up development/test environment
- [ ] Back up all existing SQLite data
- [ ] Plan downtime/migration schedule

## Phase 1: Database Abstraction (1-2 weeks)

### 1. Create Abstract Interface

```dart
// lib/services/database_service_interface.dart
abstract class IDatabaseService {
  Future<void> initialize();
  
  // Project operations
  Future<int> insertProject(Project project);
  Future<List<Project>> getAllProjects();
  Future<Project?> getProject(int id);
  Future<void> updateProject(Project project);
  
  // Instance operations
  Future<int> insertInstance(Instance instance);
  Future<Instance?> getActiveInstance();
  Future<List<Instance>> getInstancesForProject(int projectId);
  Future<void> updateInstance(Instance instance);
  
  // Note operations
  Future<int> insertNote(Note note);
  Future<List<Note>> getNotesForInstance(int instanceId);
}
```

### 2. Refactor SQLite Service

```dart
// lib/services/sqlite_database_service.dart
class SqliteDatabaseService implements IDatabaseService {
  // Move existing DatabaseService code here
  // Implement all interface methods
}
```

### 3. Update Provider

```dart
// lib/providers/tracking_provider.dart
class TrackingProvider with ChangeNotifier {
  final IDatabaseService dbService; // Changed from DatabaseService
  // Rest remains the same
}
```

### 4. Add Configuration

```dart
// lib/config/database_config.dart
enum DatabaseType { sqlite, mssql }

class DatabaseConfig {
  static DatabaseType get currentType {
    // Read from environment or config file
    return DatabaseType.sqlite; // Default for now
  }
  
  static IDatabaseService createDatabaseService() {
    switch (currentType) {
      case DatabaseType.mssql:
        return MssqlDatabaseService();
      case DatabaseType.sqlite:
      default:
        return SqliteDatabaseService();
    }
  }
}
```

### 5. Update main.dart

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for desktop if needed
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Use factory to create appropriate service
  final dbService = DatabaseConfig.createDatabaseService();
  await dbService.initialize();
  
  final fileService = FileLoggingService();
  await fileService.initialize();
  
  runApp(MyApp(dbService: dbService, fileService: fileService));
}
```

## Phase 2: MSSQL Implementation (2-3 weeks)

### 1. Set Up SQL Server

**On Windows Server/PC:**
```powershell
# Download SQL Server Express
# https://www.microsoft.com/en-us/sql-server/sql-server-downloads

# Install SQL Server Express
# Enable SQL Server Authentication
# Create database: ProjectTracking
# Create user: trackinguser with password
```

**SQL Setup Script:**
```sql
-- Create database
CREATE DATABASE ProjectTracking;
GO

USE ProjectTracking;
GO

-- Projects table
CREATE TABLE projects (
  id INT PRIMARY KEY IDENTITY(1,1),
  name NVARCHAR(255) NOT NULL,
  totalMinutes INT NOT NULL DEFAULT 0,
  createdAt DATETIME2 NOT NULL,
  lastActiveAt DATETIME2
);

-- Instances table
CREATE TABLE instances (
  id INT PRIMARY KEY IDENTITY(1,1),
  projectId INT NOT NULL,
  startTime DATETIME2 NOT NULL,
  endTime DATETIME2,
  durationMinutes INT NOT NULL DEFAULT 0,
  CONSTRAINT FK_instances_projects FOREIGN KEY (projectId) 
    REFERENCES projects (id) ON DELETE CASCADE
);

-- Notes table
CREATE TABLE notes (
  id INT PRIMARY KEY IDENTITY(1,1),
  instanceId INT NOT NULL,
  content NVARCHAR(MAX) NOT NULL,
  createdAt DATETIME2 NOT NULL,
  CONSTRAINT FK_notes_instances FOREIGN KEY (instanceId) 
    REFERENCES instances (id) ON DELETE CASCADE
);

-- Indexes
CREATE NONCLUSTERED INDEX idx_instances_projectId ON instances(projectId);
CREATE NONCLUSTERED INDEX idx_notes_instanceId ON notes(instanceId);
CREATE NONCLUSTERED INDEX idx_projects_lastActiveAt ON projects(lastActiveAt DESC);

-- Create user
CREATE LOGIN trackinguser WITH PASSWORD = 'YourStrongPassword123!';
CREATE USER trackinguser FOR LOGIN trackinguser;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO trackinguser;
```

### 2. Add Dart Package

```yaml
# pubspec.yaml
dependencies:
  # ... existing packages
  mssql_connection: ^1.0.0  # Check latest version on pub.dev
```

### 3. Implement MSSQL Service

```dart
// lib/services/mssql_database_service.dart
import 'package:mssql_connection/mssql_connection.dart';
import 'package:project_tracking/services/database_service_interface.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

class MssqlDatabaseService implements IDatabaseService {
  MssqlConnection? _connection;
  
  @override
  Future<void> initialize() async {
    _connection = MssqlConnection.getInstance();
    
    bool isConnected = await _connection!.connect(
      ip: "your-server-ip-or-vpn-hostname",
      port: "1433",
      databaseName: "ProjectTracking",
      username: "trackinguser",
      password: _getSecurePassword(),
      connectionTimeout: 30,
    );
    
    if (!isConnected) {
      throw Exception('Failed to connect to MSSQL database');
    }
  }
  
  String _getSecurePassword() {
    // Read from secure storage, environment variable, or encrypted config
    // NEVER hardcode passwords!
    return const String.fromEnvironment('DB_PASSWORD');
  }
  
  @override
  Future<int> insertProject(Project project) async {
    String query = '''
      INSERT INTO projects (name, totalMinutes, createdAt, lastActiveAt)
      OUTPUT INSERTED.id
      VALUES (@name, @totalMinutes, @createdAt, @lastActiveAt)
    ''';
    
    var result = await _connection!.writeData(query, {
      'name': project.name,
      'totalMinutes': project.totalMinutes,
      'createdAt': project.createdAt.toIso8601String(),
      'lastActiveAt': project.lastActiveAt?.toIso8601String(),
    });
    
    return result[0]['id'] as int;
  }
  
  @override
  Future<List<Project>> getAllProjects() async {
    String query = '''
      SELECT id, name, totalMinutes, createdAt, lastActiveAt
      FROM projects
      ORDER BY lastActiveAt DESC, name ASC
    ''';
    
    var result = await _connection!.readData(query);
    return result.map((row) => Project.fromMap(row)).toList();
  }
  
  @override
  Future<Project?> getProject(int id) async {
    String query = '''
      SELECT id, name, totalMinutes, createdAt, lastActiveAt
      FROM projects
      WHERE id = @id
    ''';
    
    var result = await _connection!.readData(query, {'id': id});
    if (result.isEmpty) return null;
    return Project.fromMap(result.first);
  }
  
  @override
  Future<void> updateProject(Project project) async {
    String query = '''
      UPDATE projects
      SET name = @name,
          totalMinutes = @totalMinutes,
          lastActiveAt = @lastActiveAt
      WHERE id = @id
    ''';
    
    await _connection!.writeData(query, {
      'id': project.id,
      'name': project.name,
      'totalMinutes': project.totalMinutes,
      'lastActiveAt': project.lastActiveAt?.toIso8601String(),
    });
  }
  
  // Implement remaining interface methods similarly...
  // See detailed documentation for complete implementation
}
```

### 4. Configure OpenVPN (if using VPN access)

```bash
# On server
sudo apt-get install openvpn
# Configure OpenVPN server
# Generate client certificates
# Configure firewall to allow SQL Server port 1433 through VPN only
```

## Phase 3: Migration Tools (1 week)

### Export from SQLite

```dart
// tools/export_sqlite_data.dart
import 'dart:io';
import 'dart:convert';
import 'package:project_tracking/services/sqlite_database_service.dart';

Future<void> main() async {
  final sqliteService = SqliteDatabaseService();
  await sqliteService.initialize();
  
  // Export all data
  final projects = await sqliteService.getAllProjects();
  
  final exportData = {
    'export_date': DateTime.now().toIso8601String(),
    'projects': [],
  };
  
  for (var project in projects) {
    final instances = await sqliteService.getInstancesForProject(project.id!);
    final projectData = {
      'project': project.toMap(),
      'instances': [],
    };
    
    for (var instance in instances) {
      final notes = await sqliteService.getNotesForInstance(instance.id!);
      projectData['instances'].add({
        'instance': instance.toMap(),
        'notes': notes.map((n) => n.toMap()).toList(),
      });
    }
    
    exportData['projects'].add(projectData);
  }
  
  // Save to JSON file
  final file = File('project_tracking_export_${DateTime.now().millisecondsSinceEpoch}.json');
  await file.writeAsString(JsonEncoder.withIndent('  ').convert(exportData));
  print('Exported to: ${file.path}');
}
```

### Import to MSSQL

```dart
// tools/import_to_mssql.dart
import 'dart:io';
import 'dart:convert';
import 'package:project_tracking/services/mssql_database_service.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart import_to_mssql.dart <export_file.json>');
    exit(1);
  }
  
  final file = File(args[0]);
  if (!file.existsSync()) {
    print('File not found: ${args[0]}');
    exit(1);
  }
  
  final mssqlService = MssqlDatabaseService();
  await mssqlService.initialize();
  
  final jsonData = jsonDecode(await file.readAsString());
  
  for (var projectData in jsonData['projects']) {
    final project = Project.fromMap(projectData['project']);
    final newProjectId = await mssqlService.insertProject(project);
    
    for (var instanceData in projectData['instances']) {
      final instance = Instance.fromMap(instanceData['instance']);
      final newInstance = instance.copyWith(projectId: newProjectId);
      final newInstanceId = await mssqlService.insertInstance(newInstance);
      
      for (var noteData in instanceData['notes']) {
        final note = Note.fromMap(noteData);
        final newNote = note.copyWith(instanceId: newInstanceId);
        await mssqlService.insertNote(newNote);
      }
    }
  }
  
  print('Import completed successfully!');
}
```

## Phase 4: Testing (1 week)

### Test Checklist

- [ ] Test MSSQL connection from all platforms (Android, iOS, Windows, Linux)
- [ ] Test all CRUD operations
- [ ] Test foreign key constraints and CASCADE deletes
- [ ] Test concurrent access from multiple devices
- [ ] Test network interruption handling
- [ ] Test authentication and authorization
- [ ] Performance test with realistic data volumes
- [ ] Test data migration accuracy

### Test Script

```dart
// test/integration/mssql_integration_test.dart
import 'package:test/test.dart';
import 'package:project_tracking/services/mssql_database_service.dart';
import 'package:project_tracking/models/project.dart';

void main() {
  late MssqlDatabaseService db;
  
  setUp(() async {
    db = MssqlDatabaseService();
    await db.initialize();
  });
  
  test('Insert and retrieve project', () async {
    final project = Project(name: 'Test Project');
    final id = await db.insertProject(project);
    
    final retrieved = await db.getProject(id);
    expect(retrieved, isNotNull);
    expect(retrieved!.name, equals('Test Project'));
  });
  
  test('CASCADE delete instances when project deleted', () async {
    // Test foreign key constraints
    // ...
  });
  
  // Add more tests...
}
```

## Phase 5: Deployment

### 1. Update Configuration

```dart
// Set environment variable or config
// DB_TYPE=mssql
// DB_PASSWORD=YourSecurePassword
```

### 2. Deploy New Version

```bash
# Build release versions
flutter build apk --release
flutter build windows --release
# etc.

# Distribute to users with migration instructions
```

### 3. User Migration Steps

1. Install new version
2. Export existing data (if keeping local backup)
3. App connects to MSSQL automatically on first run
4. Verify data sync is working

## Security Checklist

- [ ] Strong passwords for SQL Server authentication
- [ ] OpenVPN or equivalent secure tunnel configured
- [ ] SQL Server not exposed directly to internet
- [ ] Connection strings stored securely (not in source code)
- [ ] Regular backups configured
- [ ] Audit logging enabled
- [ ] Firewall rules configured properly
- [ ] SSL/TLS enabled for SQL Server connections

## Troubleshooting

### Connection Issues
```dart
// Add detailed logging
print('Attempting connection to: $ip:$port');
print('Database: $databaseName');
print('Username: $username');
// Never log passwords!
```

### Performance Issues
- Check network latency
- Add connection pooling
- Implement caching for frequently accessed data
- Use indexes on queried columns

### Data Sync Issues
- Verify foreign key constraints
- Check transaction isolation levels
- Implement retry logic for network failures

## Resources

- [MSSQL Connection Package](https://pub.dev/packages/mssql_connection)
- [SQL Server Express Download](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
- [Azure SQL Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)
- [Flutter Provider Documentation](https://pub.dev/packages/provider)

---

**Remember:** Always test thoroughly in a development environment before deploying to production!

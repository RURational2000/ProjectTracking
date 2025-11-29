# MSSQL Implementation Quick Start Guide

> **Note:** This guide provides step-by-step instructions for implementing MSSQL Server as the database backend for Project Tracking. MSSQL has been selected as the sole database solution, providing a clear path from self-hosted SQL Server Express to Azure SQL Database.

## Pre-Implementation Checklist

- [ ] Review and approve MSSQL as database choice ✅
- [ ] Confirm infrastructure availability (server for SQL Server Express or cloud account)
- [ ] Set up development/test environment

## Phase 1: MSSQL Implementation (2-3 weeks)

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
// lib/services/database_service.dart
import 'package:mssql_connection/mssql_connection.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

/// Core database service using MSSQL Server for centralized persistence.
/// Manages Projects, Instances (work sessions), and Notes with time accumulation.
class DatabaseService {
  MssqlConnection? _connection;
  
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
  
  Future<List<Project>> getAllProjects() async {
    String query = '''
      SELECT id, name, totalMinutes, createdAt, lastActiveAt
      FROM projects
      ORDER BY lastActiveAt DESC, name ASC
    ''';
    
    var result = await _connection!.readData(query);
    return result.map((row) => Project.fromMap(row)).toList();
  }
  
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
  
  // Implement remaining methods for Instance and Note operations similarly
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

## Phase 2: Testing (1 week)

### Test Checklist

- [ ] Test MSSQL connection from all platforms (Android, iOS, Windows, Linux)
- [ ] Test all CRUD operations
- [ ] Test foreign key constraints and CASCADE deletes
- [ ] Test concurrent access from multiple devices
- [ ] Test network interruption handling
- [ ] Test authentication and authorization
- [ ] Performance test with realistic data volumes

### Test Script

```dart
// test/integration/database_integration_test.dart
import 'package:test/test.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/models/project.dart';

void main() {
  late DatabaseService db;
  
  setUp(() async {
    db = DatabaseService();
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

## Phase 3: Deployment

### 1. Update Configuration

```dart
// Set environment variable or config
// DB_PASSWORD=YourSecurePassword
```

### 2. Deploy New Version

```bash
# Build release versions
flutter build apk --release
flutter build windows --release
# etc.
```

### 3. App Startup

1. App connects to MSSQL on first run
2. Verify data operations are working

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

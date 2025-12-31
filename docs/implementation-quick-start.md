# Supabase Implementation Quick Start Guide

> **Note:** This guide provides step-by-step instructions for implementing Supabase as the database backend for Project Tracking. Supabase has been selected as the database solution, providing a managed PostgreSQL database with built-in authentication, real-time subscriptions, and auto-generated APIs.

## Pre-Implementation Checklist

- [ ] Review and approve Supabase as database choice ✅
- [ ] Create Supabase account (free tier available)
- [ ] Set up development/test environment

## Phase 1: Supabase Implementation (2-3 weeks)

### 1. Set Up Supabase Project

**Create Project:**
1. Go to https://supabase.com and create an account
2. Create a new project
3. Note your Project URL and anon/public API key
4. Wait for project to finish provisioning (~2 minutes)

**SQL Setup Script:**
```sql
-- Projects table
CREATE TABLE projects (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  totalMinutes INTEGER NOT NULL DEFAULT 0,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  lastActiveAt TIMESTAMPTZ
);

-- Instances table
CREATE TABLE instances (
  id BIGSERIAL PRIMARY KEY,
  projectId BIGINT NOT NULL,
  startTime TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  endTime TIMESTAMPTZ,
  durationMinutes INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT fk_instances_projects FOREIGN KEY (projectId) 
    REFERENCES projects (id) ON DELETE CASCADE
);

-- Notes table
CREATE TABLE notes (
  id BIGSERIAL PRIMARY KEY,
  instanceId BIGINT NOT NULL,
  content TEXT NOT NULL,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_notes_instances FOREIGN KEY (instanceId) 
    REFERENCES instances (id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_instances_projectId ON instances(projectId);
CREATE INDEX idx_notes_instanceId ON notes(instanceId);
CREATE INDEX idx_projects_lastActiveAt ON projects(lastActiveAt DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth requirements)
-- IMPORTANT: These policies allow all authenticated users to access all data.
-- For multi-user scenarios, implement user-specific policies based on your needs.
-- Example for user-specific access: USING (auth.uid() = user_id)
CREATE POLICY "Allow all for authenticated users" ON projects
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all for authenticated users" ON instances
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all for authenticated users" ON notes
  FOR ALL USING (auth.role() = 'authenticated');
```

### 2. Add Dart Package

```yaml
# pubspec.yaml
dependencies:
  # ... existing packages
  supabase_flutter: ^2.0.0  # Check latest version on pub.dev
```

### 3. Implement Supabase Service

```dart
// lib/services/database_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

/// Core database service using Supabase for centralized persistence.
/// Manages Projects, Instances (work sessions), and Notes with time accumulation.
class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  Future<void> initialize() async {
    _connection ??= MssqlConnection.getInstance();
  
    if (_connection!.isConnected) {
      return;
    }

    bool isConnected = await _connection!.connect(
  }
  
  Future<int> insertProject(Project project) async {
    final response = await _client
        .from('projects')
        .insert({
          'name': project.name,
          'totalMinutes': project.totalMinutes,
          'createdAt': project.createdAt.toIso8601String(),
          'lastActiveAt': project.lastActiveAt?.toIso8601String(),
        })
        .select('id')
        .single();
    
    return response['id'] as int;
  }
  
  Future<List<Project>> getAllProjects() async {
    final response = await _client
        .from('projects')
        .select()
        .order('lastActiveAt', ascending: false)
        .order('name', ascending: true);
    
    return (response as List)
        .map((data) => Project.fromMap(data))
        .toList();
  }
  
  Future<Project?> getProject(int id) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return Project.fromMap(response);
  }
  
  Future<void> updateProject(Project project) async {
    await _client
        .from('projects')
        .update({
          'name': project.name,
          'totalMinutes': project.totalMinutes,
          'lastActiveAt': project.lastActiveAt?.toIso8601String(),
        })
        .eq('id', project.id!);
  }
  
  Future<Instance?> getActiveInstance() async {
    final response = await _client
        .from('instances')
        .select()
        .is_('endTime', null)
        .order('startTime', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (response == null) return null;
    return Instance.fromMap(response);
  }
  
  Future<int> insertInstance(Instance instance) async {
    final response = await _client
        .from('instances')
        .insert({
          'projectId': instance.projectId,
          'startTime': instance.startTime.toIso8601String(),
          'endTime': instance.endTime?.toIso8601String(),
          'durationMinutes': instance.durationMinutes,
        })
        .select('id')
        .single();
    
    return response['id'] as int;
  }
  
  Future<void> updateInstance(Instance instance) async {
    await _client
        .from('instances')
        .update({
          'endTime': instance.endTime?.toIso8601String(),
          'durationMinutes': instance.durationMinutes,
        })
        .eq('id', instance.id!);
  }
  
  Future<List<Instance>> getInstancesForProject(int projectId) async {
    final response = await _client
        .from('instances')
        .select()
        .eq('projectId', projectId)
        .order('startTime', ascending: false);
    
    return (response as List)
        .map((data) => Instance.fromMap(data))
        .toList();
  }
  
  Future<int> insertNote(Note note) async {
    if (note.content.trim().isEmpty) {
      throw ArgumentError('Note content cannot be empty');
    }
    
    final response = await _client
        .from('notes')
        .insert({
          'instanceId': note.instanceId,
          'content': note.content,
          'createdAt': note.createdAt.toIso8601String(),
        })
        .select('id')
        .single();
    
    return response['id'] as int;
  }
  
  Future<List<Note>> getNotesForInstance(int instanceId) async {
    final response = await _client
        .from('notes')
        .select()
        .eq('instanceId', instanceId)
        .order('createdAt', ascending: true);
    
    return (response as List)
        .map((data) => Note.fromMap(data))
        .toList();
  }
}
```

### 4. Initialize Supabase in main.dart

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/services/file_logging_service.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  // IMPORTANT: Replace with your actual Supabase project credentials
  // DO NOT commit real credentials to version control
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // Initialize services
  final dbService = DatabaseService();
  await dbService.initialize();
  
  final fileService = FileLoggingService();
  await fileService.initialize();
  
  runApp(MyApp(dbService: dbService, fileService: fileService));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  final FileLoggingService fileService;
  
  const MyApp({
    super.key,
    required this.dbService,
    required this.fileService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrackingProvider(
        dbService: dbService,
        fileService: fileService,
      ),
      child: MaterialApp(
        title: 'Project Tracking',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

### 5. Environment Configuration

**Option 1: Use environment variables (recommended for production)**
```dart
// Store in .env file (add to .gitignore)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

// Load in code
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

**Option 2: Configuration file (for development)**
```dart
// lib/config/supabase_config.dart
// WARNING: Add this file to .gitignore to avoid committing credentials
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

## Phase 2: Testing (1 week)

### Test Checklist

- [ ] Test Supabase connection from all platforms (Android, iOS, Windows, Linux)
- [ ] Test all CRUD operations
- [ ] Test foreign key constraints and CASCADE deletes
- [ ] Test concurrent access from multiple devices
- [ ] Test network interruption handling
- [ ] Test authentication and authorization with Supabase Auth
- [ ] Test real-time subscriptions (if implemented)
- [ ] Test Row-Level Security policies
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
// Set environment variables or use secure configuration
// SUPABASE_URL=https://your-project.supabase.co
// SUPABASE_ANON_KEY=your-anon-key
```

### 2. Deploy New Version

```bash
# Build release versions
flutter build apk --release
flutter build windows --release
# etc.
```

### 3. App Startup

1. App connects to Supabase on first run
2. Users can authenticate using Supabase Auth
3. Verify data operations are working

## Security Checklist

- [ ] Row-Level Security (RLS) policies configured in Supabase
- [ ] Authentication enabled and tested
- [ ] API keys secured (anon key in client, service role key never exposed)
- [ ] Environment variables used for sensitive configuration
- [ ] Database backup policies configured in Supabase dashboard
- [ ] SSL/TLS encryption enabled (default with Supabase)
- [ ] Access logs reviewed in Supabase dashboard

## Real-Time Features (Optional)

Supabase provides real-time subscriptions out of the box:

```dart
// Subscribe to project changes
final subscription = _client
    .from('projects')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> data) {
      // Handle real-time updates
      final projects = data.map((d) => Project.fromMap(d)).toList();
      // Update UI
    });

// Don't forget to cancel subscription when done
subscription.cancel();
```

## Troubleshooting

### Connection Issues
```dart
// Check Supabase initialization
try {
  await Supabase.initialize(
    url: 'YOUR_URL',
    anonKey: 'YOUR_KEY',
  );
  print('Supabase initialized successfully');
} catch (e) {
  print('Failed to initialize Supabase: $e');
}
```

### Authentication Issues
- Verify authentication is enabled in Supabase dashboard
- Check that email confirmation is configured correctly
- Ensure RLS policies allow authenticated users

### Performance Issues
- Use Supabase query filters to reduce data transfer
- Implement pagination for large datasets
- Use indexes on frequently queried columns (already created in setup)
- Consider using Supabase Edge Functions for complex operations

## Resources

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Dashboard](https://supabase.com/dashboard)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Row-Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter Provider Documentation](https://pub.dev/packages/provider)

---

**Remember:** Supabase provides automatic backups and managed infrastructure. Focus on building features rather than managing servers!

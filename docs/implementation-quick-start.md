# Supabase Implementation Quick Start Guide

> **Note:** This guide provides step-by-step instructions for implementing Supabase as the database backend for Project Tracking. Supabase has been selected as the database solution, providing a managed PostgreSQL database with built-in authentication, real-time subscriptions, and auto-generated APIs.

## Pre-Implementation Checklist

- [ ] Review and approve Supabase as database choice ✅
- [ ] Create Supabase account (free tier available)
- [ ] Set up development/test environment
- [ ] Create separate GitHub repository for Supabase configuration (optional but recommended)

## GitHub Project Management Setup

### Overview

It is recommended to maintain a separate GitHub repository for Supabase-specific configurations, SQL migration scripts, and database documentation. This keeps database schema management separate from the Flutter application code while allowing version control and collaboration.

### Creating a Supabase Configuration Repository

**1. Create New GitHub Repository:**

```bash
# Recommended repository name
ProjectTracking-Supabase-Config

# Repository structure
/
├── README.md                          # Setup instructions and overview
├── migrations/                        # SQL migration scripts
│   ├── 001_initial_schema.sql        # Initial table creation
│   ├── 002_add_user_profiles.sql     # User profiles table
│   ├── 003_add_project_status.sql    # Project status field
│   └── README.md                      # Migration instructions
├── policies/                          # RLS policies
│   ├── projects_policies.sql         # Project table policies
│   ├── instances_policies.sql        # Instance table policies
│   └── notes_policies.sql            # Notes table policies
├── functions/                         # Supabase Edge Functions
│   └── README.md                      # Functions documentation
├── seeds/                             # Test data seeds
│   └── dev_seed.sql                  # Development test data
└── docs/                              # Additional documentation
    ├── schema.md                      # Database schema documentation
    ├── api-endpoints.md               # Auto-generated API docs
    └── security.md                    # Security and RLS guide
```

**2. Link Repositories:**

In your main `ProjectTracking` repository's README.md, add a reference:

```markdown
## Database Configuration

This application uses Supabase as its backend. Database schema, migrations, and 
configuration are maintained in a separate repository:

**Supabase Config Repository:** [ProjectTracking-Supabase-Config](https://github.com/YOUR_USERNAME/ProjectTracking-Supabase-Config)
```

In your `ProjectTracking-Supabase-Config` repository's README.md:

```markdown
## ProjectTracking Supabase Configuration

This repository contains the Supabase database configuration for the 
[ProjectTracking](https://github.com/YOUR_USERNAME/ProjectTracking) Flutter application.

### Quick Links
- **Main Application:** [ProjectTracking](https://github.com/YOUR_USERNAME/ProjectTracking)
- **Live Supabase Dashboard:** [Your Project Dashboard](https://app.supabase.com/project/your-project-ref)
```

**3. Workflow for Schema Changes:**

When making database schema changes:
1. Create a new migration file in `ProjectTracking-Supabase-Config/migrations/`
2. Test the migration in Supabase development environment
3. Document changes in the migration file with comments
4. Commit and push to the Supabase config repository
5. Update the Flutter app's data models if needed in the main repository
6. Create pull requests in both repositories, linking them together

**Example Migration File Structure:**

```sql
-- Migration: 004_add_project_tags.sql
-- Description: Add tags support for projects
-- Date: 2025-12-31
-- Author: [Your Name]
-- Related PR: ProjectTracking#123

-- Add tags column to projects table
ALTER TABLE projects ADD COLUMN tags TEXT[] DEFAULT '{}';

-- Create index for tag searching
CREATE INDEX idx_projects_tags ON projects USING GIN(tags);

-- Update RLS policies if needed
-- (No policy changes required for this migration)

-- Rollback instructions:
-- ALTER TABLE projects DROP COLUMN tags;
-- DROP INDEX idx_projects_tags;
```

**4. Synchronization Strategy:**

- **Development:** Each developer has their own Supabase project for testing
- **Staging:** Shared staging Supabase project for integration testing
- **Production:** Production Supabase project with automated backups

Maintain separate `.env` files for each environment (never commit to git):

```env
# .env.development
SUPABASE_URL=https://your-dev-project.supabase.co
SUPABASE_ANON_KEY=your-dev-anon-key

# .env.staging
SUPABASE_URL=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY=your-staging-anon-key

# .env.production
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=your-prod-anon-key
```

## Phase 1: Supabase Implementation (2-3 weeks)

### 1. Set Up Supabase Project

**Create Project:**
1. Go to https://supabase.com and create an account
2. Create a new project
3. Note your Project URL and anon/public API key
4. Wait for project to finish provisioning (~2 minutes)

**SQL Setup Script:**

```sql
-- Projects table with user ownership and status tracking
CREATE TABLE projects (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_project_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' 
    CHECK (status IN ('active', 'completed', 'on_hold', 'reset', 'canceled')),
  archived BOOLEAN NOT NULL DEFAULT false,
  totalMinutes INTEGER NOT NULL DEFAULT 0,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  lastActiveAt TIMESTAMPTZ,
  completedAt TIMESTAMPTZ,
  description TEXT,
  CONSTRAINT unique_user_project_name UNIQUE (user_id, name)
);

-- Instances table with user ownership
CREATE TABLE instances (
  id BIGSERIAL PRIMARY KEY,
  projectId BIGINT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  startTime TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  endTime TIMESTAMPTZ,
  durationMinutes INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT fk_instances_projects FOREIGN KEY (projectId) 
    REFERENCES projects (id) ON DELETE CASCADE
  -- Note: A CHECK constraint verifying user_id matches the project owner
  -- would impact INSERT/UPDATE performance due to subquery execution.
  -- User ownership verification is handled by RLS policies and application logic.
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

-- User profiles table (optional, for extended user information)
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE INDEX idx_projects_parent_project_id ON projects(parent_project_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_archived ON projects(archived);
CREATE INDEX idx_projects_user_lastActiveAt ON projects(user_id, lastActiveAt DESC);
CREATE INDEX idx_instances_projectId ON instances(projectId);
CREATE INDEX idx_instances_user_id ON instances(user_id);
CREATE INDEX idx_instances_startTime ON instances(startTime DESC);
CREATE INDEX idx_notes_instanceId ON notes(instanceId);

-- Enable Row Level Security (RLS)
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user-specific data access
-- Projects: Users can only access their own projects
CREATE POLICY "Users can view own projects" ON projects
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own projects" ON projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects" ON projects
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects" ON projects
  FOR DELETE USING (auth.uid() = user_id);

-- Instances: Users can only access instances of their own projects
-- Note: This policy verifies ownership through the projects table AND the instance's user_id
CREATE POLICY "Users can view own instances" ON instances
  FOR SELECT USING (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = instances.projectId 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own instances" ON instances
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = instances.projectId 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own instances" ON instances
  FOR UPDATE USING (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = instances.projectId 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own instances" ON instances
  FOR DELETE USING (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = instances.projectId 
      AND projects.user_id = auth.uid()
    )
  );

-- Notes: Users can only access notes on their own instances
CREATE POLICY "Users can view notes on own instances" ON notes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM instances 
      WHERE instances.id = notes.instanceId 
      AND instances.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert notes on own instances" ON notes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM instances 
      WHERE instances.id = notes.instanceId 
      AND instances.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update notes on own instances" ON notes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM instances 
      WHERE instances.id = notes.instanceId 
      AND instances.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete notes on own instances" ON notes
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM instances 
      WHERE instances.id = notes.instanceId 
      AND instances.user_id = auth.uid()
    )
  );

-- User profiles: Users can only access their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
```

## Understanding Key Features

### Individual User Identification

The updated schema implements proper multi-user support through Supabase's built-in authentication system:

**1. User Authentication:**
- Each user authenticates through Supabase Auth (email/password, OAuth, etc.)
- Upon successful authentication, users receive a unique UUID from `auth.uid()`
- This UUID is automatically used in Row-Level Security (RLS) policies

**2. Data Ownership:**
- All projects and instances now include a `user_id` field referencing `auth.users(id)`
- Foreign key constraints ensure data integrity with CASCADE delete
- Users can only access their own data through RLS policies

**3. Implementation in Flutter:**

```dart
// Get current user ID
final userId = Supabase.instance.client.auth.currentUser?.id;

// When inserting a project, user_id is automatically included
final response = await _client
    .from('projects')
    .insert({
      'user_id': userId,  // Required for RLS
      'name': project.name,
      'status': 'active',
      'totalMinutes': project.totalMinutes,
      // ...
    });
```

**4. Benefits:**
- **Privacy:** Users cannot access other users' projects or data
- **Security:** Enforced at database level, not just application level
- **Multi-tenancy:** Single database serves multiple users safely
- **Scalability:** Easy to add team/organization features later

### Project Status Tracking

Projects support workflow status tracking with five predefined states, plus a separate archived flag:

**1. Status Values:**

- `active` (default): Currently being worked on
- `completed`: Project finished successfully
- `on_hold`: Temporarily paused
- `reset`: Project segment completed and archived; ready to start fresh with same name and new time accounting (useful for recurring time management tasks)
- `canceled`: Project cancelled before completion

**2. Archived Field:**

- `archived` (boolean, default false): Separate field to preserve status when archiving
- When archived, the original status is maintained for historical records
- Allows queries like "show all completed projects including archived ones"

**3. Parent Project Field:**

- `parent_project_id` (nullable): Links to parent project for hierarchical tracking
- Enables project/sub-project relationships
- Useful with `reset` status to track successive iterations of recurring tasks

**4. Status Field Definition:**

```sql
status TEXT NOT NULL DEFAULT 'active' 
  CHECK (status IN ('active', 'completed', 'on_hold', 'reset', 'canceled'))
archived BOOLEAN NOT NULL DEFAULT false
parent_project_id BIGINT REFERENCES projects(id) ON DELETE SET NULL
```

**5. Additional Fields:**

- `completedAt`: Timestamp when project was marked as completed
- `description`: Optional text description of the project

**6. Usage in Application:**

```dart
// Update project status
await _client
    .from('projects')
    .update({
      'status': 'completed',
      'completedAt': DateTime.now().toIso8601String(),
    })
    .eq('id', projectId);

// Archive a project while preserving its status
await _client
    .from('projects')
    .update({'archived': true})
    .eq('id', projectId);

// Reset a project: archive current and create new with same name
final oldProject = await _client
    .from('projects')
    .select()
    .eq('id', projectId)
    .single();

// Archive the old project with reset status
await _client
    .from('projects')
    .update({
      'status': 'reset',
      'archived': true,
    })
    .eq('id', projectId);

// Create new project linked to the old one
final newProject = await _client
    .from('projects')
    .insert({
      'user_id': userId,
      'name': oldProject['name'],
      'parent_project_id': projectId,
      'status': 'active',
      'description': oldProject['description'],
    })
    .select()
    .single();

// Filter projects by status
final activeProjects = await _client
    .from('projects')
    .select()
    .eq('status', 'active')
    .eq('archived', false)
    .order('lastActiveAt', ascending: false);

// Get all non-archived projects
final workingProjects = await _client
    .from('projects')
    .select()
    .eq('archived', false)
    .order('status', ascending: true)
    .order('lastActiveAt', ascending: false);

// Get project history (parent and all children)
final projectHistory = await _client
    .from('projects')
    .select()
    .or('id.eq.$projectId,parent_project_id.eq.$projectId')
    .order('createdAt', ascending: true);
```

**7. UI Integration Suggestions:**

- Display status badge/chip on each project card
- Add status filter dropdown in project list
- Show "Complete Project" action button
- Show "Reset Project" action for recurring time management tasks
- Automatically set `completedAt` when status changes to 'completed'
- Prevent time tracking on archived projects
- Warn before archiving projects with active instances
- Display project hierarchy when parent_project_id is set

**8. Status Transitions:**

```text
active ──────────> completed ──────> (can be archived)
  ├──────────────> on_hold ─────────> (can be archived)
  ├──────────────> reset ────────────> archived (automatic)
  └──────────────> canceled ─────────> (can be archived)

Note: reset status automatically archives the project and 
      typically creates a new project with same name
```

**9. Index Performance:**

The schema includes indexes on status and archived fields for efficient filtering:

```sql
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_archived ON projects(archived);
CREATE INDEX idx_projects_parent_project_id ON projects(parent_project_id);
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
/// Supports multi-user authentication and project status tracking.
class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  
  Future<void> initialize() async {
    // Supabase client is initialized in main.dart
    // No additional initialization needed
  }
  
  Future<int> insertProject(Project project) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated. Please sign in to create projects.');
    }
    
    final response = await _client
        .from('projects')
        .insert({
          'user_id': userId,
          'parent_project_id': project.parentProjectId,
          'name': project.name,
          // 'status' field has DEFAULT 'active' in database
          // 'archived' field has DEFAULT false in database
          'totalMinutes': project.totalMinutes,
          'createdAt': project.createdAt.toIso8601String(),
          'lastActiveAt': project.lastActiveAt?.toIso8601String(),
          'description': project.description,
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
          'parent_project_id': project.parentProjectId,
          'name': project.name,
          'status': project.status,
          'archived': project.archived,
          'totalMinutes': project.totalMinutes,
          'lastActiveAt': project.lastActiveAt?.toIso8601String(),
          'completedAt': project.completedAt?.toIso8601String(),
          'description': project.description,
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated. Please sign in to track time.');
    }
    
    final response = await _client
        .from('instances')
        .insert({
          'projectId': instance.projectId,
          'user_id': userId,
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

**Note:** This is a basic initialization example. For production use with authentication, 
see the complete implementation in Section 5 below.

```dart
// lib/main.dart (basic version without authentication)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/services/file_logging_service.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with environment variables
  // Validate that environment variables are set
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing required environment variables: SUPABASE_URL and SUPABASE_ANON_KEY. '
      'Please configure these variables before running the application. '
      'See environment configuration section for details.'
    );
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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

### 5. Implement Authentication

Add authentication screens and logic to handle user sign-in/sign-up:

```dart
// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_tracking/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      if (_isSignUp) {
        // Sign up
        final response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (response.user != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please check your email to verify.'),
            ),
          );
        }
      } else {
        // Sign in
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (response.user != null) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _handleAuth,
                child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
              ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp 
                  ? 'Already have an account? Sign In' 
                  : 'Need an account? Sign Up',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Update main.dart to handle authentication state:**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/services/file_logging_service.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/screens/home_screen.dart';
import 'package:project_tracking/screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with environment variables
  // Validate that environment variables are set
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing required environment variables: SUPABASE_URL and SUPABASE_ANON_KEY. '
      'Please configure these variables before running the application. '
      'See environment configuration section for details.'
    );
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
        home: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.session != null) {
              return const HomeScreen();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
```

### 6. Environment Configuration

#### Option 1: Use environment variables (recommended for production)

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

#### Option 2: Configuration file (for development)

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

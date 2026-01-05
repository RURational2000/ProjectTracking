-- Migration: 001_initial_schema.sql
-- Description: Initial Supabase schema for projects, instances, notes, and user profiles with RLS
-- Date: 2026-01-04
-- Author: Project Tracking team
-- Related PR: ProjectTracking#TODO

BEGIN;

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
  -- Note: User ownership verification for instances is enforced via RLS
  -- to avoid the performance cost of a CHECK constraint with a subquery.
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
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects" ON projects
  FOR DELETE USING (auth.uid() = user_id);

-- Instances: Users can only access instances of their own projects
-- Ownership is verified via both instances.user_id and the related project
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
  )
  WITH CHECK (
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

-- Notes: Users can only access notes on instances belonging to their projects
CREATE POLICY "Users can view notes on own instances" ON notes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM instances
      JOIN projects ON instances.projectId = projects.id
      WHERE instances.id = notes.instanceId
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert notes on own instances" ON notes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM instances
      JOIN projects ON instances.projectId = projects.id
      WHERE instances.id = notes.instanceId
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update notes on own instances" ON notes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM instances
      JOIN projects ON instances.projectId = projects.id
      WHERE instances.id = notes.instanceId
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete notes on own instances" ON notes
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM instances
      JOIN projects ON instances.projectId = projects.id
      WHERE instances.id = notes.instanceId
      AND projects.user_id = auth.uid()
    )
  );

-- User profiles: Users can only access their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

COMMIT;

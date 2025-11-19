# Database Alternatives Consideration for Project Tracking

**Date:** November 19, 2025  
**Status:** Research & Consideration Phase  
**Author:** AI Assistant (Copilot)

## Executive Summary

This document evaluates alternatives to the current SQLite database implementation for the Project Tracking application. The goal is to enable centralized, internet-accessible project tracking for individuals or companies while maintaining the existing application architecture and user experience.

## Current Architecture

### SQLite Implementation
- **Database:** `project_tracking.db` stored locally on each device
- **Storage Strategy:** Dual storage with SQLite for queries and text file logs for audit trail
- **Data Model:**
  - **Projects:** Container with accumulated time (`totalMinutes`)
  - **Instances:** Work sessions with start/end timestamps
  - **Notes:** Text entries associated with instances
- **Platform Support:** Cross-platform (Android, iOS, Windows, Linux)
- **Key Limitation:** No centralized access across devices or users

### Database Schema
```sql
-- Projects table with accumulated time
CREATE TABLE projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  totalMinutes INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  lastActiveAt TEXT
);

-- Instances table - work sessions with start/end times
CREATE TABLE instances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  projectId INTEGER NOT NULL,
  startTime TEXT NOT NULL,
  endTime TEXT,
  durationMinutes INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
);

-- Notes table - multiple notes per instance
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instanceId INTEGER NOT NULL,
  content TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (instanceId) REFERENCES instances (id) ON DELETE CASCADE
);
```

## Requirements for New Database Solution

### Functional Requirements
1. **Centralized Access:** Multiple devices/users access the same data
2. **Internet Accessibility:** Available through internet (not just local network)
3. **Cross-Platform Support:** Must work with Flutter on Android, iOS, Windows, Linux
4. **Data Integrity:** Maintain foreign key relationships and CASCADE deletes
5. **Real-Time Sync:** Multiple users/devices should see updates relatively quickly
6. **Security:** Authentication and authorization for multi-user scenarios

### Non-Functional Requirements
1. **Storage Capacity:** Initial 10GB should be sufficient
2. **Cost:** Free tier or low cost for initial deployment
3. **Migration Path:** Ability to scale to cloud hosting (Azure, AWS, etc.)
4. **Performance:** Acceptable latency for CRUD operations over internet
5. **Offline Support:** Desirable but not critical in first iteration
6. **Developer Familiarity:** Preference for technologies familiar to RURational2000

## Database Alternatives Analysis

### Option 1: Microsoft SQL Server (MSSQL)

#### Overview
Microsoft SQL Server is a relational database management system with extensive enterprise features and a free Express edition.

#### Pros
✅ **Strong Familiarity:** RURational2000 has extensive experience with MSSQL  
✅ **Free Tier:** SQL Server Express supports up to 10GB database size  
✅ **Full SQL Support:** Complete relational database with foreign keys, transactions, indexes  
✅ **OpenVPN Access:** Can be made accessible through OpenVPN for secure remote access  
✅ **Azure Migration:** Seamless migration path to Azure SQL Database  
✅ **Tooling:** Excellent management tools (SSMS, Azure Data Studio)  
✅ **Dart/Flutter Support:** `mssql_connection` package available for Dart  
✅ **Data Types:** Rich data type support including DATETIME2 for precise timestamps  
✅ **Transactions:** Full ACID compliance for data integrity  

#### Cons
❌ **Infrastructure Required:** Needs Windows Server or Windows machine to host  
❌ **Network Configuration:** Requires OpenVPN setup and port forwarding  
❌ **Connection Overhead:** TCP/IP connections have higher latency than local SQLite  
❌ **Self-Hosting:** Requires ongoing maintenance and security updates  
❌ **Authentication Complexity:** Need to manage SQL Server authentication  
❌ **Limited Mobile Optimizations:** Not designed for mobile-first applications  

#### Implementation Considerations
- **Package:** `mssql_connection` (https://pub.dev/packages/mssql_connection)
- **Connection String:** `Server=your-server.openvpn-domain.com;Database=ProjectTracking;User Id=trackinguser;Password=***;`
- **Schema Migration:** Direct SQL translation - minimal changes needed
- **Authentication:** SQL Server authentication or Windows authentication through OpenVPN

#### Cost Analysis
- **SQL Server Express:** Free (up to 10GB, 1GB RAM, 4 cores)
- **OpenVPN:** Free for self-hosted or ~$10/month for cloud VPN
- **Hosting:** Free if using existing hardware, or ~$20-50/month for VPS

#### Migration Path to Cloud
1. **Phase 1:** Self-hosted SQL Server Express over OpenVPN
2. **Phase 2:** Migrate to Azure SQL Database (Basic tier ~$5/month)
3. **Phase 3:** Scale to Standard/Premium tiers as needed

---

### Option 2: Firebase (Firestore)

#### Overview
Google's Firebase platform with Firestore as a NoSQL document database, designed for real-time mobile/web applications.

#### Pros
✅ **Real-Time Sync:** Built-in real-time data synchronization  
✅ **Offline Support:** Excellent offline capabilities with automatic sync  
✅ **Free Tier:** Generous free tier (1GB storage, 50K reads/day, 20K writes/day)  
✅ **Authentication:** Built-in Firebase Auth with multiple providers  
✅ **Flutter Integration:** Official `cloud_firestore` package with excellent support  
✅ **No Infrastructure:** Fully managed, no servers to maintain  
✅ **Scalability:** Automatic scaling built-in  
✅ **Mobile-First:** Designed specifically for mobile applications  
✅ **Security Rules:** Declarative security at database level  

#### Cons
❌ **NoSQL Paradigm Shift:** Requires rethinking relational data model  
❌ **No Foreign Keys:** Must handle relationships manually in application code  
❌ **Query Limitations:** Limited querying compared to SQL (no JOINs)  
❌ **Learning Curve:** Different from SQL, requires learning Firestore concepts  
❌ **Vendor Lock-in:** Tightly coupled to Google Cloud ecosystem  
❌ **Cost Scaling:** Can become expensive at scale with many reads/writes  
❌ **CASCADE Deletes:** Must implement manually in cloud functions or app  
❌ **Unfamiliarity:** RURational2000 not familiar with Firebase  

#### Implementation Considerations
- **Package:** `cloud_firestore` (https://pub.dev/packages/cloud_firestore)
- **Data Model Transformation:**
  ```javascript
  // Projects collection
  projects/{projectId}
    - name: string
    - totalMinutes: number
    - createdAt: timestamp
    - lastActiveAt: timestamp
    
    // Subcollection for instances
    /instances/{instanceId}
      - startTime: timestamp
      - endTime: timestamp
      - durationMinutes: number
      
      // Subcollection for notes
      /notes/{noteId}
        - content: string
        - createdAt: timestamp
  ```
- **Authentication:** Firebase Auth with email/password or Google sign-in
- **Security:** Firestore Security Rules to control access per user/entity

#### Cost Analysis
- **Free Tier:** 1GB storage, 50K reads/day, 20K writes/day, 20K deletes/day
- **Paid (Blaze):** $0.18/GB storage, $0.06 per 100K reads, $0.18 per 100K writes
- **Estimated Cost:** Likely free for single user, ~$5-10/month for small team

#### Schema Design Considerations
```dart
// Example Firestore structure
class FirestoreProject {
  final String id; // Document ID
  final String name;
  final int totalMinutes;
  final Timestamp createdAt;
  final Timestamp? lastActiveAt;
  
  // No direct foreign keys - use references
  CollectionReference get instances => 
    FirebaseFirestore.instance
      .collection('projects')
      .doc(id)
      .collection('instances');
}
```

---

### Option 3: Amazon DynamoDB

#### Overview
Amazon's fully managed NoSQL database service designed for high-scale applications with predictable performance.

#### Pros
✅ **Serverless:** Fully managed, no infrastructure to maintain  
✅ **Free Tier:** 25GB storage, 25 read/write capacity units (permanent free tier)  
✅ **Scalability:** Designed for massive scale  
✅ **AWS Integration:** Easy integration with other AWS services  
✅ **Consistency:** Strong consistency options available  
✅ **Global Tables:** Multi-region replication for disaster recovery  
✅ **Pay-per-use:** No minimum fees, pay only for what you use  

#### Cons
❌ **NoSQL Complexity:** Key-value/document store paradigm shift from SQL  
❌ **No Foreign Keys:** Relationships must be handled in application  
❌ **Query Limitations:** No complex queries without secondary indexes  
❌ **Limited Dart Support:** `dynamodb` package exists but less mature  
❌ **AWS Complexity:** AWS ecosystem can be overwhelming  
❌ **No JOIN Operations:** Must denormalize data or make multiple queries  
❌ **Learning Curve:** Different from SQL, requires understanding DynamoDB concepts  
❌ **Unfamiliarity:** RURational2000 not familiar with DynamoDB  
❌ **Authentication:** Requires AWS IAM/Cognito integration  

#### Implementation Considerations
- **Package:** `dynamodb` or `amplify_flutter` for authentication + data
- **Data Model:** 
  ```
  Table: ProjectTracking
  Partition Key: EntityId (e.g., userId or companyId)
  Sort Key: Composite key (ProjectId#InstanceId#NoteId)
  
  Attributes:
  - Type (PROJECT | INSTANCE | NOTE)
  - ProjectName
  - TotalMinutes
  - StartTime, EndTime
  - Content (for notes)
  ```
- **Authentication:** AWS Cognito for user authentication
- **Querying:** Must use Global Secondary Indexes for different query patterns

#### Cost Analysis
- **Free Tier (permanent):** 25GB storage, 25 WCU, 25 RCU
- **Paid:** $0.25/GB storage, $0.00065 per WCU, $0.00013 per RCU
- **Estimated Cost:** Likely free for single user/small entity

#### Schema Design Example
```dart
// DynamoDB item structure
{
  "EntityId": "user_123",           // Partition key
  "ItemId": "PROJECT#proj_1",       // Sort key
  "Type": "PROJECT",
  "Name": "My Project",
  "TotalMinutes": 480,
  "CreatedAt": "2025-11-19T14:00:00Z",
  "LastActiveAt": "2025-11-19T14:00:00Z"
}

{
  "EntityId": "user_123",
  "ItemId": "PROJECT#proj_1#INSTANCE#inst_1",
  "Type": "INSTANCE",
  "ProjectId": "proj_1",
  "StartTime": "2025-11-19T10:00:00Z",
  "EndTime": "2025-11-19T18:00:00Z",
  "DurationMinutes": 480
}
```

---

### Option 4: PostgreSQL (Cloud-Hosted)

#### Overview
Open-source relational database that can be hosted on cloud platforms (AWS RDS, Azure Database, DigitalOcean, etc.).

#### Pros
✅ **Full SQL Support:** Complete relational database with foreign keys, transactions  
✅ **Open Source:** No licensing costs  
✅ **SQL Familiarity:** Similar to MSSQL for SQL operations  
✅ **JSON Support:** Can store JSON documents if needed (hybrid approach)  
✅ **Cloud Options:** Available on all major cloud providers  
✅ **Flutter Support:** `postgres` package available for Dart  
✅ **Free Tiers Available:** Various cloud providers offer free PostgreSQL tiers  
✅ **Schema Migration:** Similar to MSSQL, minimal SQL changes needed  

#### Cons
❌ **Hosting Required:** Need to manage cloud instance or use managed service  
❌ **Less Familiar:** RURational2000 more familiar with MSSQL  
❌ **Cost:** Free tiers are limited; paid tiers start ~$15-20/month  
❌ **Configuration:** Requires setup and configuration  
❌ **Connection Management:** Need to handle connection pooling for mobile apps  

#### Implementation Considerations
- **Package:** `postgres` (https://pub.dev/packages/postgres)
- **Cloud Providers:**
  - **Azure Database for PostgreSQL:** Burstable tier ~$12/month
  - **AWS RDS Free Tier:** 750 hours/month, 20GB storage (1 year)
  - **DigitalOcean Managed PostgreSQL:** Starting at $15/month
  - **ElephantSQL:** Free tier with 20MB storage, paid from $5/month
- **Schema:** Direct SQL translation with minimal changes

#### Cost Analysis
- **ElephantSQL Free:** 20MB storage (too small)
- **AWS RDS Free Tier:** Free for 1 year, then ~$15/month
- **Azure PostgreSQL:** ~$12-15/month for basic tier
- **DigitalOcean:** $15/month for managed service

---

### Option 5: Supabase (PostgreSQL + Backend-as-a-Service)

#### Overview
Open-source Firebase alternative built on PostgreSQL, offering real-time subscriptions, authentication, and storage.

#### Pros
✅ **SQL + Real-Time:** PostgreSQL with real-time subscriptions  
✅ **Free Tier:** Generous free tier (500MB database, 2GB bandwidth, 50MB storage)  
✅ **Flutter Integration:** Official `supabase_flutter` package  
✅ **Authentication:** Built-in auth with multiple providers  
✅ **SQL Familiarity:** Uses PostgreSQL under the hood  
✅ **Foreign Keys:** Full relational database support  
✅ **Real-Time:** WebSocket subscriptions for real-time updates  
✅ **Row-Level Security:** Fine-grained access control at database level  
✅ **API Auto-Generation:** Automatic REST API from schema  

#### Cons
❌ **Learning Curve:** New platform to learn  
❌ **Vendor Lock-in:** Some features specific to Supabase  
❌ **Less Mature:** Newer than Firebase or AWS  
❌ **Free Tier Limits:** 500MB may be limiting for growth  
❌ **Unfamiliarity:** RURational2000 not familiar with Supabase  

#### Implementation Considerations
- **Package:** `supabase_flutter` (https://pub.dev/packages/supabase_flutter)
- **Schema:** Same SQL schema with minimal changes
- **Authentication:** Supabase Auth (email/password, OAuth)
- **Real-Time:** Can subscribe to table changes for live updates

#### Cost Analysis
- **Free Tier:** 500MB database, 2GB bandwidth/month, 50MB storage
- **Pro Tier:** $25/month for 8GB database, 250GB bandwidth
- **Estimated Cost:** Free for initial use, upgrade as needed

---

## Comparison Matrix

| Feature | MSSQL Server | Firebase | DynamoDB | PostgreSQL | Supabase |
|---------|--------------|----------|----------|------------|----------|
| **Familiarity** | ⭐⭐⭐⭐⭐ | ⭐ | ⭐ | ⭐⭐⭐ | ⭐⭐ |
| **SQL Support** | ✅ Full | ❌ NoSQL | ❌ NoSQL | ✅ Full | ✅ Full |
| **Free Tier** | 10GB (Express) | 1GB + quotas | 25GB (permanent) | Limited/Time-bound | 500MB |
| **Setup Complexity** | High | Low | Medium | Medium | Low |
| **Cloud Migration** | Azure (Easy) | N/A (Cloud-native) | N/A (Cloud-native) | Any cloud | Limited |
| **Real-Time Sync** | Manual | ✅ Built-in | Manual | Manual | ✅ Built-in |
| **Offline Support** | ❌ | ✅ Excellent | ❌ | ❌ | ⚠️ Limited |
| **Flutter Package** | `mssql_connection` | `cloud_firestore` | `dynamodb` | `postgres` | `supabase_flutter` |
| **Authentication** | SQL Auth | Firebase Auth | AWS Cognito | Custom/Manual | Supabase Auth |
| **Monthly Cost** | Free (self-host) | Free → $5-10 | Free → minimal | $0-15 | Free → $25 |
| **Infrastructure** | Self-managed | Fully managed | Fully managed | Managed options | Fully managed |
| **Maintenance** | High | None | None | Low-Medium | None |
| **Learning Curve** | Low | Medium | High | Low | Medium |
| **Schema Migration** | Easy | Complex | Complex | Easy | Easy |

## Recommendations

### Primary Recommendation: Microsoft SQL Server (MSSQL)

**Rationale:**
1. **Developer Familiarity:** RURational2000's strong MSSQL experience will accelerate development
2. **SQL Schema Compatibility:** Minimal changes required to existing data model
3. **Free Tier Sufficient:** 10GB SQL Server Express meets initial requirements
4. **Clear Migration Path:** Easy migration to Azure SQL Database when needed
5. **Control & Security:** Self-hosted with OpenVPN provides control over data and access

**Implementation Plan:**
1. Install SQL Server Express on Windows machine/server
2. Configure OpenVPN for secure remote access
3. Create `DatabaseService` abstraction layer to support multiple backends
4. Implement `MssqlDatabaseService` extending abstract `DatabaseService`
5. Migrate schema with minimal changes (INTEGER → INT, TEXT → NVARCHAR)
6. Add connection pooling for mobile clients
7. Implement authentication and authorization

**Short-term Setup:**
```
Client Apps → OpenVPN → Home/Office Server → SQL Server Express
```

**Long-term Cloud Migration:**
```
Client Apps → Internet → Azure SQL Database
```

### Secondary Recommendation: Supabase

**If ease of setup and modern features are prioritized over familiarity:**

**Rationale:**
1. **Quick Start:** Fastest to get up and running with minimal infrastructure
2. **SQL Support:** Keeps relational model with foreign keys
3. **Real-Time Features:** Built-in real-time updates enhance UX
4. **Free Tier:** 500MB sufficient for initial testing and development
5. **Flutter Integration:** Well-documented Flutter package

**Trade-offs:**
- Learning curve for new platform
- 500MB limit requires eventual upgrade to $25/month Pro tier
- Less control compared to self-hosted solution

### Not Recommended (For This Use Case)

**Firebase Firestore:**
- Too much architectural change from relational to NoSQL
- Loss of foreign key constraints requires significant app logic changes
- Not worth learning curve given MSSQL familiarity

**DynamoDB:**
- Overly complex for this use case
- NoSQL paradigm shift not justified by requirements
- AWS ecosystem overhead for simple tracking app
- Less mature Dart support

**PostgreSQL (Cloud-Hosted):**
- Similar to MSSQL but less familiar to RURational2000
- No significant advantage over MSSQL to justify learning curve
- Comparable costs to Azure SQL migration path

## Implementation Roadmap

### Phase 1: Architecture Preparation (Week 1-2)
- [ ] Create abstract `DatabaseService` interface
- [ ] Refactor current `DatabaseService` to `SqliteDatabaseService` implementing interface
- [ ] Update `TrackingProvider` to use interface instead of concrete implementation
- [ ] Add database selection configuration (environment variable or config file)
- [ ] Write unit tests for database abstraction layer

### Phase 2: MSSQL Implementation (Week 3-4)
- [ ] Set up SQL Server Express on target machine
- [ ] Configure OpenVPN access
- [ ] Implement `MssqlDatabaseService` class
- [ ] Convert SQLite schema to MSSQL T-SQL
- [ ] Implement connection pooling for mobile clients
- [ ] Add authentication and authorization logic
- [ ] Test CRUD operations over network

### Phase 3: Data Migration Tools (Week 5)
- [ ] Create migration script to export SQLite data
- [ ] Create migration script to import into MSSQL
- [ ] Test migration with sample data
- [ ] Document migration process for users

### Phase 4: Multi-User Support (Week 6-7)
- [ ] Add user/entity identification to schema
- [ ] Implement user authentication in app
- [ ] Add row-level security in database
- [ ] Update UI for user management
- [ ] Test multi-user scenarios

### Phase 5: Testing & Deployment (Week 8)
- [ ] Integration testing across platforms
- [ ] Performance testing over internet connection
- [ ] Security audit
- [ ] Documentation updates
- [ ] Gradual rollout to users

## Security Considerations

### For MSSQL Implementation
1. **Network Security:**
   - Use OpenVPN for encrypted tunnel
   - Never expose SQL Server directly to internet
   - Implement IP whitelisting on OpenVPN
   
2. **Authentication:**
   - Use SQL Server authentication (not Windows auth for remote access)
   - Strong passwords with complexity requirements
   - Consider rotating credentials periodically
   
3. **Authorization:**
   - Create specific database user for app (not sa account)
   - Grant minimum required permissions (INSERT, SELECT, UPDATE, DELETE on specific tables)
   - Use schemas to isolate entities/companies
   
4. **Data Protection:**
   - Enable Transparent Data Encryption (TDE) if using Standard/Enterprise (not available in Express)
   - Regular backups with encryption
   - Consider SSL/TLS for SQL Server connections in addition to VPN

### General Best Practices
- Store connection strings securely (not in source code)
- Implement rate limiting to prevent abuse
- Log all authentication attempts
- Monitor for unusual access patterns
- Regular security updates for database server

## Migration from SQLite to MSSQL

### Schema Conversion

```sql
-- SQLite to MSSQL conversions needed:

-- Projects table
CREATE TABLE projects (
  id INT PRIMARY KEY IDENTITY(1,1),      -- AUTOINCREMENT → IDENTITY
  name NVARCHAR(255) NOT NULL,           -- TEXT → NVARCHAR
  totalMinutes INT NOT NULL DEFAULT 0,   -- INTEGER → INT
  createdAt DATETIME2 NOT NULL,          -- TEXT → DATETIME2
  lastActiveAt DATETIME2                 -- TEXT → DATETIME2
);

-- Instances table
CREATE TABLE instances (
  id INT PRIMARY KEY IDENTITY(1,1),
  projectId INT NOT NULL,
  startTime DATETIME2 NOT NULL,
  endTime DATETIME2,
  durationMinutes INT NOT NULL DEFAULT 0,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
);

-- Notes table
CREATE TABLE notes (
  id INT PRIMARY KEY IDENTITY(1,1),
  instanceId INT NOT NULL,
  content NVARCHAR(MAX) NOT NULL,        -- TEXT → NVARCHAR(MAX) for large text
  createdAt DATETIME2 NOT NULL,
  FOREIGN KEY (instanceId) REFERENCES instances (id) ON DELETE CASCADE
);

-- Indexes
CREATE NONCLUSTERED INDEX idx_instances_projectId ON instances(projectId);
CREATE NONCLUSTERED INDEX idx_notes_instanceId ON notes(instanceId);
```

### Data Type Mappings

| SQLite Type | MSSQL Type | Notes |
|-------------|------------|-------|
| INTEGER | INT | Standard integer |
| AUTOINCREMENT | IDENTITY(1,1) | Auto-incrementing ID |
| TEXT | NVARCHAR(n) or NVARCHAR(MAX) | Unicode string, specify length for indexed columns |
| TEXT (ISO8601) | DATETIME2 | Higher precision than DATETIME |
| NULL | NULL | Same behavior |

### Application Code Changes

```dart
// Abstract interface
abstract class DatabaseService {
  Future<void> initialize();
  Future<int> insertProject(Project project);
  Future<List<Project>> getAllProjects();
  Future<Project?> getProject(int id);
  Future<void> updateProject(Project project);
  // ... other methods
}

// MSSQL implementation
class MssqlDatabaseService implements DatabaseService {
  late MssqlConnection _connection;
  
  @override
  Future<void> initialize() async {
    _connection = MssqlConnection.getInstance();
    await _connection.connect(
      ip: "vpn.example.com",
      port: "1433",
      databaseName: "ProjectTracking",
      username: "trackinguser",
      password: _getPassword(), // From secure storage
    );
  }
  
  @override
  Future<int> insertProject(Project project) async {
    String query = '''
      INSERT INTO projects (name, totalMinutes, createdAt, lastActiveAt)
      OUTPUT INSERTED.id
      VALUES (@name, @totalMinutes, @createdAt, @lastActiveAt)
    ''';
    
    var result = await _connection.writeData(query, {
      'name': project.name,
      'totalMinutes': project.totalMinutes,
      'createdAt': project.createdAt.toIso8601String(),
      'lastActiveAt': project.lastActiveAt?.toIso8601String(),
    });
    
    return result[0]['id'] as int;
  }
  
  // ... implement other methods
}

// Configuration
class DatabaseConfig {
  static DatabaseService createDatabaseService() {
    // Read from environment or config file
    String dbType = const String.fromEnvironment('DB_TYPE', defaultValue: 'sqlite');
    
    switch (dbType) {
      case 'mssql':
        return MssqlDatabaseService();
      case 'sqlite':
      default:
        return SqliteDatabaseService();
    }
  }
}
```

## Performance Considerations

### Network Latency
- **SQLite (local):** ~1-10ms for queries
- **MSSQL over OpenVPN:** ~50-500ms depending on connection
- **Cloud databases:** ~100-300ms typical

**Mitigation Strategies:**
1. **Caching:** Cache frequently accessed data (project list, active instance)
2. **Batch Operations:** Combine multiple operations when possible
3. **Optimistic UI Updates:** Update UI immediately, sync in background
4. **Connection Pooling:** Reuse database connections to reduce overhead

### Query Optimization
```sql
-- Add indexes for common queries
CREATE INDEX idx_projects_lastActiveAt ON projects(lastActiveAt DESC);
CREATE INDEX idx_instances_startTime ON instances(startTime DESC);

-- Use query plans to identify slow queries
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
-- Run query
-- Analyze execution plan in SSMS
```

## Cost Projections

### Year 1: Self-Hosted MSSQL
- SQL Server Express: Free
- OpenVPN: Free (self-hosted) or $120/year (cloud VPN)
- Hardware/Server: $0 (using existing) or $240-600/year (VPS)
- **Total: $0-720/year**

### Year 2-3: Azure Migration
- Azure SQL Database Basic (2GB): $60/year
- Bandwidth: ~$5/month = $60/year
- **Total: ~$120/year** (with free tier discounts)

### Year 3+: Growth
- Azure SQL Standard S1 (250GB): $180/year
- Bandwidth: ~$10/month = $120/year
- **Total: ~$300/year**

## Conclusion

**Recommended Approach:** Start with **Microsoft SQL Server Express** over OpenVPN for the following reasons:

1. **Leverages Existing Expertise:** Minimal learning curve for RURational2000
2. **Low Initial Cost:** Free with existing infrastructure
3. **Control & Security:** Complete control over data and access
4. **Clear Upgrade Path:** Well-defined migration to Azure when needed
5. **SQL Compatibility:** Minimal code changes from SQLite

**Next Steps:**
1. Approve this recommendation
2. Begin Phase 1: Architecture Preparation
3. Set up test SQL Server Express environment
4. Prototype MSSQL connection from Flutter app
5. Develop migration tooling
6. Create user documentation

**Alternative Path:** If infrastructure management is a concern, consider **Supabase** as a managed alternative that preserves SQL capabilities while offering modern real-time features.

---

**Document Version:** 1.0  
**Last Updated:** November 19, 2025  
**Review Date:** January 2026

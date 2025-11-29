# Database Migration to Client-Server Architecture - Summary

## Quick Overview

This document provides a summary of the database alternatives analysis for migrating from SQLite to a centralized client-server database. For the full detailed analysis, see [docs/database-alternatives-consideration.md](docs/database-alternatives-consideration.md).

## Current Situation

- **Database:** SQLite (local storage per device)
- **Limitation:** No centralized access across devices or users
- **Need:** Internet-accessible centralized database for project tracking

## Recommended Solution: Microsoft SQL Server (MSSQL)

### Why MSSQL?

1. ✅ **Strong Familiarity** - RURational2000 has extensive MSSQL experience
2. ✅ **Free Tier** - SQL Server Express supports up to 10GB (sufficient for initial scope)
3. ✅ **Easy Migration** - Minimal schema changes from SQLite to MSSQL
4. ✅ **Clear Cloud Path** - Straightforward migration to Azure SQL Database later
5. ✅ **Full SQL Support** - Complete relational database with foreign keys and transactions

### Implementation Approach

**Short-term (Self-hosted):**
```
Flutter Apps → OpenVPN → SQL Server Express (Windows Server/PC)
```

**Long-term (Cloud):**
```
Flutter Apps → Internet → Azure SQL Database
```

### Quick Comparison

| Database | Familiarity | Free Tier | Setup | SQL Support | Recommendation |
|----------|-------------|-----------|-------|-------------|----------------|
| **MSSQL** | ⭐⭐⭐⭐⭐ | 10GB | Complex | ✅ Full | **PRIMARY** |
| **Supabase** | ⭐⭐ | 500MB | Easy | ✅ Full | Secondary |
| **Firebase** | ⭐ | 1GB | Easy | ❌ NoSQL | Not recommended |
| **DynamoDB** | ⭐ | 25GB | Medium | ❌ NoSQL | Not recommended |
| **PostgreSQL** | ⭐⭐⭐ | Limited | Medium | ✅ Full | Not recommended |

## What Changes Are Needed?

### 1. Database Schema (Minimal Changes)
```sql
-- SQLite → MSSQL conversions:
- INTEGER AUTOINCREMENT → INT IDENTITY(1,1)
- TEXT → NVARCHAR(n) or NVARCHAR(MAX)
- TEXT (ISO8601 dates) → DATETIME2
```

### 2. Application Code
- Replace SQLite database service with MSSQL database service
- Add `mssql_connection` package dependency
- Configure connection parameters for MSSQL

### 3. Security & Access
- Configure OpenVPN for secure remote access
- Implement SQL Server authentication
- Add user/entity identification for multi-user support
- Set up proper authorization and permissions

## Cost Estimates

- **Year 1 (Self-hosted):** $0-720/year depending on infrastructure
- **Year 2+ (Azure):** ~$120-300/year depending on usage

## Next Steps

1. ✅ Review and approve this recommendation
2. ⏳ Set up development environment with SQL Server Express
3. ⏳ Implement MSSQL database service
4. ⏳ Test and deploy

## Not Recommended

**Firebase & DynamoDB** - Both are NoSQL databases requiring significant architectural changes from the current relational model. The effort to refactor from foreign keys to manual relationship handling is not justified given MSSQL familiarity and SQL Server Express free tier.

---

📄 **Full Analysis:** [docs/database-alternatives-consideration.md](docs/database-alternatives-consideration.md)  
📅 **Created:** November 19, 2025  
👤 **Contact:** RURational2000

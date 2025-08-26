# Design Document

## Overview

The Tournament Control table feature introduces a centralized mechanism for managing active tournament sessions across different tournament types (WMGT, KWT, FHIT). This design replaces the current approach of using the `current_flag` column in the `wmg_tournaments` table with a dedicated control table that can handle multiple concurrent tournament types.

**Important Context:** In this system, `wmg_tournaments` represents seasons (containing ~12 tournaments each), and `wmg_tournament_sessions` represents the individual tournaments within a season. The control table will point to specific tournament sessions (individual tournaments) rather than entire seasons.

The solution consists of:
1. A new `wmg_tournament_control` table to store active tournament session pointers
2. Updated API procedures to use the control table
3. Database procedures for managing tournament control operations
4. Audit logging capabilities for tracking changes

## Architecture

### Current State Analysis

Currently, the system uses `wmg_tournaments.current_flag = 'Y'` to identify the active season, then applies additional logic to find the current tournament session within that season. The `current_tournament` procedure in `wmg_rest_api` package queries for:
- Seasons where `current_flag = 'Y'` and `active_ind = 'Y'`
- Tournament sessions within those seasons that meet date criteria
- Additional filtering to find the "current" tournament session

This approach has limitations:
- Only one season can be active at a time across all tournament types
- No clear separation between WMGT, KWT, and FHIT tournament sessions
- Complex logic needed to determine the "current" tournament session within a season
- Difficulty running concurrent tournaments for different tournament types

### Proposed Architecture

The new architecture introduces a control layer that sits between the application logic and the tournament session data:

```
Application Layer
       ↓
Tournament Control Layer (New)
       ↓
Tournament Session Data Layer (wmg_tournament_sessions)
       ↓
Season Data Layer (wmg_tournaments)
```

## Components and Interfaces

### 1. Tournament Control Table

**Table Name:** `wmg_tournament_control`

**Purpose:** Maintains pointers to active tournament sessions for each tournament type.

**Columns:**
- `tournament_type_code` (VARCHAR2(10)) - Primary key, identifies tournament type (WMGT, KWT, FHIT)
- `tournament_session_id` (NUMBER) - Nullable foreign key to `wmg_tournament_sessions.id`
- `created_on` (TIMESTAMP WITH LOCAL TIME ZONE) - Audit timestamp
- `created_by` (VARCHAR2(60)) - Audit user
- `updated_on` (TIMESTAMP WITH LOCAL TIME ZONE) - Audit timestamp  
- `updated_by` (VARCHAR2(60)) - Audit user

**Constraints:**
- Primary key on `tournament_type_code`
- Foreign key to `wmg_tournament_sessions(id)` (nullable to support tournament breaks)

### 2. API Procedures

#### Enhanced Current Tournament API

**Procedure:** `wmg_rest_api.current_tournament`

**Changes:**
- Add optional parameter `p_tournament_type` (default 'WMGT')
- Query from `wmg_tournament_control` instead of using `current_flag`
- Maintain backward compatibility for existing callers

**New Signature:**
```sql
procedure current_tournament(
    p_output out clob,
    p_tournament_type in varchar2 default 'WMGT'
);
```

#### Tournament Control Management API

**Package:** `wmg_util` (new procedures)

```sql
procedure set_current_tournament_session(
    p_tournament_type in varchar2,
    p_tournament_session_id in number
);

function get_current_tournament_session_id(
    p_tournament_type in varchar2 default 'WMGT'
) return number;
```

### 3. Database Procedures

#### Tournament Control Management

**Package:** `wmg_util` (enhanced procedures)

```sql
procedure set_tournament_control(
    p_tournament_type in varchar2,
    p_tournament_session_id in number
);

function get_tournament_control(
    p_tournament_type in varchar2
) return number;

procedure validate_tournament_session(
    p_tournament_session_id in number
);

procedure clear_tournament_control(
    p_tournament_type in varchar2
);
```

### 4. Migration Strategy

#### Phase 1: Table Creation and Initial Data
1. Create `wmg_tournament_control` table
2. Populate initial data based on current `current_flag = 'Y'` tournaments
3. Create indexes and constraints

#### Phase 2: API Updates
1. Update `current_tournament` procedure to use control table
2. Add new tournament control management procedures
3. Maintain backward compatibility

#### Phase 3: Cleanup (Future)
1. Remove dependency on `current_flag` column
2. Update other procedures that use `current_flag`

## Data Models

### Tournament Control Table Schema

```sql
CREATE TABLE wmg_tournament_control (
    tournament_type_code       VARCHAR2(10 CHAR) 
                              CONSTRAINT wmg_tournament_control_pk PRIMARY KEY,
    tournament_session_id      NUMBER 
                              CONSTRAINT wmg_tournament_control_fk
                              REFERENCES wmg_tournament_sessions(id),
    created_on                 TIMESTAMP WITH LOCAL TIME ZONE 
                              DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by                 VARCHAR2(60 CHAR) 
                              DEFAULT COALESCE(SYS_CONTEXT('APEX$SESSION','APP_USER'),USER) NOT NULL,
    updated_on                 TIMESTAMP WITH LOCAL TIME ZONE,
    updated_by                 VARCHAR2(60 CHAR)
);
```

### Tournament Control View

```sql
CREATE OR REPLACE VIEW wmg_tournament_control_v AS
SELECT tc.tournament_type_code,
       tc.tournament_session_id,
       ts.tournament_id,
       ts.round_num,
       ts.session_date,
       ts.week,
       ts.open_registration_on,
       ts.close_registration_on,
       ts.registration_closed_flag,
       ts.rooms_open_flag,
       ts.rooms_defined_flag,
       ts.rooms_defined_by,
       ts.rooms_defined_on,
       ts.completed_ind,
       ts.completed_on,
       t.name as tournament_name,
       t.code as tournament_code,
       t.prefix_tournament,
       t.prefix_session,
       t.current_flag,
       t.active_ind,
       t.url,
       t.prefix_room_name,
       t.start_date,
       tc.created_on as control_created_on,
       tc.created_by as control_created_by,
       tc.updated_on as control_updated_on,
       tc.updated_by as control_updated_by
  FROM wmg_tournament_control tc
  LEFT JOIN wmg_tournament_sessions ts ON tc.tournament_session_id = ts.id
  LEFT JOIN wmg_tournaments t ON ts.tournament_id = t.id;
```

## Error Handling

### Error Scenarios and Responses

1. **No Active Tournament Session for Type**
   - Error Code: `NO_ACTIVE_TOURNAMENT_SESSION`
   - HTTP Status: 404
   - Message: "No active tournament session found for type {tournament_type} (tournament break period)"

2. **Invalid Tournament Session ID**
   - Error Code: `INVALID_TOURNAMENT_SESSION`
   - HTTP Status: 400
   - Message: "Tournament session {id} does not exist"

3. **Invalid Tournament Type**
   - Error Code: `INVALID_TOURNAMENT_TYPE`
   - HTTP Status: 400
   - Message: "Tournament type {type} is not supported"

### Error Handling Implementation

```sql
-- New error constants in wmg_rest_api package
c_error_no_active_tournament_session constant varchar2(30) := 'NO_ACTIVE_TOURNAMENT_SESSION';
c_error_invalid_tournament_type      constant varchar2(30) := 'INVALID_TOURNAMENT_TYPE';
c_error_invalid_tournament_session   constant varchar2(30) := 'INVALID_TOURNAMENT_SESSION';
```

## Testing Strategy

### Unit Tests

1. **Tournament Control Table Operations**
   - Insert/Update/Delete operations
   - Constraint validation
   - Foreign key integrity

2. **API Procedure Tests**
   - `current_tournament` with different tournament types
   - `set_current_tournament` with valid/invalid data
   - `get_current_tournament_session_id` edge cases

3. **Error Handling Tests**
   - Invalid tournament types
   - Non-existent tournament sessions
   - No active tournament scenarios

### Integration Tests

1. **End-to-End Tournament Control Flow**
   - Set active tournament for multiple types
   - Retrieve current tournament information
   - Verify data consistency

2. **Migration Testing**
   - Verify initial data population
   - Test backward compatibility
   - Validate existing functionality

### Performance Tests

1. **Query Performance**
   - Compare performance vs current `current_flag` approach
   - Test with multiple concurrent tournament types
   - Validate index effectiveness

## Implementation Notes

### Backward Compatibility

- The `current_tournament` procedure will maintain its existing signature
- Default tournament type will be 'WMGT' to preserve existing behavior
- Existing callers will continue to work without changes

### Data Population Strategy

Initial data will be populated to support tournament breaks and current active sessions:

```sql
-- Insert base tournament types, starting with WMGT with no active session (tournament break scenario)
INSERT INTO wmg_tournament_control (tournament_type_code, tournament_session_id)
VALUES ('WMGT', NULL);

-- Optionally populate with current active sessions if they exist
INSERT INTO wmg_tournament_control (tournament_type_code, tournament_session_id)
SELECT t.code, 
       (SELECT id FROM wmg_tournament_sessions ts 
        WHERE ts.tournament_id = t.id 
          AND ts.session_date + 1 >= TRUNC(CURRENT_TIMESTAMP)
          AND ts.completed_ind = 'N'
        ORDER BY ts.session_date
        FETCH FIRST 1 ROWS ONLY)
  FROM wmg_tournaments t
 WHERE t.current_flag = 'Y'
   AND t.active_ind = 'Y'
   AND t.code != 'WMGT'  -- WMGT already inserted above
   AND EXISTS (SELECT 1 FROM wmg_tournament_sessions ts 
               WHERE ts.tournament_id = t.id 
                 AND ts.session_date + 1 >= TRUNC(CURRENT_TIMESTAMP)
                 AND ts.completed_ind = 'N');
```

### Indexing Strategy

- Primary key on `tournament_type_code` provides fast lookups
- Foreign key index on `tournament_session_id` for referential integrity
- Consider composite index if query patterns require it

### Audit Trail

The table includes standard audit columns (`created_on`, `created_by`, `updated_on`, `updated_by`) with triggers to automatically populate update timestamps and users, following the existing pattern in other tables.
# Tournament Control Data Population

This directory contains scripts for populating and managing the `wmg_tournament_control` table data.

## Overview

The tournament control table maintains pointers to active tournament sessions for each tournament type (WMGT, KWT, FHIT). This implementation supports tournament breaks by allowing NULL values for `tournament_session_id`.

## Requirements Addressed

- **5.4**: Tournament Control table supports exactly one active tournament per tournament type
- **5.5**: Table structure accommodates new tournament types without schema changes

## Scripts

### 1. seed_wmg_tournament_control.sql
**Purpose**: Populates initial tournament control data

**Features**:
- Inserts base WMGT record with NULL tournament_session_id (tournament break state)
- Populates other tournament types based on current active sessions
- Handles tournament types without active sessions (tournament break state)
- Includes data verification queries

**Usage**:
```sql
@data/seed_wmg_tournament_control.sql
```

### 2. test_wmg_tournament_control_population.sql
**Purpose**: Tests population logic without inserting data

**Features**:
- Validates population queries
- Shows simulated results
- Checks for potential foreign key violations
- Displays tournament session status

**Usage**:
```sql
@data/test_wmg_tournament_control_population.sql
```

### 3. verify_wmg_tournament_control.sql
**Purpose**: Comprehensive verification of tournament control data

**Features**:
- Table structure verification
- Constraint validation
- Data integrity checks
- Foreign key validation
- Audit trail verification

**Usage**:
```sql
@data/verify_wmg_tournament_control.sql
```

### 4. rollback_wmg_tournament_control.sql
**Purpose**: Removes all data from tournament control table

**Features**:
- Shows current data before rollback
- Confirmation prompt
- Complete data removal
- Rollback confirmation

**Usage**:
```sql
@data/rollback_wmg_tournament_control.sql
```

## Population Logic

### WMGT Tournament Break
- Always inserts WMGT with NULL tournament_session_id
- Represents the current tournament break state
- Satisfies requirement for supporting tournament breaks

### Active Tournament Sessions
- Queries tournaments with `current_flag = 'Y'` and `active_ind = 'Y'`
- Finds active sessions (not completed, within date range)
- Selects the earliest active session for each tournament type

### Tournament Break States
- Tournament types without active sessions get NULL tournament_session_id
- Ensures all active tournament types are represented in the control table

## Data Integrity

### Foreign Key Validation
- All non-NULL tournament_session_id values reference valid wmg_tournament_sessions records
- Verification queries check for orphaned references

### Constraint Validation
- Primary key on tournament_type_code ensures one record per tournament type
- Foreign key constraint ensures referential integrity

### Audit Trail
- Standard audit columns (created_on, created_by, updated_on, updated_by)
- Automatic population via triggers

## Execution Order

1. **Test First**: Run `test_wmg_tournament_control_population.sql` to validate logic
2. **Populate**: Run `seed_wmg_tournament_control.sql` to insert data
3. **Verify**: Run `verify_wmg_tournament_control.sql` to confirm success
4. **Rollback** (if needed): Run `rollback_wmg_tournament_control.sql` to undo

## Expected Results

After successful population:
- WMGT tournament type with NULL session (tournament break)
- Other active tournament types with either active sessions or NULL (tournament break)
- All foreign key relationships valid
- Audit trail populated correctly

## Troubleshooting

### No Tournament Types Found
- Check that wmg_tournaments table has records with active_ind = 'Y'
- Verify tournament codes are properly set

### Foreign Key Violations
- Ensure wmg_tournament_sessions table exists and has valid data
- Check that session IDs being referenced actually exist

### Duplicate Tournament Types
- Verify primary key constraint is in place
- Check for existing data before running population script

## Integration Notes

- These scripts assume the wmg_tournament_control table has been created
- Table creation is handled by install/wmg_tournament_control.sql
- Population should be run after table creation but before API deployment
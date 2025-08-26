# Requirements Document

## Introduction

This feature introduces a Tournament Control table that maintains pointers to the current active tournaments for each tournament type (WMGT, KWT, FHIT). The primary goal is to simplify code throughout the system that needs to determine which tournament is currently active for a specific tournament type, eliminating the need for complex queries or hardcoded logic to identify the active tournament.

## Requirements

### Requirement 1

**User Story:** As a system administrator, I want a centralized way to manage which tournament is currently active for each tournament type (WMGT, KWT, FHIT), so that all system components can easily reference the current tournament for a specific type without complex logic.

#### Acceptance Criteria

1. WHEN the system needs to identify the current tournament for a specific type THEN it SHALL query the Tournament Control table by tournament type code
2. WHEN a new tournament becomes active for a tournament type THEN the Tournament Control table SHALL be updated to point to the new tournament session ID for that type
3. WHEN querying the Tournament Control table for a specific tournament type THEN it SHALL return exactly one active tournament session record for that type
4. IF no tournament is set as active for a tournament type THEN the system SHALL handle this gracefully with appropriate error messaging
5. WHEN multiple tournament types are active simultaneously THEN each SHALL maintain its own independent active tournament pointer

### Requirement 2

**User Story:** As a developer, I want a simple API to get the current tournament session ID for a specific tournament type, so that I can write cleaner code without complex tournament selection logic.

#### Acceptance Criteria

1. WHEN calling the get current tournament API with a tournament type code THEN it SHALL return the tournament session ID from the Tournament Control table
2. WHEN the Tournament Control table has no active tournament for the specified type THEN the API SHALL return a clear error indicating no active tournament for that type
3. WHEN multiple systems call the API simultaneously for the same tournament type THEN it SHALL return consistent results
4. WHEN the API is called THEN it SHALL complete within acceptable performance limits
5. WHEN calling the API without specifying a tournament type THEN it SHALL default to WMGT tournament type

### Requirement 3

**User Story:** As a system administrator, I want to be able to change which tournament is active for each tournament type, so that I can control tournament transitions without code changes.

#### Acceptance Criteria

1. WHEN setting a new active tournament for a tournament type THEN the system SHALL validate that the tournament session exists in wmg_tournament_sessions
2. WHEN setting a new active tournament for a tournament type THEN any previously active tournament for that type SHALL be replaced
3. WHEN changing the active tournament for a tournament type THEN dependent systems SHALL be able to detect the change
4. WHEN an invalid tournament session ID is provided THEN the system SHALL reject the change with an appropriate error message
5. WHEN setting an active tournament THEN it SHALL not affect the active tournaments of other tournament types

### Requirement 4

**User Story:** As a system administrator, I want audit capabilities for tournament control changes, so that I can track when and why the active tournament was changed for each tournament type.

#### Acceptance Criteria

1. WHEN the active tournament is changed for any tournament type THEN the system SHALL log the change with timestamp, tournament type, and user information
2. WHEN querying tournament control history THEN the system SHALL provide a chronological record of changes by tournament type
3. WHEN a tournament control change fails THEN the system SHALL log the failure reason along with the tournament type
4. WHEN reviewing audit logs THEN they SHALL include both successful and failed tournament control operations for all tournament types
5. WHEN multiple tournament types are updated simultaneously THEN each change SHALL be logged separately

### Requirement 5

**User Story:** As a database administrator, I want the Tournament Control table to have a clear structure that supports multiple tournament types, so that the system can scale to support additional tournament types in the future.

#### Acceptance Criteria

1. WHEN the Tournament Control table is created THEN it SHALL have a tournament_type_code column to identify the tournament type (WMGT, KWT, FHIT)
2. WHEN the Tournament Control table is created THEN it SHALL have a tournament_session_id column that references wmg_tournament_sessions.id
3. WHEN the Tournament Control table is created THEN it SHALL have appropriate constraints to ensure data integrity
4. WHEN the Tournament Control table is created THEN it SHALL support exactly one active tournament per tournament type
5. WHEN new tournament types are added in the future THEN the table structure SHALL accommodate them without schema changes
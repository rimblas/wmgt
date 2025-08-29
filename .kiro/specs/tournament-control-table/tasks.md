# Implementation Plan

- [x] 1. Create tournament control table and supporting database objects
  - Create wmg_tournament_control table with nullable tournament_session_id to support tournament breaks
  - Create update trigger following existing patterns for audit columns
  - Create wmg_tournament_control_v view with comprehensive tournament session details
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 2. Populate initial tournament control data
  - Insert base WMGT record with NULL tournament_session_id to represent current tournament break state
  - Create population script for other tournament types based on current active sessions
  - Verify data integrity and foreign key relationships
  - _Requirements: 5.4, 5.5_

- [x] 3. Implement tournament control management procedures in wmg_util package
  - Add set_tournament_control procedure to update active tournament sessions
  - Add get_tournament_control function to retrieve current tournament session ID
  - Add clear_tournament_control procedure to handle tournament breaks
  - Add validate_tournament_session procedure for data integrity
  - _Requirements: 2.1, 2.2, 3.1, 3.2, 3.3_

- [x] 4. Update wmg_rest_api.current_tournament procedure to use control table
  - Modify current_tournament procedure to query from wmg_tournament_control instead of current_flag
  - Add optional p_tournament_type parameter with WMGT default for backward compatibility
  - Handle NULL tournament_session_id case for tournament breaks with appropriate error response
  - Maintain existing JSON response format for backward compatibility
  - _Requirements: 2.3, 2.4, 2.5_

- [x] 5. Add new error constants and handling for tournament control scenarios
  - Add NO_ACTIVE_TOURNAMENT_SESSION error constant to wmg_rest_api package
  - Add INVALID_TOURNAMENT_TYPE error constant
  - Add INVALID_TOURNAMENT_SESSION error constant
  - Implement error handling in tournament control procedures
  - _Requirements: 1.4, 3.4_

- [x] 6. Create unit tests for tournament control functionality
  - Test wmg_tournament_control table operations (insert, update, delete)
  - Test tournament control management procedures with valid and invalid data
  - Test current_tournament procedure with different tournament types and NULL sessions
  - Test error handling scenarios for all new procedures
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2_

- [ ] 7. Create integration tests for end-to-end tournament control workflow
  - Test setting active tournament session for multiple tournament types
  - Test clearing tournament session to simulate tournament break
  - Test current_tournament API response during tournament breaks
  - Verify backward compatibility with existing API consumers
  - _Requirements: 1.5, 2.3, 2.4, 3.5_

- [x] 8. Update wmg_util.validate_tournament_state to use control table
  - Modify validate_tournament_state procedure to check wmg_tournament_control instead of current_flag
  - Maintain existing error handling and validation logic
  - Ensure compatibility with existing code that calls this procedure
  - _Requirements: 3.1, 3.2_

- [ ] 9. Create database migration script for production deployment
  - Create complete DDL script for table, view, and trigger creation
  - Create data population script with rollback capability
  - Create verification queries to confirm successful migration
  - Document deployment steps and rollback procedures
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
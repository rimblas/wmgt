# Implementation Plan

- [x] 1. Create VotesService class for API communication
  - Create `bots/src/services/VotesService.js` with axios client configuration
  - Implement `getVotingResults()` method to fetch data from votes API endpoint
  - Add error handling and retry logic using existing RetryHandler pattern
  - Include health check method for monitoring
  - _Requirements: 1.1, 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 2. Implement data processing utilities
  - Create functions to parse API response and extract course data
  - Implement logic to separate easy and hard courses into columns
  - Add formatting functions to create display strings for embed fields
  - Handle edge cases like null hard courses and zero/negative votes
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. Create votes slash command
  - Create `bots/src/commands/votes.js` with SlashCommandBuilder configuration
  - Implement command execution logic to fetch and display voting results
  - Create Discord embed with two-column layout showing Easy and Hard courses
  - Add proper error handling for API failures and malformed data
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 4. Integrate votes command into bot
  - Add votes command to the commands array in `bots/src/index.js`
  - Update configuration to include votes API endpoint
  - Test command registration and slash command availability
  - _Requirements: 1.1, 1.5_

- [x] 5. Implement embed formatting and visual indicators
  - Format course display with vote counts and course codes
  - Add visual highlighting for "top" voted courses
  - Ensure proper sorting by vote count within each column
  - Handle Discord character limits and field constraints
  - _Requirements: 1.4, 2.1, 2.2, 2.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 6. Add comprehensive error handling
  - Implement user-friendly error messages for different failure scenarios
  - Add logging for debugging API and processing errors
  - Test error scenarios like API unavailability and malformed responses
  - Ensure graceful degradation when data is incomplete
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 7. Create unit tests for VotesService
  - Write tests for API response parsing and data processing
  - Test error handling scenarios and retry logic
  - Mock API responses for various data scenarios
  - Validate health check functionality
  - _Requirements: 1.1, 1.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 8. Create integration tests for votes command
  - Test slash command execution with live API data
  - Validate embed generation and Discord formatting
  - Test command registration and interaction handling
  - Verify error responses are properly formatted
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5_
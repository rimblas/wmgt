# Requirements Document

## Introduction

This feature adds a `/votes` slash command to the Discord bot that displays current course voting results from the tournament system. The command fetches data from the existing votes REST API and presents it in a Discord embed, allowing users to view current standings. This is a read-only display command - actual voting functionality will be implemented separately via a future `/vote` command.

## Requirements

### Requirement 1

**User Story:** As a tournament participant, I want to view current course voting results through a Discord command, so that I can see which courses are most popular.

#### Acceptance Criteria

1. WHEN a user executes `/votes` THEN the system SHALL fetch current voting data from the votes REST API
2. WHEN the API returns voting data THEN the system SHALL display it in a Discord embed showing both easy and hard courses
3. WHEN displaying courses THEN the system SHALL show course codes, names, current vote counts, and vote rankings
4. WHEN courses have "top" status THEN the system SHALL visually highlight them in the display
5. IF the API is unavailable THEN the system SHALL respond with an appropriate error message

### Requirement 2

**User Story:** As a tournament participant, I want the voting display to be organized and easy to read, so that I can quickly understand the current standings.

#### Acceptance Criteria

1. WHEN displaying voting results THEN the system SHALL organize courses in a two-column layout (Easy | Hard)
2. WHEN showing course information THEN the system SHALL display vote counts as numbers next to course codes
3. WHEN courses have positive votes THEN the system SHALL display them at the top of their respective columns
4. WHEN courses have zero or negative votes THEN the system SHALL display them in descending order by vote count
5. WHEN courses are marked as "top" THEN the system SHALL use visual indicators to highlight them

### Requirement 3

**User Story:** As a tournament participant, I want the voting display to handle different data scenarios gracefully, so that the display works reliably regardless of API response variations.

#### Acceptance Criteria

1. WHEN some courses have null hard course data THEN the system SHALL display only the easy course information
2. WHEN vote counts are zero THEN the system SHALL display "0" clearly
3. WHEN vote counts are negative THEN the system SHALL display the negative number
4. WHEN courses have identical vote counts THEN the system SHALL maintain consistent ordering based on vote_order field
5. WHEN courses have no corresponding hard version THEN the system SHALL handle the display gracefully

### Requirement 4

**User Story:** As a tournament participant, I want the embed to display comprehensive course information, so that I can understand the full context of the voting results.

#### Acceptance Criteria

1. WHEN displaying courses THEN the system SHALL show both course codes and full course names
2. WHEN formatting the embed THEN the system SHALL use a layout similar to the reference image provided
3. WHEN courses are displayed THEN the system SHALL maintain the vote_order ranking from the API
4. WHEN the embed is created THEN the system SHALL include a clear title indicating this is voting results
5. WHEN displaying multiple courses THEN the system SHALL ensure the embed remains within Discord's character limits

### Requirement 5

**User Story:** As a system administrator, I want the voting command to handle API errors gracefully, so that users receive helpful feedback when issues occur.

#### Acceptance Criteria

1. WHEN the votes API is unreachable THEN the system SHALL display a clear error message with retry instructions
2. WHEN the API returns invalid data THEN the system SHALL log the error and inform the user of the issue
3. WHEN API rate limits are exceeded THEN the system SHALL inform users to wait before retrying
4. WHEN network timeouts occur THEN the system SHALL provide appropriate error messaging
5. WHEN the bot lacks permissions to create embeds THEN the system SHALL fall back to text-based display
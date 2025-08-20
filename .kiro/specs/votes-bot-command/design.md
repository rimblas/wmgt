# Design Document

## Overview

The `/votes` command will be implemented as a Discord slash command that fetches current voting data from the existing votes REST API and displays it in a formatted Discord embed. The command follows the established patterns in the existing Discord bot architecture, using the same service layer approach and error handling mechanisms.

## Architecture

### Command Structure
The votes command will follow the same pattern as existing commands (`register.js`, `unregister.js`, etc.):
- Located in `bots/src/commands/votes.js`
- Exports a command object with `data` (SlashCommandBuilder) and `execute` function
- Registered automatically in the main bot class (`DiscordTournamentBot`)

### Service Layer
A new `VotesService` class will be created to handle API communication:
- Located in `bots/src/services/VotesService.js`
- Extends the existing service pattern used by `RegistrationService`
- Uses the same axios client configuration, retry logic, and error handling

### API Integration
The service will integrate with the existing votes REST API:
- Endpoint: `https://apex.skillbuilders.com/ords/wmgt/tournament/votes`
- HTTP Method: GET
- Response format: JSON with `items` array containing course voting data

## Components and Interfaces

### VotesService Class

```javascript
class VotesService {
  constructor()
  async getVotingResults()
  handleApiError(error, context)
  getHealthStatus()
}
```

**Methods:**
- `getVotingResults()`: Fetches voting data from the REST API
- `handleApiError()`: Processes API errors with user-friendly messages
- `getHealthStatus()`: Provides service health information for monitoring

### Votes Command

```javascript
export default {
  data: SlashCommandBuilder
  async execute(interaction)
}
```

**Command Definition:**
- Name: `votes`
- Description: "Display current course voting results"
- No parameters required

### Data Processing Functions

```javascript
function formatVotingData(apiResponse)
function createVotesEmbed(formattedData)
function splitIntoColumns(courses)
```

**Utility Functions:**
- `formatVotingData()`: Processes raw API response into display format
- `createVotesEmbed()`: Builds Discord embed with voting results
- `splitIntoColumns()`: Organizes courses into Easy/Hard columns

## Data Models

### API Response Structure
```javascript
{
  items: [
    {
      easy_vote_order: number,
      hard_vote_order: number,
      easy_votes: number,
      easy_votes_top: string|null,
      easy_course: string,
      easy_name: string,
      hard_course: string|null,
      hard_name: string|null,
      hard_votes: number|null,
      hard_votes_top: string|null
    }
  ],
  hasMore: boolean,
  limit: number,
  offset: number,
  count: number
}
```

### Processed Data Structure
```javascript
{
  easyCourses: [
    {
      code: string,
      name: string,
      votes: number,
      isTop: boolean,
      order: number
    }
  ],
  hardCourses: [
    {
      code: string,
      name: string,
      votes: number,
      isTop: boolean,
      order: number
    }
  ]
}
```

### Discord Embed Structure
```javascript
{
  title: "🏆 Course Voting Results",
  color: 0x00AE86,
  fields: [
    {
      name: "Easy Courses",
      value: string, // Formatted course list
      inline: true
    },
    {
      name: "Hard Courses", 
      value: string, // Formatted course list
      inline: true
    }
  ],
  footer: {
    text: "Vote counts updated in real-time"
  },
  timestamp: Date
}
```

## Error Handling

### API Error Scenarios
1. **Network Connectivity Issues**
   - Timeout errors (15 second timeout)
   - Connection refused
   - DNS resolution failures

2. **API Response Issues**
   - HTTP 4xx/5xx status codes
   - Malformed JSON responses
   - Empty or null response data

3. **Data Processing Issues**
   - Missing required fields in API response
   - Invalid data types
   - Unexpected data structure

### Error Response Strategy
- Use existing `ErrorHandler` class for consistent error processing
- Implement retry logic via `RetryHandler` (up to 3 retries)
- Display user-friendly error messages in Discord embeds
- Log detailed error information for debugging

### Fallback Behavior
- If API is unavailable: Display "Service temporarily unavailable" message
- If data is malformed: Display "Unable to process voting data" message
- If no courses found: Display "No voting data available" message

## Testing Strategy

### Unit Tests
1. **VotesService Tests**
   - API response parsing
   - Error handling scenarios
   - Retry logic validation
   - Health check functionality

2. **Data Processing Tests**
   - Course data formatting
   - Column splitting logic
   - Edge cases (null hard courses, zero votes)
   - Embed generation

3. **Command Tests**
   - Slash command registration
   - Interaction handling
   - Error response formatting
   - Integration with service layer

### Integration Tests
1. **API Integration**
   - Live API endpoint testing
   - Response format validation
   - Error scenario simulation
   - Performance benchmarking

2. **Discord Integration**
   - Embed rendering validation
   - Character limit compliance
   - Command registration verification
   - User interaction testing

### Test Data
- Mock API responses with various scenarios:
  - Full course list with mixed vote counts
  - Courses with null hard versions
  - Empty response
  - Error responses
- Test embed character limits with maximum course data
- Validate formatting with edge cases (negative votes, zero votes)

## Implementation Details

### Configuration Updates
Add votes API endpoint to `config.js`:
```javascript
api: {
  endpoints: {
    // existing endpoints...
    votes: '/tournament/votes'
  }
}
```

### Service Registration
The `VotesService` will be instantiated in the votes command file, following the same pattern as other commands that use `RegistrationService`.

### Command Registration
The votes command will be added to the commands array in `index.js` alongside existing commands.

### Embed Formatting
- Use two-column layout (Easy | Hard) as shown in reference image
- Display vote counts as numbers next to course codes
- Highlight "top" courses with visual indicators (emoji or formatting)
- Sort courses by vote count within each column
- Handle Discord's 1024 character limit per field by truncating if necessary

### Performance Considerations
- Cache API responses for 30 seconds to reduce API load
- Implement request deduplication for concurrent command usage
- Use efficient string building for embed content
- Monitor embed size to stay within Discord limits

## Security Considerations

### API Security
- Use HTTPS for all API communications
- Implement request timeout to prevent hanging connections
- Validate API response structure before processing
- Sanitize any user-displayable content from API

### Discord Security
- Validate interaction source
- Use ephemeral responses when appropriate
- Implement rate limiting per user
- Sanitize embed content to prevent injection

### Error Information Disclosure
- Log detailed errors server-side only
- Display generic error messages to users
- Avoid exposing internal API details
- Implement error correlation IDs for debugging
# Design Document

## Overview

The "/course" slash command will integrate with the existing Discord bot architecture to provide course-specific leaderboard data. The command will leverage the existing leaderboards API endpoint (`/leaderboards/course/:code`) and follow the established patterns used by other commands like `/votes`.

The design focuses on providing an intuitive user experience with course selection via Discord's autocomplete functionality, robust error handling, and consistent formatting with existing bot commands.

## Architecture

### Command Structure
The command follows the existing bot architecture pattern:
- **Command Definition**: Uses Discord.js SlashCommandBuilder with autocomplete support
- **Service Layer**: CourseLeaderboardService handles API communication and data processing
- **Error Handling**: Leverages existing ErrorHandler and RetryHandler utilities
- **Logging**: Integrates with the existing Logger system

### Data Flow
1. User initiates `/course` command
2. Discord presents course autocomplete options (fetched from courses API)
3. User selects a course
4. Bot calls leaderboards API with selected course code
5. Service processes and formats leaderboard data
6. Bot displays formatted results in Discord embed

### Integration Points
- **Existing API**: Uses `/leaderboards/course/:code` endpoint
- **Bot Framework**: Integrates with DiscordTournamentBot class
- **Utilities**: Reuses ErrorHandler, RetryHandler, Logger, and DiscordRateLimitHandler
- **Configuration**: Extends existing config.js with leaderboards endpoint

## Components and Interfaces

### 1. Course Command (`/src/commands/course.js`)
```javascript
// Command definition with autocomplete
SlashCommandBuilder()
  .setName('course')
  .setDescription('Display leaderboard scores for a selected course')
  .addStringOption(option =>
    option.setName('course')
      .setDescription('Select a course to view leaderboard')
      .setRequired(true)
      .setAutocomplete(true)
  )
```

**Key Methods:**
- `execute(interaction)`: Main command handler
- `autocomplete(interaction)`: Provides course suggestions

### 2. CourseLeaderboardService (`/src/services/CourseLeaderboardService.js`)
Follows the pattern established by VotesService.

**Key Methods:**
- `getCourseLeaderboard(courseCode, userId)`: Fetch leaderboard data for specific course with user context
- `getAvailableCourses()`: Fetch course list for autocomplete
- `formatLeaderboardData(apiResponse, userId)`: Process raw API data and identify user scores by discord_id
- `createLeaderboardEmbed(leaderboardData, courseInfo)`: Generate Discord embed with user highlighting
- `createTextDisplay(leaderboardData, courseInfo)`: Fallback text format with user highlighting
- `handleApiError(error, context)`: Error processing with user-friendly messages
- `getAuthToken()`: Obtain and cache OAuth2 bearer token
- `refreshTokenIfNeeded()`: Refresh token when expired

### 3. API Integration
**Leaderboards Endpoint**: `https://apex.skillbuilders.com/ords/wmgt/leaderboards/course/:code?discord_id={user_id}`
- Returns: `{ items: [{ pos, discord_id, player_name, score, isApproved }], hasMore, limit, offset, count }`
- Pass requesting user's discord_id to identify their scores
- Includes pagination metadata and links
- Returns both approved and personal (unapproved) scores
- **Authentication Required**: Bearer token via OAuth2 client credentials flow

**Courses Endpoint**: `https://apex.skillbuilders.com/ords/wmgt/tournament/courses`
- Returns course list for autocomplete functionality
- Users expected to know 3-letter course codes
- **Authentication Required**: Bearer token via OAuth2 client credentials flow

**Authentication Flow**:
1. Obtain token: `POST /ords/wmgt/api/oauth/token` with client credentials
2. Use token: `Authorization: Bearer {token}` header on all API calls
3. Token expires in 3600 seconds (1 hour) - implement refresh logic
- Users can search by course full name
- The course mode is not important

## Data Models

### Leaderboard Entry
```javascript
{
  pos: number,            // Ranking position 
  discord_id: number,     // Discord user ID
  player_name: string,    // Player display name
  score: number,          // Course score (negative values indicate under par)
  isApproved: boolean     // Whether score is admin-approved (true) or personal (false)
}
```

Note: User identification is done by comparing `discord_id` with the requesting user's ID.

### Course Information
```javascript
{
  code: string,           // Course code (e.g., "ALE", "BBH")
  name: string,           // Full course name
  difficulty: string      // "Easy" or "Hard" (derived from code)
}
```

### Formatted Leaderboard Data
```javascript
{
  course: CourseInfo,
  entries: LeaderboardEntry[],
  totalEntries: number,
  lastUpdated: Date
}
```

## Error Handling

### Error Categories
1. **Course Not Found**: Invalid or non-existent course code
2. **No Scores Available**: Valid course but no recorded scores
3. **API Unavailable**: Leaderboards service down or unreachable
4. **Timeout Errors**: API response timeout
5. **Rate Limiting**: Too many requests to API
6. **Data Format Errors**: Invalid API response structure

### Error Response Strategy
- **User-Friendly Messages**: Clear, actionable error descriptions
- **Retry Logic**: Automatic retry for transient failures (3 attempts)
- **Fallback Options**: Suggest alternative courses when course not found
- **Graceful Degradation**: Text display when embed creation fails

### Error Message Examples
- "Course 'XYZ' not found. Try one of these popular courses: ALE, BBH, CLE"
- "No scores recorded for this course yet. Be the first to play!"
- "Leaderboard service temporarily unavailable. Please try again in a moment."

## Testing Strategy

### Unit Tests
- **CourseLeaderboardService**: API calls, data formatting, error handling
- **Command Logic**: Autocomplete functionality, parameter validation
- **Error Scenarios**: Various API failure modes and edge cases

### Integration Tests
- **API Integration**: Real API calls with test data
- **Discord Integration**: Command registration and execution
- **End-to-End Flow**: Complete user interaction simulation

### Test Data Requirements
- **Valid Courses**: Courses with existing leaderboard data
- **Empty Courses**: Valid courses with no scores
- **Invalid Courses**: Non-existent course codes
- **Edge Cases**: Courses with special characters, very long names

### Performance Tests
- **Response Time**: Command execution under 3 seconds
- **Concurrent Users**: Multiple simultaneous command executions
- **API Load**: Stress testing leaderboards endpoint
- **Memory Usage**: Service memory consumption monitoring

## User Experience Design

### Autocomplete Behavior
- **Course Code Matching**: Match against 3-letter course codes
- **Popular Courses First**: Prioritize frequently accessed courses
- **Simple Format**: Display course codes directly (users know the codes)
- **Limit Results**: Maximum 25 autocomplete suggestions

### Display Format
**Embed Structure:**
- **Title**: "🏆 [Course Name] Leaderboard"
- **Description**: Course code and difficulty
- **Fields**: Ranked list of top scores
- **Footer**: "Last updated" timestamp
- **Color**: Consistent with bot theme (0x00AE86)

**Score Display Format:**
```
1. 🥇 Outrider - (-22)
2. 🥈 leanin2it - (-21)  
3. � INDY - a(-21)
4. El Jorge - (-20)
...
```
**Display Indicators:**
- 🥇🥈🥉: Top 3 positions
- ➤: Current user's approved score (highlighted)
- 📝: Personal/unapproved scores
- ⭐ [YOU]: User's own score marker
- [PERSONAL]: Unapproved score indicator

Note: Negative scores indicate strokes under par, positive scores over par.

### Responsive Design
- **Mobile Optimization**: Readable on mobile Discord clients
- **Character Limits**: Respect Discord's embed field limits (1024 chars)
- **Truncation**: Graceful handling of long player names
- **Fallback Display**: Plain text when embeds fail

## Security Considerations

### Authentication & Authorization
- **OAuth2 Client Credentials**: Secure API access with bearer tokens
- **Token Management**: Secure storage and automatic refresh of access tokens
- **Client Secret Protection**: Store credentials in environment variables
- **Token Expiration**: Handle 401 responses and refresh tokens automatically

### Input Validation
- **Course Code Sanitization**: Prevent SQL injection via course parameter
- **Rate Limiting**: Prevent command spam and API abuse
- **User Permissions**: No special permissions required (public command)

### Data Privacy
- **Discord ID Handling**: Only display when user has opted in
- **Player Names**: Use tournament-registered names only
- **Score Visibility**: Show both approved and personal scores with clear indicators

### API Security
- **Parameter Binding**: Use parameterized queries in API
- **Input Sanitization**: Validate course codes against known values
- **Error Information**: Avoid exposing internal system details
- **Token Security**: Never log or expose bearer tokens in error messages
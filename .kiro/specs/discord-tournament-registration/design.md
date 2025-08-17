# Design Document

## Overview

The Discord Tournament Registration Bot will be a Node.js application using the Discord.js library to provide tournament registration functionality directly within Discord. The bot will integrate with the existing WMGT Oracle database through REST API endpoints, allowing players to register for tournament sessions, view available time slots with timezone conversion, and manage their registrations.

The system will leverage the existing tournament infrastructure including `wmg_tournaments`, `wmg_tournament_sessions`, and `wmg_tournament_players` tables, while adding new API endpoints specifically designed for Discord bot integration.

## Architecture

### High-Level Architecture

```mermaid
graph TB
    A[Discord Client] --> B[Discord Bot]
    B --> C[REST API Layer]
    C --> D[Oracle Database]
    
    subgraph "Discord Bot Components"
        B1[Command Handler]
        B2[Timezone Service]
        B3[Registration Service]
        B4[Error Handler]
    end
    
    subgraph "API Endpoints"
        C1[/api/tournaments/current]
        C2[/api/tournaments/register]
        C3[/api/tournaments/unregister]
        C4[/api/players/registrations]
    end
    
    subgraph "Database Tables"
        D1[wmg_tournaments]
        D2[wmg_tournament_sessions]
        D3[wmg_tournament_players]
        D4[wmg_players]
    end
    
    B --> B1
    B --> B2
    B --> B3
    B --> B4
    
    C --> C1
    C --> C2
    C --> C3
    C --> C4
    
    D --> D1
    D --> D2
    D --> D3
    D --> D4
```

### Technology Stack

- **Discord Bot**: Node.js with Discord.js v14
- **API Layer**: Oracle REST Data Services (ORDS) 
- **Database**: Oracle Database (existing WMGT schema)
- **Timezone Handling**: moment-timezone library
- **Configuration**: Environment variables and JSON config files

## Components and Interfaces

### Discord Bot Components

#### 1. Command Handler
Manages Discord slash commands and user interactions.

**Commands:**
- `/register` - Start tournament registration process
- `/unregister` - Remove registration from tournament
- `/mystatus` - View current registrations
- `/timezone` - Set or update user timezone preference

**Interfaces:**
```javascript
class CommandHandler {
  async handleRegister(interaction, userId, timezone)
  async handleUnregister(interaction, userId)
  async handleMyStatus(interaction, userId)
  async handleTimezone(interaction, userId, timezone)
}
```

#### 2. Timezone Service
Handles timezone conversion and validation.

**Interfaces:**
```javascript
class TimezoneService {
  convertUTCToLocal(utcTime, timezone)
  validateTimezone(timezone)
  formatTimeDisplay(utcTime, localTime, timezone)
  detectTimezoneFromLocation(location) // Optional enhancement
}
```

#### 3. Registration Service
Manages communication with backend APIs for registration operations.

**Interfaces:**
```javascript
class RegistrationService {
  async getCurrentTournament()
  async registerPlayer(discordUser, sessionId, timeSlot)
  async unregisterPlayer(discordUser, sessionId)
  async getPlayerRegistrations(playerId)
  async getPlayerByDiscordId(discordId)
}
```

### API Endpoints

#### 1. GET /api/tournaments/current
Returns current active tournament with available sessions, time slots, and course information.

**Response:**
```json
{
  "tournament": {
    "id": 123,
    "name": "Season 14 Tournament",
    "code": "S14"
  },
  "sessions": [
    {
      "id": 456,
      "week": "S14W01",
      "session_date": "2024-08-17T00:00:00Z",
      "open_registration_on": "2024-08-10T00:00:00Z",
      "close_registration_on": "2024-08-17T22:00:00Z",
      "registration_open": true,
      "available_time_slots": [
        "22:00", "00:00", "02:00", "04:00", "08:00", "12:00", "16:00", "18:00", "20:00"
      ],
      "courses": [
        {
          "course_no": 1,
          "course_name": "Atlantis",
          "course_code": "ATH",
          "difficulty": "Hard"
        },
        {
          "course_no": 2,
          "course_name": "Cherry Blossom",
          "course_code": "CBE",
          "difficulty": "Easy"
        }
      ]
    }
  ]
}
```

#### 2. POST /api/tournaments/register
Registers a player for a specific tournament session and time slot, including full Discord user data for synchronization.

**Request:**
```json
{
  "session_id": 456,
  "time_slot": "22:00",
  "discord_user": {
    "id": "864988785888329748",
    "username": "glitchingqueen",
    "global_name": "Jen",
    "avatar": "1eb556c0773045fef0d56292c151ab11",
    "accent_color": null,
    "banner": "a_75888fd5e40a99be49c208857b8a3994",
    "discriminator": "0",
    "avatar_decoration_data": null
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully registered for S14W01 at 22:00 UTC",
  "registration": {
    "session_id": 456,
    "week": "S14W01",
    "time_slot": "22:00",
    "room_no": null
  }
}
```

#### 3. POST /api/tournaments/unregister
Removes a player's registration from a tournament session.

**Request:**
```json
{
  "session_id": 456,
  "discord_user": {
    "id": "864988785888329748",
    "username": "glitchingqueen",
    "global_name": "Jen",
    "avatar": "1eb556c0773045fef0d56292c151ab11",
    "accent_color": null,
    "banner": "a_75888fd5e40a99be49c208857b8a3994",
    "discriminator": "0",
    "avatar_decoration_data": null
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully unregistered from S14W01"
}
```

#### 4. GET /api/players/registrations/:discord_id
Returns all active registrations for a player.

**Response:**
```json
{
  "player": {
    "id": 789,
    "name": "PlayerName",
    "discord_id": "123456789012345678"
  },
  "registrations": [
    {
      "session_id": 456,
      "week": "S14W01",
      "time_slot": "22:00",
      "session_date": "2024-08-17T00:00:00Z",
      "room_no": 5
    }
  ]
}
```

## Data Models

### Extended Player Model
The existing `wmg_players` table will be used with Discord ID linking:

```sql
-- Existing columns used:
-- id, player_name, discord_id, discord_avatar, active_ind
```

### Tournament Registration Model
Uses existing `wmg_tournament_players` table:

```sql
-- Key columns:
-- tournament_session_id, player_id, time_slot, room_no, active_ind
```

### User Preferences
Uses existing `wmg_players` table with potential enhancement for notification preferences:

```sql
-- Existing columns used:
-- id, player_name, discord_id, discord_avatar, prefered_tz, active_ind

-- Potential new column for Discord notifications:
-- notification_preferences VARCHAR2(100) -- JSON string for Discord notification settings
```

## Error Handling

### Bot Error Handling
- **Invalid Commands**: Respond with usage help and examples
- **API Failures**: Retry with exponential backoff, fallback to error message
- **Timezone Errors**: Prompt for valid timezone selection with examples
- **Registration Conflicts**: Display clear error message with alternatives

### API Error Responses
Standardized error format:
```json
{
  "success": false,
  "error_code": "REGISTRATION_CLOSED",
  "message": "Registration for this tournament session has closed",
  "details": {
    "session_id": 456,
    "close_time": "2024-08-17T22:00:00Z"
  }
}
```

### Error Categories
- `REGISTRATION_CLOSED`: Tournament registration period has ended
- `ALREADY_REGISTERED`: Player already registered for this session
- `INVALID_TIME_SLOT`: Selected time slot is not available
- `PLAYER_NOT_FOUND`: Discord user not linked to WMGT player account
- `SESSION_NOT_FOUND`: Tournament session does not exist
- `UNREGISTRATION_FAILED`: Cannot unregister (tournament started, etc.)

## Testing Strategy

### Unit Testing
- **Timezone Service**: Test conversion accuracy across all supported timezones
- **Registration Service**: Mock API responses and test error handling
- **Command Handler**: Test command parsing and response formatting

### Integration Testing
- **API Endpoints**: Test with real database using test data
- **Discord Bot**: Test commands in development Discord server
- **End-to-End**: Complete registration flow from Discord to database

### Test Data Setup
- Create test tournament sessions with various states (open, closed, completed)
- Test players with different timezone preferences
- Mock Discord interactions for automated testing

### Performance Testing
- **Concurrent Registrations**: Test multiple users registering simultaneously
- **API Response Times**: Ensure sub-second response for registration operations
- **Timezone Calculations**: Verify performance with large numbers of timezone conversions

### User Acceptance Testing
- **Timezone Display**: Verify accuracy across different user locations
- **Registration Flow**: Test complete user journey from command to confirmation
- **Error Scenarios**: Validate error messages are clear and actionable
- **Mobile Discord**: Test bot interactions on mobile Discord clients
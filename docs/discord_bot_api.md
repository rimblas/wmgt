# Discord Bot API Documentation

This document describes the REST API endpoints created for the Discord Tournament Registration Bot.

## Base URL

All endpoints are available under the base path: `/ords/wmgt/`

## Authentication

Currently, these endpoints do not require authentication. In a production environment, consider implementing proper authentication and rate limiting.

## Endpoints

### 1. Get Current Tournament

**Endpoint:** `GET /current_tournament`

**Description:** Returns the current active tournament with available sessions and courses.

**Response Format:**
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
      "registration_open": "true",
      "available_time_slots": [
        {
          "time_slot": "22:00",
          "day_offset": -1,
          "display": "22:00 -1"
        },
        {
          "time_slot": "00:00",
          "day_offset": 0,
          "display": "00:00"
        },
        {
          "time_slot": "02:00",
          "day_offset": 0,
          "display": "02:00"
        }
      ],
      "courses": [
        {
          "course_no": 1,
          "course_name": "Atlantis",
          "course_code": "ATH",
          "difficulty": "Easy"
        },
        {
          "course_no": 2,
          "course_name": "Cherry Blossom",
          "course_code": "CBE",
          "difficulty": "Hard"
        }
      ]
    }
  ]
}
```

**Example Request:**
```bash
curl -X GET "http://your-server/ords/wmgt/tournament/current_tournament"
```

### 2. Register Player

**Endpoint:** `POST /register`

**Description:** Registers a Discord user for a specific tournament session and time slot.

**Request Format:**
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

**Success Response:**
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

**Error Response:**
```json
{
  "success": false,
  "error_code": "REGISTRATION_CLOSED",
  "message": "Registration for this tournament session has closed"
}
```

**Error Codes:**
- `REGISTRATION_CLOSED`: Tournament registration period has ended
- `ALREADY_REGISTERED`: Player already registered for this session
- `INVALID_TIME_SLOT`: Selected time slot is not available
- `SESSION_NOT_FOUND`: Tournament session does not exist
- `REGISTRATION_FAILED`: General registration failure

**Example Request:**
```bash
curl -X POST "http://your-server/ords/wmgt/tournament/register" \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

### 3. Unregister Player

**Endpoint:** `POST /unregister`

**Description:** Removes a player's registration from a tournament session.

**Request Format:**
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

**Success Response:**
```json
{
  "success": true,
  "message": "Successfully unregistered from S14W01"
}
```

**Error Response:**
```json
{
  "success": false,
  "error_code": "UNREGISTRATION_FAILED",
  "message": "Cannot unregister after tournament has started"
}
```

**Error Codes:**
- `UNREGISTRATION_FAILED`: Cannot unregister (tournament started, etc.)
- `NOT_REGISTERED`: Player is not registered for this session
- `SESSION_NOT_FOUND`: Tournament session does not exist

**Example Request:**
```bash
curl -X POST "http://your-server/ords/wmgt/tournament/unregister" \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

### 4. Get Player Registrations

**Endpoint:** `GET /players/registrations/{discord_id}`

**Description:** Returns all active registrations for a player by Discord ID.

**Parameters:**
- `discord_id` (path parameter): The Discord user ID

**Response Format:**
```json
{
  "player": {
    "id": 789,
    "name": "PlayerName",
    "discord_id": "864988785888329748"
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

**Error Response:**
```json
{
  "success": false,
  "error_code": "PLAYER_NOT_FOUND",
  "message": "Discord user not linked to WMGT player account"
}
```

**Example Request:**
```bash
curl -X GET "http://your-server/ords/wmgt/players/registrations/864988785888329748"
```

## Time Slots

Time slots are dynamically retrieved from the `wmg_time_slots_all_v` view and include day offsets:

- **time_slot**: The time in HH:MM format (e.g., "22:00", "00:00")
- **day_offset**: Day offset relative to tournament date (-1 for previous day, 0 for same day)
- **display**: Human-readable format showing time and day offset (e.g., "22:00 -1" for 10 PM the day before)

Example time slots:
- `22:00` with day_offset `-1` (10:00 PM the day before tournament)
- `00:00` with day_offset `0` (12:00 AM on tournament day)
- `02:00` with day_offset `0` (2:00 AM on tournament day)
- `04:00` with day_offset `0` (4:00 AM on tournament day)
- `08:00` with day_offset `0` (8:00 AM on tournament day)
- `12:00` with day_offset `0` (12:00 PM on tournament day)
- `16:00` with day_offset `0` (4:00 PM on tournament day)
- `18:00` with day_offset `0` (6:00 PM on tournament day)
- `20:00` with day_offset `0` (8:00 PM on tournament day)

## Discord User Object

The Discord user object should contain the following fields from the Discord API:

- `id`: Discord user ID (string)
- `username`: Discord username (string)
- `global_name`: Discord display name (string, nullable)
- `avatar`: Avatar hash (string, nullable)
- `accent_color`: Accent color (number, nullable)
- `banner`: Banner hash (string, nullable)
- `discriminator`: Legacy discriminator (string)
- `avatar_decoration_data`: Avatar decoration (string, nullable)

## Integration with Existing System

These endpoints integrate with the existing WMGT system:

1. **Player Synchronization**: Uses the existing `t_discord_user` package to synchronize Discord user data with the `wmg_players` table.

2. **Tournament Management**: Leverages existing tournament tables (`wmg_tournaments`, `wmg_tournament_sessions`, `wmg_tournament_players`).

3. **Logging**: Uses the existing logger package for debugging and monitoring.

## Installation

1. Run the installation script:
   ```sql
   @ords/install_discord_api.sql
   ```

2. Test the endpoints:
   ```sql
   @ords/test_discord_api.sql
   ```

## Security Considerations

For production deployment, consider implementing:

1. **Authentication**: Add proper API authentication
2. **Rate Limiting**: Prevent abuse of registration endpoints
3. **Input Validation**: Additional validation of Discord user data
4. **CORS**: Configure appropriate CORS headers
5. **HTTPS**: Ensure all API calls use HTTPS
6. **Monitoring**: Set up monitoring and alerting for API usage

## Troubleshooting

### Common Issues

1. **Player Not Found**: Ensure the Discord user has been properly synchronized with the WMGT system
2. **Registration Closed**: Check that the current timestamp is within the registration window
3. **Invalid Time Slot**: Verify the time slot is one of the allowed values
4. **Database Errors**: Check the logger output for detailed error information

### Debugging

Enable detailed logging by checking the logger output with scope `REST:api/*` to see detailed execution information for each endpoint.
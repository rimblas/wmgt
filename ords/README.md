# ORDS REST API Endpoints

This directory contains Oracle REST Data Services (ORDS) endpoint definitions for the WMGT system.

## Files

- `tournament.sql` - Existing tournament API endpoints for rounds and season data
- `discord_bot_api.sql` - New Discord Bot API endpoints for tournament registration
- `install_discord_api.sql` - Installation script for Discord Bot API
- `test_discord_api.sql` - Test script to validate Discord Bot API functionality

## Installation

### Discord Bot API

To install the Discord Bot API endpoints:

1. Connect to your Oracle database as the WMGT schema owner
2. Run the installation script:
   ```sql
   @install_discord_api.sql
   ```

### Testing

To test the Discord Bot API endpoints:

1. Run the test script:
   ```sql
   @test_discord_api.sql
   ```

2. Test the actual REST endpoints using curl or a REST client:
   ```bash
   # Get current tournament
   curl -X GET "http://your-server/ords/wmgt/api/tournaments/current"
   
   # Get player registrations
   curl -X GET "http://your-server/ords/wmgt/api/players/registrations/123456789"
   ```

## API Documentation

See `../docs/discord_bot_api.md` for complete API documentation including:
- Endpoint specifications
- Request/response formats
- Error codes
- Example usage

## Dependencies

The Discord Bot API endpoints require:
- Oracle Database with ORDS enabled
- WMGT schema with existing tables and packages
- `t_discord_user` package for Discord user synchronization
- Logger package for debugging and monitoring

## Security

These endpoints are currently configured without authentication. For production use, consider implementing:
- API authentication
- Rate limiting
- Input validation
- CORS configuration
- HTTPS enforcement
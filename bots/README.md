# Discord Tournament Registration Bot

A Discord bot for WMGT tournament registration that allows players to register for tournaments directly through Discord with timezone-aware time slot selection.

## Features

- Tournament registration through Discord slash commands
- Timezone-aware time slot display
- Registration status management
- Integration with existing WMGT backend APIs

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Copy environment configuration:
   ```bash
   cp .env.example .env
   ```

3. Configure your Discord bot token and API endpoints in `.env`

4. Start the bot:
   ```bash
   npm start
   ```

## Development

- `npm run dev` - Start with file watching for development
- `npm test` - Run tests

## Commands

- `/register` - Register for a tournament session
- `/unregister` - Unregister from a tournament session  
- `/mystatus` - View current registrations
- `/votes` - View current votes on courses
- `/timezone` - Set preferred timezone

## Project Structure

```
src/
├── commands/          # Discord slash commands
├── services/          # Business logic services
├── config/           # Configuration management
└── index.js          # Main bot entry point
```

## Requirements

- Node.js 18.0.0 or higher
- Discord bot token
- Access to WMGT backend APIs

## NAS Install

### Log Cleanup

Setup logrotate `/etc/logrotate.d/discordbot`

```
/root/.forever/*.log
/volume1/repos/wmgt/bots/logs/log.txt
/volume1/repos/wmgt/bots/logs/output.txt
/volume1/repos/wmgt/bots/logs/bot.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
```

# Discord Tournament Registration Bot

A Discord bot for WMGT tournament registration that allows players to register for tournaments directly through Discord with timezone-aware time slot selection.

## Features

- Tournament registration through Discord slash commands
- Timezone-aware time slot display
- Real-time tournament leaderboard showing top 5 current leaders
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

- `/register` - Register for a tournament session or change time slots
- `/unregister` - Unregister from a tournament session  
- `/mystatus` - View your current registration and room assignment
- `/votes` - View current votes on courses
- `/course` - View current high scores on a course
- `/timezone` - Set preferred timezone

## Tournament Leaderboard

When a tournament is in progress, the registration message automatically displays a real-time leaderboard showing the top 5 current leaders.

### How It Works

- **When it appears**: The leaderboard is displayed only when the tournament state is "ongoing" and players have submitted scores
- **What it shows**: Position, player name, and total score for the top 5 players
- **Update frequency**: The leaderboard updates automatically every 60 seconds during the tournament's active window
- **Data source**: Rankings are calculated from the `wmg_tournament_session_points_v` database view, which aggregates scores across all tournament courses

### Example Display

```
🏆 Current Leaders
1. player1 (-39)
2. player2 (-35)
3. player3 (-32)
4. player4 (-30)
5. player5 (-28)
```

### Notes

- Scores are displayed as under-par (negative) or over-par (positive) values
- The leaderboard only appears during ongoing tournaments - it is not shown when registration is open or after the tournament closes
- If no scores have been submitted yet, the leaderboard field will not be displayed
- In case of tied scores, all players with the same position may be shown (potentially more than 5 players)

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

## Changelog

### 2025-01-27 - Tournament Leaderboard Feature
- Added real-time tournament leaderboard display to registration messages
- Leaderboard shows top 5 current leaders during ongoing tournaments
- Updates automatically every 60 seconds with latest scores
- Displays position, player name, and total score for each leader
- Gracefully handles tournaments with no submitted scores

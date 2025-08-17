// Configuration management
import dotenv from 'dotenv';

dotenv.config();

export const config = {
  discord: {
    token: process.env.DISCORD_BOT_TOKEN,
    clientId: process.env.DISCORD_CLIENT_ID,
    guildId: process.env.DISCORD_GUILD_ID // Optional: for guild-specific commands
  },
  api: {
    baseUrl: process.env.API_BASE_URL || 'http://localhost:8080',
    endpoints: {
      currentTournament: '/api/tournaments/current',
      register: '/api/tournaments/register',
      unregister: '/api/tournaments/unregister',
      playerRegistrations: '/api/players/registrations',
      setTimezone: '/api/players/timezone'
    }
  },
  bot: {
    name: 'WMGT Tournament Bot',
    version: '1.0.0'
  }
};
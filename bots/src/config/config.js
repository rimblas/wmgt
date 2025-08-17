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
    },
    timeout: parseInt(process.env.API_TIMEOUT) || 15000,
    retries: parseInt(process.env.API_RETRIES) || 3
  },
  bot: {
    name: 'WMGT Tournament Bot',
    version: '1.0.0'
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || './logs/bot.log',
    console: process.env.LOG_CONSOLE !== 'false',
    maxFileSize: parseInt(process.env.LOG_MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB
    maxFiles: parseInt(process.env.LOG_MAX_FILES) || 5
  },
  errorHandling: {
    interactionTimeout: parseInt(process.env.INTERACTION_TIMEOUT) || 15000,
    retryBaseDelay: parseInt(process.env.RETRY_BASE_DELAY) || 1000,
    retryMaxDelay: parseInt(process.env.RETRY_MAX_DELAY) || 30000,
    circuitBreakerThreshold: parseInt(process.env.CIRCUIT_BREAKER_THRESHOLD) || 5,
    circuitBreakerTimeout: parseInt(process.env.CIRCUIT_BREAKER_TIMEOUT) || 60000
  }
};
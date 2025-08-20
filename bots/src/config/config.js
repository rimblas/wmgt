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
      currentTournament: '/tournament/current_tournament',
      register: '/tournament/register',
      unregister: '/tournament/unregister',
      playerRegistrations: '/tournament/players/registrations',
      setTimezone: '/tournament/players/timezone',
      votes: '/tournament/votes'
    },
    timeout: parseInt(process.env.API_TIMEOUT) || 15000,
    retries: parseInt(process.env.API_RETRIES) || 3,
    maxConcurrentRequests: parseInt(process.env.MAX_CONCURRENT_REQUESTS) || 10
  },
  bot: {
    name: 'WMGT Tournament Bot',
    version: '1.0.0',
    tournament: 'WMGT'
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
  },
  healthCheck: {
    enabled: process.env.HEALTH_CHECK_ENABLED === 'true',
    port: parseInt(process.env.HEALTH_CHECK_PORT) || 3000,
    path: process.env.HEALTH_CHECK_PATH || '/health'
  },
  security: {
    rateLimitWindow: parseInt(process.env.RATE_LIMIT_WINDOW) || 60000,
    rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
  },
  monitoring: {
    sentryDsn: process.env.SENTRY_DSN,
    datadogApiKey: process.env.DATADOG_API_KEY,
    newRelicLicenseKey: process.env.NEW_RELIC_LICENSE_KEY
  },
  database: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT) || 1521,
    serviceName: process.env.DB_SERVICE_NAME,
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD
  }
};
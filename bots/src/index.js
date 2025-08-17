import { Client, GatewayIntentBits, Collection, REST, Routes } from 'discord.js';
import { config } from './config/config.js';
import { logger } from './utils/Logger.js';
import { ErrorHandler } from './utils/ErrorHandler.js';
import { DiscordRateLimitHandler } from './utils/DiscordRateLimitHandler.js';
import registerCommand from './commands/register.js';
import unregisterCommand from './commands/unregister.js';
import mystatusCommand from './commands/mystatus.js';
import timezoneCommand from './commands/timezone.js';

export class DiscordTournamentBot {
  constructor() {
    // Initialize logging and error handling
    this.logger = logger.child({ component: 'DiscordTournamentBot' });
    this.errorHandler = new ErrorHandler(this.logger);
    this.rateLimitHandler = new DiscordRateLimitHandler(this.logger);

    // Initialize Discord client with required intents
    this.client = new Client({
      intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages
      ],
      // Add retry configuration for Discord API
      retryLimit: 3,
      restTimeOffset: 0,
      restRequestTimeout: 15000
    });

    // Collection to store commands
    this.client.commands = new Collection();
    
    // Track interaction timeouts
    this.activeInteractions = new Map();
    
    // Load commands
    this.loadCommands();
    
    // Set up event handlers
    this.setupEventHandlers();
  }

  loadCommands() {
    const commands = [
      registerCommand,
      unregisterCommand,
      mystatusCommand,
      timezoneCommand
    ];

    for (const command of commands) {
      this.client.commands.set(command.data.name, command);
    }
  }

  setupEventHandlers() {
    // Bot ready event
    this.client.once('ready', () => {
      this.logger.info(`${config.bot.name} v${config.bot.version} is online!`, {
        guilds: this.client.guilds.cache.size,
        users: this.client.users.cache.size,
        uptime: process.uptime()
      });
    });

    // Handle slash command interactions
    this.client.on('interactionCreate', async (interaction) => {
      if (!interaction.isChatInputCommand()) return;

      const command = this.client.commands.get(interaction.commandName);

      if (!command) {
        this.logger.error(`No command matching ${interaction.commandName} was found`, {
          commandName: interaction.commandName,
          userId: interaction.user.id,
          guildId: interaction.guildId
        });
        return;
      }

      // Track interaction for timeout handling
      const interactionId = `${interaction.id}_${Date.now()}`;
      this.activeInteractions.set(interactionId, {
        commandName: interaction.commandName,
        userId: interaction.user.id,
        startTime: Date.now()
      });

      // Set up interaction timeout
      const timeoutId = setTimeout(() => {
        if (this.activeInteractions.has(interactionId)) {
          this.logger.interactionTimeout(interaction.commandName, interaction.user.id, {
            interactionId,
            duration: Date.now() - this.activeInteractions.get(interactionId).startTime
          });
          this.activeInteractions.delete(interactionId);
        }
      }, 15000); // 15 second timeout

      try {
        // Log command execution
        this.logger.commandExecution(
          interaction.commandName,
          interaction.user.id,
          interaction.guildId,
          {
            interactionId,
            options: interaction.options.data
          }
        );

        // Execute command with rate limiting
        await this.rateLimitHandler.executeRequest(
          () => command.execute(interaction),
          `command_${interaction.commandName}`,
          { interactionId }
        );

        // Clear timeout on successful completion
        clearTimeout(timeoutId);
        this.activeInteractions.delete(interactionId);

      } catch (error) {
        // Clear timeout on error
        clearTimeout(timeoutId);
        this.activeInteractions.delete(interactionId);

        // Handle the error using our error handler
        await this.errorHandler.handleInteractionError(
          error,
          interaction,
          `command_${interaction.commandName}`
        );
      }
    });

    // Handle component interactions (buttons, select menus)
    this.client.on('interactionCreate', async (interaction) => {
      if (!interaction.isMessageComponent()) return;

      try {
        // Component interactions are handled by the commands themselves
        // This is just for logging and error handling
        this.logger.debug('Component interaction received', {
          customId: interaction.customId,
          userId: interaction.user.id,
          componentType: interaction.componentType
        });

      } catch (error) {
        await this.errorHandler.handleInteractionError(
          error,
          interaction,
          'component_interaction'
        );
      }
    });

    // Discord client error handling
    this.client.on('error', (error) => {
      this.logger.error('Discord client error', {
        error: error.message,
        stack: error.stack,
        code: error.code
      });
    });

    this.client.on('warn', (warning) => {
      this.logger.warn('Discord client warning', { warning });
    });

    // Rate limit handling
    this.client.on('rateLimit', (rateLimitData) => {
      this.logger.warn('Discord API rate limit hit', {
        timeout: rateLimitData.timeout,
        limit: rateLimitData.limit,
        method: rateLimitData.method,
        path: rateLimitData.path,
        route: rateLimitData.route
      });
    });

    // Shard events (for future scaling)
    this.client.on('shardError', (error, shardId) => {
      this.logger.error('Shard error', {
        shardId,
        error: error.message,
        stack: error.stack
      });
    });

    this.client.on('shardReady', (shardId) => {
      this.logger.info('Shard ready', { shardId });
    });

    this.client.on('shardDisconnect', (event, shardId) => {
      this.logger.warn('Shard disconnected', {
        shardId,
        code: event.code,
        reason: event.reason
      });
    });

    this.client.on('shardReconnecting', (shardId) => {
      this.logger.info('Shard reconnecting', { shardId });
    });
  }

  async registerSlashCommands() {
    const commands = [];
    
    // Collect command data for registration
    for (const command of this.client.commands.values()) {
      commands.push(command.data.toJSON());
    }

    const rest = new REST().setToken(config.discord.token);

    try {
      this.logger.info(`Started refreshing ${commands.length} application (/) commands`, {
        commandCount: commands.length,
        guildSpecific: !!config.discord.guildId
      });

      let data;
      if (config.discord.guildId) {
        // Register commands for specific guild (faster for development)
        data = await this.rateLimitHandler.executeRequest(
          () => rest.put(
            Routes.applicationGuildCommands(config.discord.clientId, config.discord.guildId),
            { body: commands }
          ),
          'command_registration'
        );
      } else {
        // Register commands globally (takes up to 1 hour to propagate)
        data = await this.rateLimitHandler.executeRequest(
          () => rest.put(
            Routes.applicationCommands(config.discord.clientId),
            { body: commands }
          ),
          'command_registration'
        );
      }

      this.logger.info(`Successfully reloaded ${data.length} application (/) commands`, {
        registeredCount: data.length,
        guildId: config.discord.guildId || 'global'
      });

    } catch (error) {
      this.logger.error('Error registering slash commands', {
        error: error.message,
        stack: error.stack,
        commandCount: commands.length
      });
      throw error;
    }
  }

  async start() {
    try {
      // Validate required configuration
      if (!config.discord.token) {
        throw new Error('DISCORD_BOT_TOKEN is required in environment variables');
      }
      if (!config.discord.clientId) {
        throw new Error('DISCORD_CLIENT_ID is required in environment variables');
      }

      this.logger.info('Starting Discord Tournament Bot', {
        version: config.bot.version,
        nodeVersion: process.version,
        environment: process.env.NODE_ENV || 'development'
      });
      
      // Register slash commands
      await this.registerSlashCommands();
      
      // Login to Discord with rate limiting
      await this.rateLimitHandler.executeRequest(
        () => this.client.login(config.discord.token),
        'bot_login'
      );
      
    } catch (error) {
      this.logger.error('Failed to start bot', {
        error: error.message,
        stack: error.stack
      });
      process.exit(1);
    }
  }

  async stop() {
    this.logger.info('Shutting down Discord Tournament Bot', {
      uptime: process.uptime(),
      activeInteractions: this.activeInteractions.size,
      rateLimitStatus: this.rateLimitHandler.getStatus()
    });

    // Clear any active interaction timeouts
    this.activeInteractions.clear();

    // Clear rate limit handler
    this.rateLimitHandler.clearRateLimits();

    // Destroy Discord client
    this.client.destroy();
  }

  /**
   * Get bot health status
   * @returns {Object} Health status information
   */
  getHealthStatus() {
    return {
      status: this.client.readyAt ? 'online' : 'offline',
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      guilds: this.client.guilds.cache.size,
      users: this.client.users.cache.size,
      activeInteractions: this.activeInteractions.size,
      rateLimitStatus: this.rateLimitHandler.getStatus(),
      lastReady: this.client.readyAt?.toISOString()
    };
  }
}

// Only start the bot if this file is run directly (not imported)
if (import.meta.url === `file://${process.argv[1]}`) {
  // Create and start the bot
  const bot = new DiscordTournamentBot();

  // Graceful shutdown handling
  process.on('SIGINT', async () => {
    logger.info('Received SIGINT, shutting down gracefully');
    await bot.stop();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    logger.info('Received SIGTERM, shutting down gracefully');
    await bot.stop();
    process.exit(0);
  });

  // Handle uncaught exceptions
  process.on('uncaughtException', (error) => {
    logger.error('Uncaught exception', {
      error: error.message,
      stack: error.stack
    });
    process.exit(1);
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled promise rejection', {
      reason: reason?.message || reason,
      stack: reason?.stack,
      promise: promise.toString()
    });
  });

  // Log process warnings
  process.on('warning', (warning) => {
    logger.warn('Process warning', {
      name: warning.name,
      message: warning.message,
      stack: warning.stack
    });
  });

  // Start the bot
  bot.start().catch((error) => {
    logger.error('Failed to start bot', {
      error: error.message,
      stack: error.stack
    });
    process.exit(1);
  });
}
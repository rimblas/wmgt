import { Client, GatewayIntentBits, Collection, REST, Routes } from 'discord.js';
import { config } from './config/config.js';
import registerCommand from './commands/register.js';
import unregisterCommand from './commands/unregister.js';
import mystatusCommand from './commands/mystatus.js';
import timezoneCommand from './commands/timezone.js';

export class DiscordTournamentBot {
  constructor() {
    // Initialize Discord client with required intents
    this.client = new Client({
      intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages
      ]
    });

    // Collection to store commands
    this.client.commands = new Collection();
    
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
      console.log(`✅ ${config.bot.name} v${config.bot.version} is online!`);
      console.log(`📊 Serving ${this.client.guilds.cache.size} guilds`);
    });

    // Handle slash command interactions
    this.client.on('interactionCreate', async (interaction) => {
      if (!interaction.isChatInputCommand()) return;

      const command = this.client.commands.get(interaction.commandName);

      if (!command) {
        console.error(`❌ No command matching ${interaction.commandName} was found.`);
        return;
      }

      try {
        await command.execute(interaction);
      } catch (error) {
        console.error(`❌ Error executing ${interaction.commandName}:`, error);
        
        const errorMessage = {
          content: '❌ There was an error while executing this command!',
          ephemeral: true
        };

        if (interaction.replied || interaction.deferred) {
          await interaction.followUp(errorMessage);
        } else {
          await interaction.reply(errorMessage);
        }
      }
    });

    // Error handling
    this.client.on('error', (error) => {
      console.error('❌ Discord client error:', error);
    });

    this.client.on('warn', (warning) => {
      console.warn('⚠️ Discord client warning:', warning);
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
      console.log(`🔄 Started refreshing ${commands.length} application (/) commands.`);

      let data;
      if (config.discord.guildId) {
        // Register commands for specific guild (faster for development)
        data = await rest.put(
          Routes.applicationGuildCommands(config.discord.clientId, config.discord.guildId),
          { body: commands }
        );
      } else {
        // Register commands globally (takes up to 1 hour to propagate)
        data = await rest.put(
          Routes.applicationCommands(config.discord.clientId),
          { body: commands }
        );
      }

      console.log(`✅ Successfully reloaded ${data.length} application (/) commands.`);
    } catch (error) {
      console.error('❌ Error registering slash commands:', error);
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

      console.log('🚀 Starting Discord Tournament Bot...');
      
      // Register slash commands
      await this.registerSlashCommands();
      
      // Login to Discord
      await this.client.login(config.discord.token);
      
    } catch (error) {
      console.error('❌ Failed to start bot:', error);
      process.exit(1);
    }
  }

  async stop() {
    console.log('🛑 Shutting down Discord Tournament Bot...');
    this.client.destroy();
  }
}

// Only start the bot if this file is run directly (not imported)
if (import.meta.url === `file://${process.argv[1]}`) {
  // Create and start the bot
  const bot = new DiscordTournamentBot();

  // Graceful shutdown handling
  process.on('SIGINT', async () => {
    await bot.stop();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    await bot.stop();
    process.exit(0);
  });

  // Start the bot
  bot.start().catch(console.error);
}
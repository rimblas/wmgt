import { EmbedBuilder } from 'discord.js';

/**
 * Comprehensive error handling utility for the Discord Tournament Bot
 * Provides standardized error handling, user-friendly messages, and retry logic
 */
export class ErrorHandler {
  constructor(logger) {
    this.logger = logger;
    
    // Error type mappings for user-friendly messages
    this.errorMessages = {
      // API Errors
      'REGISTRATION_CLOSED': {
        title: '🔒 Registration Closed',
        message: 'Registration for this tournament session has closed.',
        color: 0xFFA500,
        suggestion: 'Check back later for new tournament sessions.'
      },
      'ALREADY_REGISTERED': {
        title: '⚠️ Already Registered',
        message: 'You are already registered for this tournament session.',
        color: 0xFFA500,
        suggestion: 'Use /mystatus to view your registrations or /unregister to cancel.'
      },
      'INVALID_TIME_SLOT': {
        title: '❌ Invalid Time Slot',
        message: 'The selected time slot is not available.',
        color: 0xFF0000,
        suggestion: 'Please select a different time slot.'
      },
      'PLAYER_NOT_FOUND': {
        title: '👤 Player Not Found',
        message: 'Your Discord account is not linked to a tournament player account.',
        color: 0xFF0000,
        suggestion: 'Please contact support to link your account.'
      },
      'SESSION_NOT_FOUND': {
        title: '📅 Session Not Found',
        message: 'The tournament session could not be found.',
        color: 0xFF0000,
        suggestion: 'The session may have been cancelled or completed.'
      },
      'UNREGISTRATION_FAILED': {
        title: '❌ Cannot Unregister',
        message: 'Cannot unregister from this tournament session.',
        color: 0xFF0000,
        suggestion: 'The tournament may have already started or registration is locked.'
      },
      
      // Network/Service Errors
      'SERVICE_UNAVAILABLE': {
        title: '🔧 Service Unavailable',
        message: 'The tournament service is temporarily unavailable.',
        color: 0xFF6B6B,
        suggestion: 'Please try again in a few minutes.'
      },
      'CONNECTION_ERROR': {
        title: '🌐 Connection Error',
        message: 'Unable to connect to the tournament service.',
        color: 0xFF6B6B,
        suggestion: 'Please check your connection and try again.'
      },
      'TIMEOUT_ERROR': {
        title: '⏰ Request Timeout',
        message: 'The request took too long to complete.',
        color: 0xFF6B6B,
        suggestion: 'Please try again. If the problem persists, contact support.'
      },
      'RATE_LIMITED': {
        title: '🚦 Rate Limited',
        message: 'Too many requests. Please slow down.',
        color: 0xFFA500,
        suggestion: 'Wait a moment before trying again.'
      },
      
      // Discord Errors
      'INTERACTION_TIMEOUT': {
        title: '⏰ Interaction Timeout',
        message: 'The interaction timed out.',
        color: 0x808080,
        suggestion: 'Please run the command again.'
      },
      'DISCORD_API_ERROR': {
        title: '🤖 Discord API Error',
        message: 'An error occurred with Discord\'s API.',
        color: 0xFF6B6B,
        suggestion: 'Please try again. If the problem persists, contact support.'
      },
      
      // Validation Errors
      'INVALID_TIMEZONE': {
        title: '🌍 Invalid Timezone',
        message: 'The provided timezone is not valid.',
        color: 0xFF0000,
        suggestion: 'Please use a valid IANA timezone name (e.g., America/New_York).'
      },
      'INVALID_INPUT': {
        title: '❌ Invalid Input',
        message: 'The provided input is not valid.',
        color: 0xFF0000,
        suggestion: 'Please check your input and try again.'
      },
      
      // Votes API Specific Errors
      'VOTES_API_UNAVAILABLE': {
        title: '📊 Voting Service Unavailable',
        message: 'The voting service is temporarily unavailable.',
        color: 0xFF6B6B,
        suggestion: 'Please try again in a few minutes. If the problem persists, contact support.'
      },
      'VOTES_DATA_INVALID': {
        title: '📊 Invalid Voting Data',
        message: 'The voting data received is in an unexpected format.',
        color: 0xFF0000,
        suggestion: 'This may be a temporary issue. Please try again later.'
      },
      'VOTES_NO_DATA': {
        title: '📊 No Voting Data',
        message: 'No voting data is currently available.',
        color: 0xFFA500,
        suggestion: 'Voting may not have started yet or no courses are available for voting.'
      },
      'VOTES_PROCESSING_ERROR': {
        title: '📊 Data Processing Error',
        message: 'Unable to process the voting data for display.',
        color: 0xFF0000,
        suggestion: 'The data may be corrupted or in an unexpected format. Please try again later.'
      },
      'EMBED_CREATION_FAILED': {
        title: '🤖 Display Error',
        message: 'Unable to create the voting results display.',
        color: 0xFF6B6B,
        suggestion: 'This may be due to Discord limitations. Trying text-based display...'
      },
      'EMBED_PERMISSION_ERROR': {
        title: '🔒 Permission Error',
        message: 'The bot lacks permission to send embedded messages.',
        color: 0xFFA500,
        suggestion: 'Using text-based display instead. Contact an admin to grant embed permissions.'
      },

      // Generic Errors
      'UNKNOWN_ERROR': {
        title: '❌ Unexpected Error',
        message: 'An unexpected error occurred.',
        color: 0xFF0000,
        suggestion: 'Please try again later or contact support.'
      }
    };
  }

  /**
   * Handle and classify errors, returning appropriate user messages
   * @param {Error} error - The error to handle
   * @param {string} context - Context where the error occurred (e.g., 'registration', 'api_call')
   * @param {Object} metadata - Additional metadata about the error
   * @returns {Object} Error response object with embed and logging info
   */
  handleError(error, context = 'unknown', metadata = {}) {
    const errorId = this.generateErrorId();
    const timestamp = new Date().toISOString();
    
    // Log the error with full details
    this.logger.error('Error occurred', {
      errorId,
      context,
      message: error.message,
      stack: error.stack,
      metadata,
      timestamp
    });

    // Classify the error
    const errorType = this.classifyError(error);
    const errorConfig = this.errorMessages[errorType] || this.errorMessages.UNKNOWN_ERROR;

    // Create user-friendly embed
    const embed = new EmbedBuilder()
      .setColor(errorConfig.color)
      .setTitle(errorConfig.title)
      .setDescription(errorConfig.message)
      .setFooter({ 
        text: `${errorConfig.suggestion} | Error ID: ${errorId}`,
        iconURL: null
      })
      .setTimestamp();

    // Add additional context if available
    if (metadata.details) {
      embed.addFields({
        name: 'Details',
        value: metadata.details,
        inline: false
      });
    }

    return {
      embed,
      errorId,
      errorType,
      shouldRetry: this.shouldRetryError(error),
      retryAfter: this.getRetryDelay(error)
    };
  }

  /**
   * Classify error based on type and message content
   * @param {Error} error - The error to classify
   * @returns {string} Error type key
   */
  classifyError(error) {
    // Check for specific error codes first
    if (error.code) {
      switch (error.code) {
        case 'ECONNREFUSED':
        case 'ENOTFOUND':
        case 'ECONNRESET':
          return 'CONNECTION_ERROR';
        case 'ETIMEDOUT':
          return 'TIMEOUT_ERROR';
        default:
          break;
      }
    }

    // Check for HTTP status codes
    if (error.response?.status) {
      const status = error.response.status;
      if (status === 429) return 'RATE_LIMITED';
      if (status >= 500) return 'SERVICE_UNAVAILABLE';
      if (status === 404) return 'SESSION_NOT_FOUND';
    }

    // Check for API error codes
    if (error.response?.data?.error_code) {
      const apiErrorCode = error.response.data.error_code;
      if (this.errorMessages[apiErrorCode]) {
        return apiErrorCode;
      }
    }

    // Check error message content
    const message = error.message?.toLowerCase() || '';
    
    // Votes API specific errors
    if (message.includes('voting data') && message.includes('invalid')) {
      return 'VOTES_DATA_INVALID';
    }
    if (message.includes('no voting data') || message.includes('voting data') && message.includes('empty')) {
      return 'VOTES_NO_DATA';
    }
    if (message.includes('voting') && (message.includes('process') || message.includes('format'))) {
      return 'VOTES_PROCESSING_ERROR';
    }
    if (message.includes('voting') && message.includes('unavailable')) {
      return 'VOTES_API_UNAVAILABLE';
    }
    if (message.includes('embed') && (message.includes('permission') || message.includes('forbidden'))) {
      return 'EMBED_PERMISSION_ERROR';
    }
    if (message.includes('embed') && message.includes('failed')) {
      return 'EMBED_CREATION_FAILED';
    }
    
    // Existing error classifications
    if (message.includes('registration') && message.includes('closed')) {
      return 'REGISTRATION_CLOSED';
    }
    if (message.includes('already registered')) {
      return 'ALREADY_REGISTERED';
    }
    if (message.includes('timezone') && message.includes('invalid')) {
      return 'INVALID_TIMEZONE';
    }
    if (message.includes('timeout') || message.includes('timed out')) {
      return 'INTERACTION_TIMEOUT';
    }
    if (message.includes('discord') && message.includes('api')) {
      return 'DISCORD_API_ERROR';
    }
    if (message.includes('service') && message.includes('unavailable')) {
      return 'SERVICE_UNAVAILABLE';
    }

    return 'UNKNOWN_ERROR';
  }

  /**
   * Determine if an error should be retried
   * @param {Error} error - The error to check
   * @returns {boolean} Whether the error should be retried
   */
  shouldRetryError(error) {
    // Don't retry client errors (4xx) except rate limiting
    if (error.response?.status >= 400 && error.response?.status < 500) {
      return error.response.status === 429; // Only retry rate limits
    }

    // Retry server errors (5xx)
    if (error.response?.status >= 500) {
      return true;
    }

    // Retry network errors
    if (error.code && ['ECONNREFUSED', 'ENOTFOUND', 'ECONNRESET', 'ETIMEDOUT'].includes(error.code)) {
      return true;
    }

    // Don't retry validation or business logic errors
    const errorType = this.classifyError(error);
    const nonRetryableErrors = [
      'ALREADY_REGISTERED',
      'INVALID_TIME_SLOT',
      'PLAYER_NOT_FOUND',
      'REGISTRATION_CLOSED',
      'INVALID_TIMEZONE',
      'INVALID_INPUT'
    ];

    return !nonRetryableErrors.includes(errorType);
  }

  /**
   * Get retry delay for rate limited requests
   * @param {Error} error - The error to check
   * @returns {number} Delay in milliseconds, or 0 if no specific delay
   */
  getRetryDelay(error) {
    // Check for Retry-After header (Discord rate limiting)
    if (error.response?.headers?.['retry-after']) {
      return parseInt(error.response.headers['retry-after']) * 1000;
    }

    // Check for X-RateLimit-Reset header
    if (error.response?.headers?.['x-ratelimit-reset']) {
      const resetTime = parseInt(error.response.headers['x-ratelimit-reset']) * 1000;
      const now = Date.now();
      return Math.max(0, resetTime - now);
    }

    return 0;
  }

  /**
   * Generate unique error ID for tracking
   * @returns {string} Unique error identifier
   */
  generateErrorId() {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 8);
    return `ERR_${timestamp}_${random}`.toUpperCase();
  }

  /**
   * Handle Discord interaction errors specifically
   * @param {Error} error - The error that occurred
   * @param {Object} interaction - Discord interaction object
   * @param {string} context - Context of the error
   * @returns {Promise<void>}
   */
  async handleInteractionError(error, interaction, context = 'interaction') {
    const errorResponse = this.handleError(error, context, {
      userId: interaction.user?.id,
      commandName: interaction.commandName,
      guildId: interaction.guildId
    });

    try {
      const replyOptions = { 
        embeds: [errorResponse.embed], 
        ephemeral: true 
      };

      if (interaction.replied || interaction.deferred) {
        await interaction.editReply(replyOptions);
      } else {
        await interaction.reply(replyOptions);
      }
    } catch (replyError) {
      // If we can't reply to the interaction, log it
      this.logger.error('Failed to send error response to user', {
        originalErrorId: errorResponse.errorId,
        replyError: replyError.message,
        userId: interaction.user?.id,
        commandName: interaction.commandName
      });
    }
  }

  /**
   * Create a standardized error embed for manual use
   * @param {string} title - Error title
   * @param {string} message - Error message
   * @param {string} suggestion - Suggestion for user
   * @param {number} color - Embed color (default: red)
   * @returns {EmbedBuilder} Discord embed
   */
  createErrorEmbed(title, message, suggestion = null, color = 0xFF0000) {
    const embed = new EmbedBuilder()
      .setColor(color)
      .setTitle(title)
      .setDescription(message)
      .setTimestamp();

    if (suggestion) {
      embed.setFooter({ text: suggestion });
    }

    return embed;
  }

  /**
   * Create a warning embed
   * @param {string} title - Warning title
   * @param {string} message - Warning message
   * @param {string} suggestion - Suggestion for user
   * @returns {EmbedBuilder} Discord embed
   */
  createWarningEmbed(title, message, suggestion = null) {
    return this.createErrorEmbed(title, message, suggestion, 0xFFA500);
  }

  /**
   * Create an info embed
   * @param {string} title - Info title
   * @param {string} message - Info message
   * @param {string} suggestion - Additional info for user
   * @returns {EmbedBuilder} Discord embed
   */
  createInfoEmbed(title, message, suggestion = null) {
    return this.createErrorEmbed(title, message, suggestion, 0x0099FF);
  }
}
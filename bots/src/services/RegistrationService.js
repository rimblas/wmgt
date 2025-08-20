import axios from 'axios';
import { config } from '../config/config.js';
import { logger } from '../utils/Logger.js';
import { RetryHandler } from '../utils/RetryHandler.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';

/**
 * Service for handling tournament registration API communication
 */
export class RegistrationService {
  constructor() {
    this.logger = logger.child({ service: 'RegistrationService' });
    this.errorHandler = new ErrorHandler(this.logger);
    this.retryHandler = RetryHandler.forApiCalls(this.logger, {
      maxRetries: 3,
      baseDelay: 1000,
      maxDelay: 10000
    });

    this.apiClient = axios.create({
      baseURL: config.api.baseUrl,
      timeout: 15000, // Increased timeout
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // Add request interceptor for logging
    this.apiClient.interceptors.request.use(
      (config) => {
        const startTime = Date.now();
        config.metadata = { startTime };
        
        this.logger.apiRequest(config.method, config.url, {
          baseURL: config.baseURL,
          timeout: config.timeout
        });
        
        return config;
      },
      (error) => {
        this.logger.error('API Request setup failed', {
          error: error.message,
          stack: error.stack
        });
        return Promise.reject(error);
      }
    );

    // Add response interceptor for logging and error handling
    this.apiClient.interceptors.response.use(
      (response) => {
        const duration = Date.now() - response.config.metadata.startTime;
        
        this.logger.apiResponse(
          response.config.method,
          response.config.url,
          response.status,
          duration,
          {
            responseSize: JSON.stringify(response.data).length,
            success: true
          }
        );
        
        return response;
      },
      (error) => {
        const duration = error.config?.metadata?.startTime ? 
          Date.now() - error.config.metadata.startTime : 0;
        
        this.logger.apiResponse(
          error.config?.method || 'UNKNOWN',
          error.config?.url || 'UNKNOWN',
          error.response?.status || 0,
          duration,
          {
            error: error.message,
            errorCode: error.code,
            responseData: error.response?.data
          }
        );
        
        return Promise.reject(error);
      }
    );
  }

  /**
   * Fetch current active tournament with available sessions and time slots
   * @returns {Promise<Object>} Tournament data with sessions and courses
   */
  async getCurrentTournament() {
    return this.retryHandler.executeWithRetry(
      async () => {
        const response = await this.apiClient.get(config.api.endpoints.currentTournament);
        
        if (!response.data) {
          const error = new Error('No tournament data received from API');
          error.noRetry = true; // Don't retry empty responses
          throw error;
        }

        this.logger.debug('Tournament data fetched successfully', {
          sessionsCount: response.data.sessions?.length || 0,
          tournamentName: response.data.tournament?.name
        });

        return response.data;
      },
      { maxRetries: 2 }, // Fewer retries for data fetching
      'getCurrentTournament'
    );
  }

  /**
   * Register a player for a tournament session
   * @param {Object} discordUser - Discord user data
   * @param {number} sessionId - Tournament session ID
   * @param {string} timeSlot - Time slot (e.g., "22:00")
   * @param {string} timeZone - 'America/Central'
   * @returns {Promise<Object>} Registration confirmation
   */
  async registerPlayer(discordUser, sessionId, timeSlot, timeZone) {
    return this.retryHandler.executeWithRetry(
      async () => {
        const requestData = {
          session_id: sessionId,
          time_slot: timeSlot,
          time_zone: timeZone,
          discord_user: {
            id: discordUser.id,
            username: discordUser.username,
            global_name: discordUser.globalName || discordUser.username,
            avatar: discordUser.avatar,
            accent_color: discordUser.accentColor,
            banner: discordUser.banner,
            discriminator: discordUser.discriminator || '0',
            avatar_decoration_data: discordUser.avatarDecorationData
          }
        };

        this.logger.info('Attempting player registration', {
          userId: discordUser.id,
          username: discordUser.username,
          sessionId,
          timeSlot
        });

        const response = await this.apiClient.post(config.api.endpoints.register, requestData);
        
        if (!response.data?.success) {
          const error = new Error(response.data?.message || 'Registration failed');
          error.noRetry = true; // Don't retry business logic failures
          throw error;
        }

        this.logger.info('Player registration successful', {
          userId: discordUser.id,
          sessionId,
          timeSlot,
          roomNo: response.data.registration?.room_no
        });

        return response.data;
      },
      { maxRetries: 3 },
      'registerPlayer'
    );
  }

  /**
   * Unregister a player from a tournament session
   * @param {Object} discordUser - Discord user data
   * @param {number} sessionId - Tournament session ID
   * @returns {Promise<Object>} Unregistration confirmation
   */
  async unregisterPlayer(discordUser, sessionId) {
    return this.retryHandler.executeWithRetry(
      async () => {
        const requestData = {
          session_id: sessionId,
          discord_user: {
            id: discordUser.id,
            username: discordUser.username,
            global_name: discordUser.globalName || discordUser.username,
            avatar: discordUser.avatar,
            accent_color: discordUser.accentColor,
            banner: discordUser.banner,
            discriminator: discordUser.discriminator || '0',
            avatar_decoration_data: discordUser.avatarDecorationData
          }
        };

        this.logger.info('Attempting player unregistration', {
          userId: discordUser.id,
          username: discordUser.username,
          sessionId
        });

        const response = await this.apiClient.post(config.api.endpoints.unregister, requestData);
        
        if (!response.data?.success) {
          const error = new Error(response.data?.message || 'Unregistration failed');
          error.noRetry = true; // Don't retry business logic failures
          throw error;
        }

        this.logger.info('Player unregistration successful', {
          userId: discordUser.id,
          sessionId
        });

        return response.data;
      },
      { maxRetries: 3 },
      'unregisterPlayer'
    );
  }

  /**
   * Get all active registrations for a player
   * @param {string} discordId - Discord user ID
   * @returns {Promise<Object>} Player registration data
   */
  async getPlayerRegistrations(discordId) {
    return this.retryHandler.executeWithRetry(
      async () => {
        const endpoint = `${config.api.endpoints.playerRegistrations}/${discordId}`;
        
        this.logger.debug('Fetching player registrations', { discordId });
        
        const response = await this.apiClient.get(endpoint);
        
        if (!response.data) {
          const error = new Error('No registration data received from API');
          error.noRetry = true;
          throw error;
        }

        this.logger.debug('Player registrations fetched', {
          discordId,
          registrationCount: response.data.registrations?.length || 0,
          hasPlayer: !!response.data.player
        });

        return response.data;
      },
      { 
        maxRetries: 2,
        // Custom retry logic for 404s
        shouldRetry: (error) => {
          if (error.response?.status === 404) {
            // Return empty data for 404s instead of retrying
            return false;
          }
          return this.retryHandler.shouldRetry(error);
        }
      },
      'getPlayerRegistrations'
    ).catch(error => {
      // Handle 404s gracefully
      if (error.response?.status === 404) {
        this.logger.debug('Player not found, returning empty registrations', { discordId });
        return {
          player: null,
          registrations: []
        };
      }
      throw error;
    });
  }

  /**
   * Set timezone preference for a player
   * @param {string} discordId - Discord user ID
   * @param {string} timezone - IANA timezone name
   * @param {Object} discordUser - Full Discord user data for synchronization
   * @returns {Promise<Object>} Success confirmation
   */
  async setPlayerTimezone(discordId, timezone, discordUser) {
    return this.retryHandler.executeWithRetry(
      async () => {
        const requestData = {
          discord_id: discordId,
          timezone: timezone,
          discord_user: {
            id: discordUser.id,
            username: discordUser.username,
            global_name: discordUser.globalName || discordUser.username,
            avatar: discordUser.avatar,
            accent_color: discordUser.accentColor,
            banner: discordUser.banner,
            discriminator: discordUser.discriminator || '0',
            avatar_decoration_data: discordUser.avatarDecorationData
          }
        };

        this.logger.info('Setting player timezone', {
          discordId,
          timezone,
          username: discordUser.username
        });

        const response = await this.apiClient.post(config.api.endpoints.setTimezone, requestData);
        
        if (!response.data?.success) {
          const error = new Error(response.data?.message || 'Failed to set timezone preference');
          error.noRetry = true;
          throw error;
        }

        this.logger.info('Player timezone set successfully', {
          discordId,
          timezone
        });

        return response.data;
      },
      { maxRetries: 2 },
      'setPlayerTimezone'
    );
  }

  /**
   * Get timezone preference for a player
   * @param {string} discordId - Discord user ID
   * @returns {Promise<string|null>} Player's timezone preference or null if not set
   */
  async getPlayerTimezone(discordId) {
    try {
      const registrationData = await this.getPlayerRegistrations(discordId);
      
      const timezone = registrationData.player?.timezone || null;
      
      this.logger.debug('Player timezone retrieved', {
        discordId,
        timezone,
        hasPlayer: !!registrationData.player
      });
      
      return timezone;
    } catch (error) {
      this.logger.warn('Failed to fetch player timezone, returning null', {
        discordId,
        error: error.message
      });
      
      // Return null if we can't fetch timezone (don't throw error)
      return null;
    }
  }

  /**
   * Handle API errors with proper error classification and user-friendly messages
   * @param {Error} error - The error to handle
   * @param {string} context - Context where the error occurred
   * @returns {Error} Processed error with user-friendly message
   */
  handleApiError(error, context = 'api_call') {
    // Use the error handler to classify and process the error
    const errorResponse = this.errorHandler.handleError(error, context);
    
    // Create a new error with user-friendly message
    const processedError = new Error(errorResponse.embed.data.description);
    processedError.originalError = error;
    processedError.errorId = errorResponse.errorId;
    processedError.errorType = errorResponse.errorType;
    processedError.shouldRetry = errorResponse.shouldRetry;
    
    return processedError;
  }

  /**
   * Get service health status
   * @returns {Promise<Object>} Service health information
   */
  async getHealthStatus() {
    try {
      const startTime = Date.now();
      
      // Simple health check - try to fetch current tournament
      await this.getCurrentTournament();
      
      const responseTime = Date.now() - startTime;
      
      return {
        status: 'healthy',
        responseTime,
        timestamp: new Date().toISOString(),
        circuitBreaker: this.retryHandler.getCircuitBreakerStatus()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString(),
        circuitBreaker: this.retryHandler.getCircuitBreakerStatus()
      };
    }
  }
}
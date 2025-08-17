import axios from 'axios';
import { config } from '../config/config.js';

/**
 * Service for handling tournament registration API communication
 */
export class RegistrationService {
  constructor() {
    this.apiClient = axios.create({
      baseURL: config.api.baseUrl,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // Add request interceptor for logging
    this.apiClient.interceptors.request.use(
      (config) => {
        console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`);
        return config;
      },
      (error) => {
        console.error('API Request Error:', error);
        return Promise.reject(error);
      }
    );

    // Add response interceptor for error handling
    this.apiClient.interceptors.response.use(
      (response) => {
        console.log(`API Response: ${response.status} ${response.config.url}`);
        return response;
      },
      (error) => {
        console.error('API Response Error:', error.response?.status, error.response?.data);
        return Promise.reject(error);
      }
    );
  }

  /**
   * Fetch current active tournament with available sessions and time slots
   * @returns {Promise<Object>} Tournament data with sessions and courses
   */
  async getCurrentTournament() {
    try {
      const response = await this.apiClient.get(config.api.endpoints.currentTournament);
      
      if (!response.data) {
        throw new Error('No tournament data received from API');
      }

      return response.data;
    } catch (error) {
      console.error('Error fetching current tournament:', error);
      
      if (error.response?.status === 404) {
        throw new Error('No active tournament found');
      } else if (error.response?.status >= 500) {
        throw new Error('Tournament service is temporarily unavailable');
      } else if (error.code === 'ECONNREFUSED') {
        throw new Error('Unable to connect to tournament service');
      }
      
      throw new Error(`Failed to fetch tournament data: ${error.message}`);
    }
  }

  /**
   * Register a player for a tournament session
   * @param {Object} discordUser - Discord user data
   * @param {number} sessionId - Tournament session ID
   * @param {string} timeSlot - Time slot (e.g., "22:00")
   * @returns {Promise<Object>} Registration confirmation
   */
  async registerPlayer(discordUser, sessionId, timeSlot) {
    try {
      const requestData = {
        session_id: sessionId,
        time_slot: timeSlot,
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

      const response = await this.apiClient.post(config.api.endpoints.register, requestData);
      
      if (!response.data?.success) {
        throw new Error(response.data?.message || 'Registration failed');
      }

      return response.data;
    } catch (error) {
      console.error('Error registering player:', error);
      
      if (error.response?.data?.error_code) {
        const errorData = error.response.data;
        switch (errorData.error_code) {
          case 'REGISTRATION_CLOSED':
            throw new Error('Registration for this tournament session has closed');
          case 'ALREADY_REGISTERED':
            throw new Error('You are already registered for this tournament session');
          case 'INVALID_TIME_SLOT':
            throw new Error('The selected time slot is not available');
          case 'SESSION_NOT_FOUND':
            throw new Error('Tournament session not found');
          default:
            throw new Error(errorData.message || 'Registration failed');
        }
      }
      
      if (error.response?.status >= 500) {
        throw new Error('Registration service is temporarily unavailable');
      }
      
      throw new Error(`Registration failed: ${error.message}`);
    }
  }

  /**
   * Unregister a player from a tournament session
   * @param {Object} discordUser - Discord user data
   * @param {number} sessionId - Tournament session ID
   * @returns {Promise<Object>} Unregistration confirmation
   */
  async unregisterPlayer(discordUser, sessionId) {
    try {
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

      const response = await this.apiClient.post(config.api.endpoints.unregister, requestData);
      
      if (!response.data?.success) {
        throw new Error(response.data?.message || 'Unregistration failed');
      }

      return response.data;
    } catch (error) {
      console.error('Error unregistering player:', error);
      
      if (error.response?.data?.error_code) {
        const errorData = error.response.data;
        switch (errorData.error_code) {
          case 'UNREGISTRATION_FAILED':
            throw new Error('Cannot unregister: tournament may have already started');
          case 'PLAYER_NOT_FOUND':
            throw new Error('You are not registered for this tournament session');
          case 'SESSION_NOT_FOUND':
            throw new Error('Tournament session not found');
          default:
            throw new Error(errorData.message || 'Unregistration failed');
        }
      }
      
      if (error.response?.status >= 500) {
        throw new Error('Registration service is temporarily unavailable');
      }
      
      throw new Error(`Unregistration failed: ${error.message}`);
    }
  }

  /**
   * Get all active registrations for a player
   * @param {string} discordId - Discord user ID
   * @returns {Promise<Object>} Player registration data
   */
  async getPlayerRegistrations(discordId) {
    try {
      const endpoint = `${config.api.endpoints.playerRegistrations}/${discordId}`;
      const response = await this.apiClient.get(endpoint);
      
      if (!response.data) {
        throw new Error('No registration data received from API');
      }

      return response.data;
    } catch (error) {
      console.error('Error fetching player registrations:', error);
      
      if (error.response?.status === 404) {
        // Return empty registrations if player not found
        return {
          player: null,
          registrations: []
        };
      } else if (error.response?.status >= 500) {
        throw new Error('Registration service is temporarily unavailable');
      }
      
      throw new Error(`Failed to fetch registrations: ${error.message}`);
    }
  }

  /**
   * Retry API calls with exponential backoff
   * @param {Function} apiCall - The API call function to retry
   * @param {number} maxRetries - Maximum number of retries (default: 3)
   * @param {number} baseDelay - Base delay in milliseconds (default: 1000)
   * @returns {Promise<any>} Result of the API call
   */
  async retryWithBackoff(apiCall, maxRetries = 3, baseDelay = 1000) {
    let lastError;
    
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await apiCall();
      } catch (error) {
        lastError = error;
        
        // Don't retry on client errors (4xx) except for 429 (rate limit)
        if (error.response?.status >= 400 && error.response?.status < 500 && error.response?.status !== 429) {
          throw error;
        }
        
        if (attempt === maxRetries) {
          break;
        }
        
        const delay = baseDelay * Math.pow(2, attempt);
        console.log(`API call failed, retrying in ${delay}ms (attempt ${attempt + 1}/${maxRetries + 1})`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
    
    throw lastError;
  }
}
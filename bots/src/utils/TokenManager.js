import { config } from '../config/config.js';
import { Logger } from './Logger.js';
import { RetryHandler } from './RetryHandler.js';

/**
 * Manages OAuth2 token lifecycle including acquisition, storage, and refresh
 */
export class TokenManager {
  constructor() {
    this.token = null;
    this.tokenExpiry = null;
    this.refreshPromise = null;
    this.logger = new Logger('TokenManager');
    this.retryHandler = new RetryHandler(this.logger);
  }

  /**
   * Get a valid access token, refreshing if necessary
   * @returns {Promise<string>} Valid access token
   */
  async getToken() {
    try {
      // If we have a valid token, return it
      if (this.isTokenValid()) {
        return this.token;
      }

      // If a refresh is already in progress, wait for it
      if (this.refreshPromise) {
        await this.refreshPromise;
        return this.token;
      }

      // Start token refresh
      this.refreshPromise = this.refreshToken();
      await this.refreshPromise;
      this.refreshPromise = null;

      return this.token;
    } catch (error) {
      this.logger.error('Failed to get token', { error: error.message });
      throw new Error('Authentication failed: Unable to obtain access token');
    }
  }

  /**
   * Check if current token is valid and not expired
   * @returns {boolean} True if token is valid
   */
  isTokenValid() {
    if (!this.token || !this.tokenExpiry) {
      return false;
    }

    // Check if token expires within the buffer time
    const now = Date.now();
    const bufferTime = config.api.oauth.tokenExpiryBuffer * 1000; // Convert to milliseconds
    return (this.tokenExpiry - now) > bufferTime;
  }

  /**
   * Refresh the access token using client credentials
   * @returns {Promise<void>}
   */
  async refreshToken() {
    try {
      this.logger.info('Refreshing OAuth2 token');

      const tokenData = await this.retryHandler.executeWithRetry(
        () => this.requestToken(),
        {
          maxRetries: 3,
          baseDelay: 1000,
          maxDelay: 5000,
          backoffMultiplier: 2
        },
        'refreshToken'
      );

      this.token = tokenData.access_token;
      // Calculate expiry time (subtract buffer to refresh early)
      const expiresIn = tokenData.expires_in || 3600; // Default to 1 hour
      this.tokenExpiry = Date.now() + (expiresIn * 1000);

      this.logger.info('OAuth2 token refreshed successfully', {
        expiresIn: expiresIn,
        expiryTime: new Date(this.tokenExpiry).toISOString()
      });
    } catch (error) {
      this.logger.error('Failed to refresh token', { error: error.message });
      this.clearToken();
      throw error;
    }
  }

  /**
   * Make the actual token request to the OAuth2 endpoint
   * @returns {Promise<Object>} Token response data
   */
  async requestToken() {
    const { clientId, clientSecret, tokenUrl, grantType } = config.api.oauth;

    if (!clientId || !clientSecret) {
      throw new Error('OAuth2 client credentials not configured');
    }

    const params = new URLSearchParams({
      grant_type: grantType,
      client_id: clientId,
      client_secret: clientSecret
    });

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), config.api.timeout);

    try {
      const response = await fetch(tokenUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json'
        },
        body: params,
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        this.logger.error('Token request failed', {
          status: response.status,
          statusText: response.statusText,
          error: errorText
        });
        throw new Error(`Token request failed: ${response.status} ${response.statusText}`);
      }

      const tokenData = await response.json();

      if (!tokenData.access_token) {
        throw new Error('Invalid token response: missing access_token');
      }

      return tokenData;
    } catch (error) {
      clearTimeout(timeoutId);
      throw error;
    }
  }

  /**
   * Clear stored token data
   */
  clearToken() {
    this.token = null;
    this.tokenExpiry = null;
    this.refreshPromise = null;
    this.logger.info('Token data cleared');
  }

  /**
   * Get authorization header for API requests
   * @returns {Promise<Object>} Authorization header object
   */
  async getAuthHeader() {
    const token = await this.getToken();
    return {
      'Authorization': `Bearer ${token}`
    };
  }

  /**
   * Get token expiry information for monitoring
   * @returns {Object} Token status information
   */
  getTokenStatus() {
    return {
      hasToken: !!this.token,
      isValid: this.isTokenValid(),
      expiryTime: this.tokenExpiry ? new Date(this.tokenExpiry).toISOString() : null,
      timeUntilExpiry: this.tokenExpiry ? Math.max(0, this.tokenExpiry - Date.now()) : 0
    };
  }
}

// Export singleton instance
export const tokenManager = new TokenManager();
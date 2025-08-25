import axios from 'axios';
import { config } from '../config/config.js';
import { logger } from '../utils/Logger.js';
import { RetryHandler } from '../utils/RetryHandler.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';
import { tokenManager } from '../utils/TokenManager.js';

/**
 * Base service class for authenticated API calls using OAuth2
 * Provides common functionality for services that need bearer token authentication
 */
export class BaseAuthenticatedService {
  constructor(serviceName = 'AuthenticatedService') {
    this.serviceName = serviceName;
    this.logger = logger.child({ service: serviceName });
    this.errorHandler = new ErrorHandler(this.logger);
    this.retryHandler = RetryHandler.forApiCalls(this.logger, {
      maxRetries: 3,
      baseDelay: 1000,
      maxDelay: 10000
    });

    this.apiClient = axios.create({
      baseURL: config.api.baseUrl,
      timeout: config.api.timeout,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    this.setupInterceptors();
  }

  /**
   * Setup axios interceptors for authentication, logging, and error handling
   */
  setupInterceptors() {
    // Request interceptor - add authentication and logging
    this.apiClient.interceptors.request.use(
      async (config) => {
        const startTime = Date.now();
        config.metadata = { startTime };

        try {
          // Add authentication header
          const authHeader = await tokenManager.getAuthHeader();
          config.headers = { ...config.headers, ...authHeader };

          this.logger.apiRequest(config.method, config.url, {
            baseURL: config.baseURL,
            timeout: config.timeout,
            hasAuth: !!authHeader.Authorization
          });
        } catch (error) {
          this.logger.error('Failed to add authentication to request', {
            error: error.message,
            url: config.url
          });
          throw error;
        }

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

    // Response interceptor - logging and error handling
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
      async (error) => {
        const duration = error.config?.metadata?.startTime ? 
          Date.now() - error.config.metadata.startTime : 0;

        // Handle 401 Unauthorized - token might be expired
        if (error.response?.status === 401) {
          this.logger.warn('Received 401 Unauthorized, clearing token cache', {
            url: error.config?.url
          });
          tokenManager.clearToken();
        }

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
   * Make an authenticated GET request with retry logic
   * @param {string} endpoint - API endpoint path
   * @param {Object} params - Query parameters
   * @param {Object} options - Additional options
   * @returns {Promise<Object>} API response data
   */
  async authenticatedGet(endpoint, params = {}, options = {}) {
    return this.retryHandler.executeWithRetry(
      async () => {
        const response = await this.apiClient.get(endpoint, { 
          params,
          ...options 
        });

        if (!response.data) {
          const error = new Error('No data received from API');
          error.noRetry = true;
          throw error;
        }

        return response.data;
      },
      { 
        maxRetries: options.maxRetries || 3,
        shouldRetry: (error) => {
          // Retry on 401 (token expired) after clearing token
          if (error.response?.status === 401) {
            this.logger.info('Retrying GET request after 401 - token will be refreshed');
            return true;
          }
          
          // Don't retry on 403 (forbidden) - likely a permissions issue
          if (error.response?.status === 403) {
            return false;
          }
          
          // Handle rate limiting with backoff
          if (error.response?.status === 429) {
            const retryAfter = error.response.headers?.['retry-after'];
            if (retryAfter && parseInt(retryAfter) > 300) {
              // Don't retry if rate limit is too long (> 5 minutes)
              return false;
            }
            return true;
          }
          
          return this.retryHandler.shouldRetry(error);
        }
      },
      `${this.serviceName}.authenticatedGet`
    );
  }

  /**
   * Make an authenticated POST request with retry logic
   * @param {string} endpoint - API endpoint path
   * @param {Object} data - Request body data
   * @param {Object} options - Additional options
   * @returns {Promise<Object>} API response data
   */
  async authenticatedPost(endpoint, data = {}, options = {}) {
    return this.retryHandler.executeWithRetry(
      async () => {
        const response = await this.apiClient.post(endpoint, data, options);

        if (!response.data) {
          const error = new Error('No data received from API');
          error.noRetry = true;
          throw error;
        }

        return response.data;
      },
      { 
        maxRetries: options.maxRetries || 3,
        shouldRetry: (error) => {
          // Retry on 401 (token expired) after clearing token
          if (error.response?.status === 401) {
            this.logger.info('Retrying POST request after 401 - token will be refreshed');
            return true;
          }
          
          // Don't retry on 403 (forbidden) - likely a permissions issue
          if (error.response?.status === 403) {
            return false;
          }
          
          // Handle rate limiting with backoff
          if (error.response?.status === 429) {
            const retryAfter = error.response.headers?.['retry-after'];
            if (retryAfter && parseInt(retryAfter) > 300) {
              // Don't retry if rate limit is too long (> 5 minutes)
              return false;
            }
            return true;
          }
          
          return this.retryHandler.shouldRetry(error);
        }
      },
      `${this.serviceName}.authenticatedPost`
    );
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
   * Get authentication status for health checks
   * @returns {Promise<Object>} Authentication status information
   */
  async getAuthStatus() {
    try {
      const tokenStatus = tokenManager.getTokenStatus();
      
      return {
        hasToken: tokenStatus.hasToken,
        isValid: tokenStatus.isValid,
        expiryTime: tokenStatus.expiryTime,
        timeUntilExpiry: tokenStatus.timeUntilExpiry
      };
    } catch (error) {
      return {
        hasToken: false,
        isValid: false,
        error: error.message
      };
    }
  }

  /**
   * Get service health status including authentication
   * @returns {Promise<Object>} Service health information
   */
  async getHealthStatus() {
    try {
      const startTime = Date.now();
      const authStatus = await this.getAuthStatus();
      
      // Test authentication by making a simple authenticated request
      // This will be overridden by child classes with appropriate test endpoints
      
      const responseTime = Date.now() - startTime;
      
      return {
        status: 'healthy',
        responseTime,
        timestamp: new Date().toISOString(),
        authentication: authStatus,
        circuitBreaker: this.retryHandler.getCircuitBreakerStatus()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString(),
        authentication: await this.getAuthStatus(),
        circuitBreaker: this.retryHandler.getCircuitBreakerStatus()
      };
    }
  }
}
import axios from 'axios';
import { config } from '../config/config.js';
import { logger } from '../utils/Logger.js';
import { RetryHandler } from '../utils/RetryHandler.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';

/**
 * Service for handling votes API communication
 */
export class VotesService {
  constructor() {
    this.logger = logger.child({ service: 'VotesService' });
    this.errorHandler = new ErrorHandler(this.logger);
    this.retryHandler = RetryHandler.forApiCalls(this.logger, {
      maxRetries: 3,
      baseDelay: 1000,
      maxDelay: 10000
    });

    this.apiClient = axios.create({
      baseURL: config.api.baseUrl,
      timeout: 15000,
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
   * Fetch current voting results from the votes API
   * @returns {Promise<Object>} Voting data with items array containing course voting information
   */
  async getVotingResults() {
    return this.retryHandler.executeWithRetry(
      async () => {
        const response = await this.apiClient.get(config.api.endpoints.votes);
        
        if (!response.data) {
          const error = new Error('No voting data received from API');
          error.noRetry = true; // Don't retry empty responses
          throw error;
        }

        // Validate response structure
        if (!response.data.items || !Array.isArray(response.data.items)) {
          const error = new Error('Invalid voting data format received from API');
          error.noRetry = true;
          throw error;
        }

        this.logger.debug('Voting data fetched successfully', {
          itemsCount: response.data.items.length,
          hasMore: response.data.hasMore,
          count: response.data.count
        });

        return response.data;
      },
      { maxRetries: 2 }, // Fewer retries for data fetching
      'getVotingResults'
    );
  }

  /**
   * Handle API errors with proper error classification and user-friendly messages
   * @param {Error} error - The error to handle
   * @param {string} context - Context where the error occurred
   * @returns {Error} Processed error with user-friendly message
   */
  handleApiError(error, context = 'votes_api_call') {
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
      
      // Simple health check - try to fetch voting results
      await this.getVotingResults();
      
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
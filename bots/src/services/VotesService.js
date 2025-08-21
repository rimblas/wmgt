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
   * Parse API response and extract course data into structured format
   * @param {Object} apiResponse - Raw API response from votes endpoint
   * @returns {Object} Processed data with easyCourses and hardCourses arrays
   */
  formatVotingData(apiResponse) {
    if (!apiResponse || !apiResponse.items || !Array.isArray(apiResponse.items)) {
      this.logger.warn('Invalid API response structure for formatting', { apiResponse });
      return { easyCourses: [], hardCourses: [] };
    }

    const easyCourses = [];
    const hardCourses = [];

    apiResponse.items.forEach(item => {
      // Process easy course data
      if (item.easy_course && item.easy_name) {
        easyCourses.push({
          code: item.easy_course,
          name: item.easy_name,
          votes: item.easy_votes || 0,
          isTop: item.easy_votes_top === 'Y',
          order: item.easy_vote_order || 0
        });
      }

      // Process hard course data (handle null hard courses)
      if (item.hard_course && item.hard_name) {
        hardCourses.push({
          code: item.hard_course,
          name: item.hard_name,
          votes: item.hard_votes || 0,
          isTop: item.hard_votes_top === 'Y',
          order: item.hard_vote_order || 0
        });
      }
    });

    // Sort courses by vote order (maintaining API ordering)
    easyCourses.sort((a, b) => a.order - b.order);
    hardCourses.sort((a, b) => a.order - b.order);

    this.logger.debug('Voting data formatted successfully', {
      easyCoursesCount: easyCourses.length,
      hardCoursesCount: hardCourses.length
    });

    return { easyCourses, hardCourses };
  }

  /**
   * Create formatted display strings for Discord embed fields
   * @param {Array} courses - Array of course objects with code, name, votes, isTop
   * @returns {string} Formatted string for Discord embed field
   */
  formatCoursesForDisplay(courses) {
    if (!courses || courses.length === 0) {
      return 'No courses available';
    }

    const formattedCourses = courses.map(course => {
      // Handle zero and negative votes display clearly (Requirements 3.2, 3.3)
      const voteDisplay = course.votes.toString();
      
      // Add visual indicator for top courses (Requirement 2.5)
      const topIndicator = course.isTop ? '🏆 ' : '';
      
      // Enhanced format with better visual hierarchy
      // Format: "🏆 **ABC** (123) - Course Name" for top courses
      // Format: "**ABC** (123) - Course Name" for regular courses
      return `${topIndicator}**${course.code}** (${voteDisplay}) - ${course.name}`;
    });

    let result = formattedCourses.join('\n');
    
    // Handle Discord character limits (1024 per field) with better truncation
    if (result.length > 1024) {
      this.logger.warn('Course display string exceeds Discord field limit', {
        length: result.length,
        coursesCount: courses.length
      });
      
      // Try to truncate at a course boundary to avoid cutting off course names
      const lines = result.split('\n');
      let truncatedResult = '';
      let currentLength = 0;
      
      for (let i = 0; i < lines.length; i++) {
        const lineWithNewline = lines[i] + (i < lines.length - 1 ? '\n' : '');
        if (currentLength + lineWithNewline.length + 20 > 1024) { // Leave room for truncation message
          truncatedResult += '\n*... and more courses*';
          break;
        }
        truncatedResult += lineWithNewline;
        currentLength += lineWithNewline.length;
      }
      
      result = truncatedResult;
    }

    return result;
  }

  /**
   * Split courses into Easy and Hard columns with proper formatting
   * @param {Object} formattedData - Data from formatVotingData()
   * @returns {Object} Object with formatted easy and hard course strings
   */
  splitIntoColumns(formattedData) {
    const { easyCourses, hardCourses } = formattedData;

    return {
      easyColumn: this.formatCoursesForDisplay(easyCourses),
      hardColumn: this.formatCoursesForDisplay(hardCourses)
    };
  }

  /**
   * Create complete Discord embed data structure for voting results
   * @param {Object} apiResponse - Raw API response from votes endpoint
   * @returns {Object} Discord embed object ready for sending
   */
  createVotesEmbed(apiResponse) {
    const formattedData = this.formatVotingData(apiResponse);
    const columns = this.splitIntoColumns(formattedData);

    const embed = {
      title: '🏆 Course Voting Results',
      color: 0x00AE86,
      fields: [
        {
          name: 'Easy Courses',
          value: columns.easyColumn,
          inline: true
        },
        {
          name: 'Hard Courses',
          value: columns.hardColumn,
          inline: true
        }
      ],
      footer: {
        text: 'Vote counts updated in real-time'
      },
      timestamp: new Date().toISOString()
    };

    this.logger.debug('Votes embed created successfully', {
      fieldsCount: embed.fields.length,
      easyCoursesLength: columns.easyColumn.length,
      hardCoursesLength: columns.hardColumn.length
    });

    return embed;
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
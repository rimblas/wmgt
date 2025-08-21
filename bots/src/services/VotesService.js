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
        try {
          const response = await this.apiClient.get(config.api.endpoints.votes);

          // Enhanced validation with detailed logging
          if (!response) {
            this.logger.error('No response received from votes API');
            const error = new Error('No response received from voting service');
            error.noRetry = true;
            throw error;
          }

          if (!response.data) {
            this.logger.error('Empty response data from votes API', {
              status: response.status,
              headers: response.headers
            });
            const error = new Error('No voting data received from API');
            error.noRetry = true;
            throw error;
          }

          // Validate response structure with detailed error messages
          if (typeof response.data !== 'object') {
            this.logger.error('Invalid response data type from votes API', {
              dataType: typeof response.data,
              data: response.data
            });
            const error = new Error('Invalid voting data format received from API');
            error.noRetry = true;
            throw error;
          }

          if (!response.data.items) {
            this.logger.error('Missing items array in votes API response', {
              responseKeys: Object.keys(response.data),
              data: response.data
            });
            const error = new Error('Invalid voting data format received from API - missing items');
            error.noRetry = true;
            throw error;
          }

          if (!Array.isArray(response.data.items)) {
            this.logger.error('Items is not an array in votes API response', {
              itemsType: typeof response.data.items,
              items: response.data.items
            });
            const error = new Error('Invalid voting data format received from API - items not array');
            error.noRetry = true;
            throw error;
          }

          // Validate individual items structure
          const invalidItems = response.data.items.filter((item, index) => {
            const isValid = item &&
              typeof item === 'object' &&
              (item.easy_course || item.hard_course); // At least one course should exist

            if (!isValid) {
              this.logger.warn('Invalid item in votes API response', {
                itemIndex: index,
                item: item
              });
            }

            return !isValid;
          });

          if (invalidItems.length > 0) {
            this.logger.warn('Some invalid items found in votes API response', {
              invalidItemsCount: invalidItems.length,
              totalItemsCount: response.data.items.length
            });
          }

          this.logger.debug('Voting data fetched and validated successfully', {
            itemsCount: response.data.items.length,
            validItemsCount: response.data.items.length - invalidItems.length,
            hasMore: response.data.hasMore,
            count: response.data.count,
            responseSize: JSON.stringify(response.data).length
          });

          return response.data;

        } catch (error) {
          // Enhanced error logging for debugging
          this.logger.error('Error fetching voting results', {
            errorMessage: error.message,
            errorCode: error.code,
            errorName: error.name,
            httpStatus: error.response?.status,
            httpStatusText: error.response?.statusText,
            responseHeaders: error.response?.headers,
            responseData: error.response?.data,
            requestConfig: {
              url: error.config?.url,
              method: error.config?.method,
              timeout: error.config?.timeout,
              baseURL: error.config?.baseURL
            },
            stack: error.stack
          });

          throw error;
        }
      },
      { maxRetries: 2 }, // Fewer retries for data fetching
      'getVotingResults'
    );
  }

  /**
   * Handle API errors with proper error classification and user-friendly messages
   * @param {Error} error - The error to handle
   * @param {string} context - Context where the error occurred
   * @param {Object} metadata - Additional error context
   * @returns {Error} Processed error with user-friendly message
   */
  handleApiError(error, context = 'votes_api_call', metadata = {}) {
    // Enhanced logging for debugging API errors
    this.logger.error('Votes API error occurred', {
      context,
      errorMessage: error.message,
      errorCode: error.code,
      httpStatus: error.response?.status,
      httpStatusText: error.response?.statusText,
      responseData: error.response?.data,
      requestUrl: error.config?.url,
      requestMethod: error.config?.method,
      requestTimeout: error.config?.timeout,
      stack: error.stack,
      metadata
    });

    // Classify the specific error type for votes API
    let errorType = 'UNKNOWN_ERROR';

    if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
      errorType = 'VOTES_API_UNAVAILABLE';
    } else if (error.code === 'ETIMEDOUT' || error.message?.includes('timeout')) {
      errorType = 'TIMEOUT_ERROR';
    } else if (error.response?.status === 429) {
      errorType = 'RATE_LIMITED';
    } else if (error.response?.status >= 500) {
      errorType = 'VOTES_API_UNAVAILABLE';
    } else if (error.response?.status === 404) {
      errorType = 'VOTES_NO_DATA';
    } else if (error.message?.includes('Invalid voting data format')) {
      errorType = 'VOTES_DATA_INVALID';
    } else if (error.message?.includes('No voting data received')) {
      errorType = 'VOTES_NO_DATA';
    }

    // Use the error handler to create user-friendly response
    const errorResponse = this.errorHandler.handleError(error, context, {
      ...metadata,
      apiEndpoint: config.api.endpoints.votes,
      errorType
    });

    // Create a new error with enhanced information
    const processedError = new Error(errorResponse.embed.data.description);
    processedError.originalError = error;
    processedError.errorId = errorResponse.errorId;
    processedError.errorType = errorResponse.errorType;
    processedError.shouldRetry = errorResponse.shouldRetry;
    processedError.retryAfter = errorResponse.retryAfter;

    return processedError;
  }

  /**
   * Parse API response and extract course data into structured format
   * @param {Object} apiResponse - Raw API response from votes endpoint
   * @returns {Object} Processed data with easyCourses and hardCourses arrays
   */
  formatVotingData(apiResponse) {
    try {
      // Enhanced validation with detailed error messages
      if (!apiResponse) {
        this.logger.error('Null or undefined API response provided for formatting');
        throw new Error('No voting data provided for formatting');
      }

      if (!apiResponse.items) {
        this.logger.error('API response missing items array', {
          responseKeys: Object.keys(apiResponse),
          response: apiResponse
        });
        throw new Error('Invalid voting data format - missing items');
      }

      if (!Array.isArray(apiResponse.items)) {
        this.logger.error('API response items is not an array', {
          itemsType: typeof apiResponse.items,
          items: apiResponse.items
        });
        throw new Error('Invalid voting data format - items not array');
      }

      const easyCourses = [];
      const hardCourses = [];
      const processingErrors = [];

      apiResponse.items.forEach((item, index) => {
        try {
          // Validate item structure
          if (!item || typeof item !== 'object') {
            processingErrors.push(`Item ${index}: Invalid item structure`);
            return;
          }

          // Process easy course data with validation
          if (item.easy_course && item.easy_name) {
            // Validate easy course data
            if (typeof item.easy_course !== 'string' || typeof item.easy_name !== 'string') {
              processingErrors.push(`Item ${index}: Invalid easy course data types`);
            } else {
              easyCourses.push({
                code: item.easy_course.trim(),
                name: item.easy_name.trim(),
                votes: this.validateVoteCount(item.easy_votes, `Item ${index} easy_votes`),
                isTop: item.easy_votes_top === 'top',
                order: this.validateOrder(item.easy_vote_order, `Item ${index} easy_vote_order`)
              });
            }
          } else if (item.easy_course || item.easy_name) {
            // Partial easy course data
            processingErrors.push(`Item ${index}: Incomplete easy course data - code: ${item.easy_course}, name: ${item.easy_name}`);
          }

          // Process hard course data (handle null hard courses gracefully)
          if (item.hard_course && item.hard_name) {
            // Validate hard course data
            if (typeof item.hard_course !== 'string' || typeof item.hard_name !== 'string') {
              processingErrors.push(`Item ${index}: Invalid hard course data types`);
            } else {
              hardCourses.push({
                code: item.hard_course.trim(),
                name: item.hard_name.trim(),
                votes: this.validateVoteCount(item.hard_votes, `Item ${index} hard_votes`),
                isTop: item.hard_votes_top === 'top',
                order: this.validateOrder(item.hard_vote_order, `Item ${index} hard_vote_order`)
              });
            }
          } else if (item.hard_course || item.hard_name) {
            // Partial hard course data (this is acceptable as some courses may not have hard versions)
            this.logger.debug(`Item ${index}: Incomplete hard course data (acceptable) - code: ${item.hard_course}, name: ${item.hard_name}`);
          }

        } catch (itemError) {
          processingErrors.push(`Item ${index}: ${itemError.message}`);
          this.logger.warn('Error processing individual voting item', {
            itemIndex: index,
            item: item,
            error: itemError.message
          });
        }
      });

      // Log processing errors if any
      if (processingErrors.length > 0) {
        this.logger.warn('Errors occurred while processing voting data items', {
          errorCount: processingErrors.length,
          totalItems: apiResponse.items.length,
          errors: processingErrors
        });
      }

      // Sort courses by vote order (maintaining API ordering)
      // easyCourses.sort((a, b) => a.order - b.order);
      // hardCourses.sort((a, b) => a.order - b.order);

      this.logger.debug('Voting data formatted successfully', {
        totalItems: apiResponse.items.length,
        easyCoursesCount: easyCourses.length,
        hardCoursesCount: hardCourses.length,
        processingErrorsCount: processingErrors.length
      });

      // Return empty arrays if no valid courses found
      if (easyCourses.length === 0 && hardCourses.length === 0) {
        this.logger.warn('No valid courses found in voting data');
        return { easyCourses: [], hardCourses: [] };
      }

      return { easyCourses, hardCourses };

    } catch (error) {
      this.logger.error('Error formatting voting data', {
        error: error.message,
        stack: error.stack,
        apiResponse: apiResponse
      });
      throw new Error(`Unable to process voting data: ${error.message}`);
    }
  }

  /**
   * Validate and normalize vote count values
   * @param {any} voteCount - Raw vote count from API
   * @param {string} context - Context for error logging
   * @returns {number} Validated vote count
   */
  validateVoteCount(voteCount, context) {
    if (voteCount === null || voteCount === undefined) {
      return 0;
    }

    if (typeof voteCount === 'string') {
      const parsed = parseInt(voteCount, 10);
      if (isNaN(parsed)) {
        this.logger.warn(`Invalid vote count string: ${voteCount}`, { context });
        return 0;
      }
      return parsed;
    }

    if (typeof voteCount === 'number') {
      if (isNaN(voteCount) || !isFinite(voteCount)) {
        this.logger.warn(`Invalid vote count number: ${voteCount}`, { context });
        return 0;
      }
      return Math.floor(voteCount); // Ensure integer
    }

    this.logger.warn(`Unexpected vote count type: ${typeof voteCount}`, { context, voteCount });
    return 0;
  }

  /**
   * Validate and normalize order values
   * @param {any} order - Raw order from API
   * @param {string} context - Context for error logging
   * @returns {number} Validated order
   */
  validateOrder(order, context) {
    if (order === null || order === undefined) {
      return 0;
    }

    if (typeof order === 'string') {
      const parsed = parseInt(order, 10);
      if (isNaN(parsed)) {
        this.logger.warn(`Invalid order string: ${order}`, { context });
        return 0;
      }
      return parsed;
    }

    if (typeof order === 'number') {
      if (isNaN(order) || !isFinite(order)) {
        this.logger.warn(`Invalid order number: ${order}`, { context });
        return 0;
      }
      return Math.floor(order); // Ensure integer
    }

    this.logger.warn(`Unexpected order type: ${typeof order}`, { context, order });
    return 0;
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
      // add a space to positive votes so they align
      const voteDisplay = (course.votes<0 ? '' :' ') +course.votes.toString();

      // Add visual indicator for top courses (Requirement 2.5)
      const topIndicator = course.isTop ? ' ⛳️' : '';

      // Enhanced format with better visual hierarchy
      // Format: "ABC  123 ⛳️ " for top courses
      // Format: "**ABC** (123) - Course Name" for regular courses
      return `${course.code}    ${voteDisplay}${topIndicator}`;
    });

    let result = 'Course Votes\n------ -----\n'+formattedCourses.join('\n');

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
      easyColumn: '```' + this.formatCoursesForDisplay(easyCourses) + '```',
      hardColumn: '```' + this.formatCoursesForDisplay(hardCourses) + '```'
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
        text: 'Votes as of'
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
   * Create text-based display as fallback when embeds fail
   * @param {Object} apiResponse - Raw API response from votes endpoint
   * @returns {string} Formatted text display of voting results
   */
  createTextDisplay(apiResponse) {
    try {
      const formattedData = this.formatVotingData(apiResponse);
      const { easyCourses, hardCourses } = formattedData;

      let textDisplay = '🏆 **Course Voting Results**\n\n';

      // Easy Courses Section
      textDisplay += '**Easy Courses:**\n';
      if (easyCourses.length > 0) {
        easyCourses.forEach(course => {
          const topIndicator = course.isTop ? '🏆 ' : '';
          textDisplay += `${topIndicator}**${course.code}** (${course.votes}) - ${course.name}\n`;
        });
      } else {
        textDisplay += 'No easy courses available\n';
      }

      textDisplay += '\n**Hard Courses:**\n';
      if (hardCourses.length > 0) {
        hardCourses.forEach(course => {
          const topIndicator = course.isTop ? '🏆 ' : '';
          textDisplay += `${topIndicator}**${course.code}** (${course.votes}) - ${course.name}\n`;
        });
      } else {
        textDisplay += 'No hard courses available\n';
      }

      textDisplay += '\n*Vote counts updated in real-time*';

      // Ensure we don't exceed Discord's message limit (2000 characters)
      if (textDisplay.length > 1900) {
        textDisplay = textDisplay.substring(0, 1850) + '\n\n*... and more courses*\n\n*Vote counts updated in real-time*';
      }

      this.logger.debug('Text display created successfully', {
        textLength: textDisplay.length,
        easyCoursesCount: easyCourses.length,
        hardCoursesCount: hardCourses.length
      });

      return textDisplay;

    } catch (error) {
      this.logger.error('Error creating text display', {
        error: error.message,
        stack: error.stack
      });

      return '❌ **Voting Results Unavailable**\n\nUnable to process voting data for display. Please try again later.';
    }
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
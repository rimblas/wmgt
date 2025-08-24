import { BaseAuthenticatedService } from './BaseAuthenticatedService.js';
import { config } from '../config/config.js';

/**
 * Service for handling course leaderboard API communication
 * Extends BaseAuthenticatedService to inherit OAuth2 authentication capabilities
 */
export class CourseLeaderboardService extends BaseAuthenticatedService {
  constructor() {
    super('CourseLeaderboardService');
    
    // Cache for course data to reduce API calls
    this.courseCache = new Map();
    this.courseCacheExpiry = null;
    this.courseCacheTimeout = 5 * 60 * 1000; // 5 minutes cache
  }

  /**
   * Get authentication token using OAuth2 client credentials flow
   * Inherited from BaseAuthenticatedService via tokenManager
   * @returns {Promise<string>} Bearer token for API authentication
   */
  async getAuthToken() {
    try {
      const authHeader = await this.tokenManager.getAuthHeader();
      return authHeader.Authorization.replace('Bearer ', '');
    } catch (error) {
      this.logger.error('Failed to obtain authentication token', {
        error: error.message,
        stack: error.stack
      });
      throw this.handleApiError(error, 'authentication');
    }
  }

  /**
   * Refresh authentication token if needed
   * Inherited from BaseAuthenticatedService via tokenManager
   * @returns {Promise<boolean>} True if token was refreshed, false if still valid
   */
  async refreshTokenIfNeeded() {
    try {
      const tokenStatus = this.tokenManager.getTokenStatus();
      
      if (!tokenStatus.isValid || tokenStatus.timeUntilExpiry < config.api.oauth.tokenExpiryBuffer * 1000) {
        this.logger.info('Token refresh needed', {
          hasToken: tokenStatus.hasToken,
          isValid: tokenStatus.isValid,
          timeUntilExpiry: tokenStatus.timeUntilExpiry
        });
        
        // Clear the current token to force refresh on next request
        this.tokenManager.clearToken();
        
        // Get new token (this will trigger the refresh)
        await this.getAuthToken();
        
        this.logger.info('Token refreshed successfully');
        return true;
      }
      
      return false;
    } catch (error) {
      this.logger.error('Failed to refresh authentication token', {
        error: error.message,
        stack: error.stack
      });
      throw this.handleApiError(error, 'token_refresh');
    }
  }

  /**
   * Test authentication by making a simple authenticated request
   * @returns {Promise<Object>} Authentication test result
   */
  async testAuthentication() {
    try {
      // Use the courses endpoint as a simple test of authentication
      const response = await this.authenticatedGet(config.api.endpoints.courses, {}, {
        maxRetries: 1 // Don't retry for auth test
      });
      
      return {
        success: true,
        message: 'Authentication successful',
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      this.logger.error('Authentication test failed', {
        error: error.message,
        httpStatus: error.response?.status
      });
      
      return {
        success: false,
        message: error.message,
        timestamp: new Date().toISOString(),
        httpStatus: error.response?.status
      };
    }
  }

  /**
   * Fetch course leaderboard data for a specific course
   * @param {string} courseCode - 3-letter course code (e.g., "ALE", "BBH")
   * @param {string} userId - Discord user ID to identify user's scores
   * @returns {Promise<Object>} Leaderboard data with user context
   */
  async getCourseLeaderboard(courseCode, userId) {
    if (!courseCode || typeof courseCode !== 'string') {
      const error = new Error('Course code is required and must be a string');
      error.noRetry = true;
      throw error;
    }

    if (!userId || typeof userId !== 'string') {
      const error = new Error('User ID is required and must be a string');
      error.noRetry = true;
      throw error;
    }

    const normalizedCourseCode = courseCode.trim().toUpperCase();
    
    return this.retryHandler.executeWithRetry(
      async () => {
        try {
          this.logger.debug('Fetching course leaderboard', {
            courseCode: normalizedCourseCode,
            userId: userId
          });

          // Build endpoint URL with course code
          const endpoint = `${config.api.endpoints.leaderboards}/${normalizedCourseCode}`;
          
          // Add discord_id as query parameter to identify user scores
          const params = {
            discord_id: userId
          };

          const response = await this.authenticatedGet(endpoint, params);

          // Validate response structure
          if (!response) {
            const error = new Error('No response received from leaderboards API');
            error.noRetry = true;
            throw error;
          }

          if (!response.items) {
            this.logger.warn('No items array in leaderboard response', {
              courseCode: normalizedCourseCode,
              responseKeys: Object.keys(response)
            });
            
            // Return empty leaderboard structure for valid courses with no scores
            return {
              items: [],
              hasMore: false,
              count: 0,
              courseCode: normalizedCourseCode,
              userId: userId
            };
          }

          if (!Array.isArray(response.items)) {
            const error = new Error('Invalid leaderboard data format - items not array');
            error.noRetry = true;
            throw error;
          }

          // Validate individual leaderboard entries
          const validItems = response.items.filter((item, index) => {
            const isValid = item &&
              typeof item === 'object' &&
              typeof item.pos === 'number' &&
              typeof item.player_name === 'string' &&
              typeof item.score === 'number';

            if (!isValid) {
              this.logger.warn('Invalid leaderboard entry', {
                courseCode: normalizedCourseCode,
                itemIndex: index,
                item: item
              });
            }

            return isValid;
          });

          this.logger.debug('Course leaderboard fetched successfully', {
            courseCode: normalizedCourseCode,
            totalItems: response.items.length,
            validItems: validItems.length,
            hasMore: response.hasMore,
            count: response.count
          });

          return {
            ...response,
            items: validItems,
            courseCode: normalizedCourseCode,
            userId: userId
          };

        } catch (error) {
          // Enhanced error logging for debugging
          this.logger.error('Error fetching course leaderboard', {
            courseCode: normalizedCourseCode,
            userId: userId,
            errorMessage: error.message,
            errorCode: error.code,
            httpStatus: error.response?.status,
            httpStatusText: error.response?.statusText,
            responseData: error.response?.data,
            stack: error.stack
          });

          // Handle specific error cases
          if (error.response?.status === 404) {
            const courseError = new Error(`Course '${normalizedCourseCode}' not found. Please check the course code and try again.`);
            courseError.noRetry = true;
            courseError.courseCode = normalizedCourseCode;
            throw courseError;
          }

          if (error.response?.status === 400) {
            const validationError = new Error(`Invalid course code '${normalizedCourseCode}'. Course codes should be 3 letters (e.g., ALE, BBH).`);
            validationError.noRetry = true;
            validationError.courseCode = normalizedCourseCode;
            throw validationError;
          }

          throw error;
        }
      },
      { 
        maxRetries: 3,
        shouldRetry: (error) => {
          // Don't retry on validation errors or course not found
          if (error.noRetry || error.response?.status === 404 || error.response?.status === 400) {
            return false;
          }
          
          // Retry on 401 (token expired) after clearing token
          if (error.response?.status === 401) {
            return true;
          }
          
          return this.retryHandler.shouldRetry(error);
        }
      },
      'getCourseLeaderboard'
    );
  }

  /**
   * Fetch available courses for autocomplete functionality
   * Implements caching to reduce API calls and improve performance
   * @returns {Promise<Array>} Array of course objects with code and name
   */
  async getAvailableCourses() {
    // Check cache first
    if (this.courseCache.size > 0 && this.courseCacheExpiry && Date.now() < this.courseCacheExpiry) {
      this.logger.debug('Returning cached course data', {
        cacheSize: this.courseCache.size,
        cacheExpiry: new Date(this.courseCacheExpiry).toISOString()
      });
      return Array.from(this.courseCache.values());
    }

    return this.retryHandler.executeWithRetry(
      async () => {
        try {
          this.logger.debug('Fetching available courses from API');

          const response = await this.authenticatedGet(config.api.endpoints.courses);

          // Validate response structure
          if (!response) {
            const error = new Error('No response received from courses API');
            error.noRetry = true;
            throw error;
          }

          if (!response.items) {
            this.logger.warn('No items array in courses response', {
              responseKeys: Object.keys(response)
            });
            
            // Return empty array as fallback
            return [];
          }

          if (!Array.isArray(response.items)) {
            const error = new Error('Invalid courses data format - items not array');
            error.noRetry = true;
            throw error;
          }

          // Process and validate course data
          const validCourses = [];
          const processingErrors = [];

          response.items.forEach((item, index) => {
            try {
              // Validate course item structure
              if (!item || typeof item !== 'object') {
                processingErrors.push(`Item ${index}: Invalid item structure`);
                return;
              }

              if (!item.course_code || typeof item.course_code !== 'string') {
                processingErrors.push(`Item ${index}: Missing or invalid course_code`);
                return;
              }

              if (!item.course_name || typeof item.course_name !== 'string') {
                processingErrors.push(`Item ${index}: Missing or invalid course_name`);
                return;
              }

              const courseCode = item.course_code.trim().toUpperCase();
              const courseName = item.course_name.trim();

              // Validate course code format (should be 3 letters)
              if (!/^[A-Z]{3}$/.test(courseCode)) {
                processingErrors.push(`Item ${index}: Invalid course code format: ${courseCode}`);
                return;
              }

              const courseData = {
                code: courseCode,
                name: courseName,
                difficulty: courseCode.endsWith('H') ? 'Hard' : 'Easy'
              };

              validCourses.push(courseData);

            } catch (itemError) {
              processingErrors.push(`Item ${index}: ${itemError.message}`);
              this.logger.warn('Error processing individual course item', {
                itemIndex: index,
                item: item,
                error: itemError.message
              });
            }
          });

          // Log processing errors if any
          if (processingErrors.length > 0) {
            this.logger.warn('Errors occurred while processing course data', {
              errorCount: processingErrors.length,
              totalItems: response.items.length,
              errors: processingErrors.slice(0, 5) // Log first 5 errors to avoid spam
            });
          }

          // Sort courses by code for consistent ordering
          validCourses.sort((a, b) => a.code.localeCompare(b.code));

          // Update cache
          this.courseCache.clear();
          validCourses.forEach(course => {
            this.courseCache.set(course.code, course);
          });
          this.courseCacheExpiry = Date.now() + this.courseCacheTimeout;

          this.logger.debug('Courses fetched and cached successfully', {
            totalItems: response.items.length,
            validCourses: validCourses.length,
            processingErrors: processingErrors.length,
            cacheExpiry: new Date(this.courseCacheExpiry).toISOString()
          });

          return validCourses;

        } catch (error) {
          // Enhanced error logging
          this.logger.error('Error fetching available courses', {
            errorMessage: error.message,
            errorCode: error.code,
            httpStatus: error.response?.status,
            httpStatusText: error.response?.statusText,
            responseData: error.response?.data,
            stack: error.stack
          });

          // Provide fallback options when API fails
          if (this.courseCache.size > 0) {
            this.logger.info('API failed, returning stale cached course data', {
              cacheSize: this.courseCache.size,
              cacheAge: Date.now() - (this.courseCacheExpiry - this.courseCacheTimeout)
            });
            return Array.from(this.courseCache.values());
          }

          // If no cache available, return popular courses as fallback
          this.logger.warn('No cached data available, returning fallback course list');
          return this.getFallbackCourses();
        }
      },
      { 
        maxRetries: 2, // Fewer retries for course list as we have fallbacks
        shouldRetry: (error) => {
          // Don't retry on validation errors
          if (error.noRetry) {
            return false;
          }
          
          // Retry on 401 (token expired) after clearing token
          if (error.response?.status === 401) {
            return true;
          }
          
          return this.retryHandler.shouldRetry(error);
        }
      },
      'getAvailableCourses'
    );
  }

  /**
   * Get fallback course list when API is unavailable
   * @returns {Array} Array of popular course objects
   */
  getFallbackCourses() {
    return [
      { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
      { code: 'ALH', name: 'Alfheim Hard', difficulty: 'Hard' },
      { code: 'BBE', name: 'Bogeys Bonnie Easy', difficulty: 'Easy' },
      { code: 'BBH', name: 'Bogeys Bonnie Hard', difficulty: 'Hard' },
      { code: 'CLE', name: 'Cherry Blossom Easy', difficulty: 'Easy' },
      { code: 'CLH', name: 'Cherry Blossom Hard', difficulty: 'Hard' },
      { code: 'EDE', name: 'El Dorado Easy', difficulty: 'Easy' },
      { code: 'EDH', name: 'El Dorado Hard', difficulty: 'Hard' },
      { code: 'GBE', name: 'Gardens of Babylon Easy', difficulty: 'Easy' },
      { code: 'GBH', name: 'Gardens of Babylon Hard', difficulty: 'Hard' }
    ];
  }

  /**
   * Clear course cache (useful for testing or forced refresh)
   */
  clearCourseCache() {
    this.courseCache.clear();
    this.courseCacheExpiry = null;
    this.logger.debug('Course cache cleared');
  }

  /**
   * Get service health status including authentication
   * @returns {Promise<Object>} Service health information
   */
  async getHealthStatus() {
    try {
      const startTime = Date.now();
      const authStatus = await this.getAuthStatus();
      
      // Test authentication with courses endpoint
      const authTest = await this.testAuthentication();
      
      const responseTime = Date.now() - startTime;
      
      return {
        status: authTest.success ? 'healthy' : 'unhealthy',
        responseTime,
        timestamp: new Date().toISOString(),
        authentication: {
          ...authStatus,
          testResult: authTest
        },
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
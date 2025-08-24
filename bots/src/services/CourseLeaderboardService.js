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
   * Format leaderboard data for display, identifying user scores and handling approval status
   * @param {Object} apiResponse - Raw API response from getCourseLeaderboard
   * @param {string} userId - Discord user ID to identify user's scores
   * @returns {Object} Formatted leaderboard data with user context
   */
  formatLeaderboardData(apiResponse, userId) {
    try {
      // Validate input parameters
      if (!apiResponse || typeof apiResponse !== 'object') {
        throw new Error('API response is required and must be an object');
      }

      if (!userId || typeof userId !== 'string') {
        throw new Error('User ID is required and must be a string');
      }

      // Extract course information
      const courseInfo = {
        code: apiResponse.courseCode || 'UNKNOWN',
        name: this.getCourseNameFromCode(apiResponse.courseCode),
        difficulty: this.getCourseDifficulty(apiResponse.courseCode)
      };

      // Handle empty leaderboard
      if (!apiResponse.items || !Array.isArray(apiResponse.items) || apiResponse.items.length === 0) {
        this.logger.debug('No leaderboard entries found', {
          courseCode: courseInfo.code,
          userId: userId
        });

        return {
          course: courseInfo,
          entries: [],
          totalEntries: 0,
          userEntries: [],
          hasUserScores: false,
          lastUpdated: new Date()
        };
      }

      // Process leaderboard entries
      const processedEntries = [];
      const userEntries = [];
      let hasUserScores = false;

      apiResponse.items.forEach((item, index) => {
        try {
          // Validate entry structure
          if (!item || typeof item !== 'object') {
            this.logger.warn('Invalid leaderboard entry structure', {
              courseCode: courseInfo.code,
              entryIndex: index,
              entry: item
            });
            return;
          }

          // Ensure required fields exist
          const pos = typeof item.pos === 'number' ? item.pos : index + 1;
          const playerName = typeof item.player_name === 'string' ? item.player_name.trim() : 'Unknown Player';
          const score = typeof item.score === 'number' ? item.score : 0;
          const discordId = item.discord_id ? String(item.discord_id) : null;
          const isApproved = Boolean(item.isApproved);

          // Create processed entry
          const processedEntry = {
            position: pos,
            playerName: playerName,
            score: score,
            discordId: discordId,
            isApproved: isApproved,
            isCurrentUser: discordId === userId
          };

          processedEntries.push(processedEntry);

          // Track user entries
          if (processedEntry.isCurrentUser) {
            userEntries.push(processedEntry);
            hasUserScores = true;
          }

        } catch (entryError) {
          this.logger.warn('Error processing leaderboard entry', {
            courseCode: courseInfo.code,
            entryIndex: index,
            entry: item,
            error: entryError.message
          });
        }
      });

      // Sort entries by position (should already be sorted from API, but ensure consistency)
      processedEntries.sort((a, b) => a.position - b.position);

      // Log processing results
      this.logger.debug('Leaderboard data formatted successfully', {
        courseCode: courseInfo.code,
        totalEntries: processedEntries.length,
        userEntries: userEntries.length,
        hasUserScores: hasUserScores,
        userId: userId
      });

      return {
        course: courseInfo,
        entries: processedEntries,
        totalEntries: apiResponse.count || processedEntries.length,
        userEntries: userEntries,
        hasUserScores: hasUserScores,
        lastUpdated: new Date()
      };

    } catch (error) {
      this.logger.error('Error formatting leaderboard data', {
        userId: userId,
        apiResponse: apiResponse,
        error: error.message,
        stack: error.stack
      });

      // Return safe fallback structure
      return {
        course: {
          code: apiResponse?.courseCode || 'UNKNOWN',
          name: 'Unknown Course',
          difficulty: 'Unknown'
        },
        entries: [],
        totalEntries: 0,
        userEntries: [],
        hasUserScores: false,
        lastUpdated: new Date(),
        error: error.message
      };
    }
  }

  /**
   * Get course name from course code using cache or fallback
   * @param {string} courseCode - 3-letter course code
   * @returns {string} Course name
   */
  getCourseNameFromCode(courseCode) {
    if (!courseCode || typeof courseCode !== 'string') {
      return 'Unknown Course';
    }

    const normalizedCode = courseCode.trim().toUpperCase();

    // Check cache first
    if (this.courseCache.has(normalizedCode)) {
      return this.courseCache.get(normalizedCode).name;
    }

    // Check fallback courses
    const fallbackCourses = this.getFallbackCourses();
    const fallbackCourse = fallbackCourses.find(course => course.code === normalizedCode);
    if (fallbackCourse) {
      return fallbackCourse.name;
    }

    // Generate name from code as last resort
    const difficulty = normalizedCode.endsWith('H') ? 'Hard' : 'Easy';
    const baseCode = normalizedCode.substring(0, 2);
    return `${baseCode} ${difficulty}`;
  }

  /**
   * Get course difficulty from course code
   * @param {string} courseCode - 3-letter course code
   * @returns {string} Course difficulty ('Easy' or 'Hard')
   */
  getCourseDifficulty(courseCode) {
    if (!courseCode || typeof courseCode !== 'string') {
      return 'Unknown';
    }

    return courseCode.trim().toUpperCase().endsWith('H') ? 'Hard' : 'Easy';
  }

  /**
   * Create Discord embed for leaderboard display with user highlighting
   * @param {Object} leaderboardData - Formatted leaderboard data from formatLeaderboardData
   * @param {Object} courseInfo - Course information (optional, will use data from leaderboardData if not provided)
   * @returns {Object} Discord embed object
   */
  createLeaderboardEmbed(leaderboardData, courseInfo = null) {
    try {
      // Validate input
      if (!leaderboardData || typeof leaderboardData !== 'object') {
        throw new Error('Leaderboard data is required and must be an object');
      }

      // Use provided courseInfo or extract from leaderboardData
      const course = courseInfo || leaderboardData.course;
      if (!course) {
        throw new Error('Course information is required');
      }

      // Create embed structure
      const embed = {
        color: 0x00AE86, // Consistent bot theme color
        title: `🏆 ${course.name} Leaderboard`,
        description: `**Course:** ${course.code} (${course.difficulty})\n**Total Scores:** ${leaderboardData.totalEntries}`,
        fields: [],
        footer: {
          text: `Last updated: ${leaderboardData.lastUpdated.toLocaleString()}`
        },
        timestamp: leaderboardData.lastUpdated.toISOString()
      };

      // Handle empty leaderboard
      if (!leaderboardData.entries || leaderboardData.entries.length === 0) {
        embed.fields.push({
          name: '📊 Leaderboard',
          value: 'No scores recorded for this course yet. Be the first to play!',
          inline: false
        });
        return embed;
      }

      // Limit to top 10 entries for readability (as per requirements)
      const displayEntries = leaderboardData.entries.slice(0, 10);

      // Format leaderboard entries
      const leaderboardLines = [];

      displayEntries.forEach((entry, index) => {
        let line = '';

        // Add position indicators for top 3
        if (entry.position === 1) {
          line += '🥇 ';
        } else if (entry.position === 2) {
          line += '🥈 ';
        } else if (entry.position === 3) {
          line += '🥉 ';
        } else {
          line += `${entry.position}. `;
        }

        // Add user highlighting markers
        if (entry.isCurrentUser) {
          if (entry.isApproved) {
            line += '➤ '; // Approved user score marker
          } else {
            line += '📝 '; // Personal/unapproved score marker
          }
        }

        // Add player name
        line += entry.playerName;

        // Add score (negative values indicate under par)
        const scoreDisplay = entry.score >= 0 ? `+${entry.score}` : `${entry.score}`;
        line += ` - (${scoreDisplay})`;

        // Add user identification and approval status
        if (entry.isCurrentUser) {
          line += ' ⭐ **[YOU]**';
          if (!entry.isApproved) {
            line += ' **[PERSONAL]**';
          }
        } else if (!entry.isApproved) {
          line += ' [PERSONAL]';
        }

        leaderboardLines.push(line);
      });

      // Add leaderboard field
      embed.fields.push({
        name: '📊 Top Scores',
        value: leaderboardLines.join('\n'),
        inline: false
      });

      // Add user summary if user has scores
      if (leaderboardData.hasUserScores && leaderboardData.userEntries.length > 0) {
        const userSummaryLines = [];

        leaderboardData.userEntries.forEach(userEntry => {
          const scoreDisplay = userEntry.score >= 0 ? `+${userEntry.score}` : `${userEntry.score}`;
          const statusText = userEntry.isApproved ? 'Approved' : 'Personal';
          userSummaryLines.push(`Position ${userEntry.position}: ${scoreDisplay} (${statusText})`);
        });

        embed.fields.push({
          name: '🎯 Your Scores',
          value: userSummaryLines.join('\n'),
          inline: false
        });
      }

      // Add legend if there are personal scores
      const hasPersonalScores = leaderboardData.entries.some(entry => !entry.isApproved);
      if (hasPersonalScores) {
        embed.fields.push({
          name: '📋 Legend',
          value: '🥇🥈🥉 Top 3 positions\n➤ Your approved score\n📝 Personal (unapproved) scores\n⭐ **[YOU]** Your score',
          inline: false
        });
      }

      this.logger.debug('Discord embed created successfully', {
        courseCode: course.code,
        entriesDisplayed: displayEntries.length,
        totalEntries: leaderboardData.totalEntries,
        hasUserScores: leaderboardData.hasUserScores,
        hasPersonalScores: hasPersonalScores
      });

      return embed;

    } catch (error) {
      this.logger.error('Error creating Discord embed', {
        leaderboardData: leaderboardData,
        courseInfo: courseInfo,
        error: error.message,
        stack: error.stack
      });

      // Return error embed
      return {
        color: 0xFF0000, // Red color for error
        title: '❌ Error Creating Leaderboard',
        description: 'An error occurred while formatting the leaderboard data.',
        fields: [{
          name: 'Error Details',
          value: error.message,
          inline: false
        }],
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * Create fallback text display for leaderboard when embeds fail
   * @param {Object} leaderboardData - Formatted leaderboard data from formatLeaderboardData
   * @param {Object} courseInfo - Course information (optional, will use data from leaderboardData if not provided)
   * @returns {string} Formatted text display with proper Discord character limit handling
   */
  createTextDisplay(leaderboardData, courseInfo = null) {
    try {
      // Validate input
      if (!leaderboardData || typeof leaderboardData !== 'object') {
        throw new Error('Leaderboard data is required and must be an object');
      }

      // Use provided courseInfo or extract from leaderboardData
      const course = courseInfo || leaderboardData.course;
      if (!course) {
        throw new Error('Course information is required');
      }

      // Start building text display
      let textDisplay = '';

      // Header
      textDisplay += `🏆 **${course.name} Leaderboard**\n`;
      textDisplay += `Course: ${course.code} (${course.difficulty}) | Total Scores: ${leaderboardData.totalEntries}\n`;
      textDisplay += `Last updated: ${leaderboardData.lastUpdated.toLocaleString()}\n\n`;

      // Handle empty leaderboard
      if (!leaderboardData.entries || leaderboardData.entries.length === 0) {
        textDisplay += '📊 **Leaderboard**\n';
        textDisplay += 'No scores recorded for this course yet. Be the first to play!\n';
        return this.truncateTextDisplay(textDisplay);
      }

      // Limit to top 10 entries for readability
      const displayEntries = leaderboardData.entries.slice(0, 10);

      // Leaderboard section
      textDisplay += '📊 **Top Scores**\n';

      displayEntries.forEach((entry, index) => {
        let line = '';

        // Add position indicators for top 3
        if (entry.position === 1) {
          line += '🥇 ';
        } else if (entry.position === 2) {
          line += '🥈 ';
        } else if (entry.position === 3) {
          line += '🥉 ';
        } else {
          line += `${entry.position}. `;
        }

        // Add user highlighting markers
        if (entry.isCurrentUser) {
          if (entry.isApproved) {
            line += '➤ '; // Approved user score marker
          } else {
            line += '📝 '; // Personal/unapproved score marker
          }
        }

        // Add player name (truncate if too long)
        const maxNameLength = 20;
        let playerName = entry.playerName;
        if (playerName.length > maxNameLength) {
          playerName = playerName.substring(0, maxNameLength - 3) + '...';
        }
        line += playerName;

        // Add score (negative values indicate under par)
        const scoreDisplay = entry.score >= 0 ? `+${entry.score}` : `${entry.score}`;
        line += ` - (${scoreDisplay})`;

        // Add user identification and approval status
        if (entry.isCurrentUser) {
          line += ' ⭐ **[YOU]**';
          if (!entry.isApproved) {
            line += ' **[PERSONAL]**';
          }
        } else if (!entry.isApproved) {
          line += ' [PERSONAL]';
        }

        textDisplay += line + '\n';
      });

      // Add user summary if user has scores
      if (leaderboardData.hasUserScores && leaderboardData.userEntries.length > 0) {
        textDisplay += '\n🎯 **Your Scores**\n';

        leaderboardData.userEntries.forEach(userEntry => {
          const scoreDisplay = userEntry.score >= 0 ? `+${userEntry.score}` : `${userEntry.score}`;
          const statusText = userEntry.isApproved ? 'Approved' : 'Personal';
          textDisplay += `Position ${userEntry.position}: ${scoreDisplay} (${statusText})\n`;
        });
      }

      // Add legend if there are personal scores
      const hasPersonalScores = leaderboardData.entries.some(entry => !entry.isApproved);
      if (hasPersonalScores) {
        textDisplay += '\n📋 **Legend**\n';
        textDisplay += '🥇🥈🥉 Top 3 positions | ➤ Your approved score\n';
        textDisplay += '📝 Personal (unapproved) scores | ⭐ **[YOU]** Your score\n';
      }

      this.logger.debug('Text display created successfully', {
        courseCode: course.code,
        entriesDisplayed: displayEntries.length,
        totalEntries: leaderboardData.totalEntries,
        hasUserScores: leaderboardData.hasUserScores,
        hasPersonalScores: hasPersonalScores,
        textLength: textDisplay.length
      });

      return this.truncateTextDisplay(textDisplay);

    } catch (error) {
      this.logger.error('Error creating text display', {
        leaderboardData: leaderboardData,
        courseInfo: courseInfo,
        error: error.message,
        stack: error.stack
      });

      // Return error text
      return `❌ **Error Creating Leaderboard**\nAn error occurred while formatting the leaderboard data.\n\nError: ${error.message}`;
    }
  }

  /**
   * Truncate text display to fit Discord character limits
   * @param {string} text - Text to truncate
   * @returns {string} Truncated text that fits Discord limits
   */
  truncateTextDisplay(text) {
    const maxLength = 2000; // Discord message character limit

    if (text.length <= maxLength) {
      return text;
    }

    // Find a good truncation point (preferably at a line break)
    const truncateAt = maxLength - 100; // Leave some buffer
    let truncationPoint = text.lastIndexOf('\n', truncateAt);

    if (truncationPoint === -1 || truncationPoint < truncateAt - 200) {
      // If no good line break found, truncate at word boundary
      truncationPoint = text.lastIndexOf(' ', truncateAt);
    }

    if (truncationPoint === -1) {
      // Last resort: hard truncate
      truncationPoint = truncateAt;
    }

    const truncatedText = text.substring(0, truncationPoint);
    const remainingEntries = text.substring(truncationPoint).split('\n').filter(line => line.trim()).length;

    return truncatedText + `\n\n... and ${remainingEntries} more entries (message truncated due to length)`;
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
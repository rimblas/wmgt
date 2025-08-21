import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import axios from 'axios';
import { VotesService } from '../services/VotesService.js';
import { config } from '../config/config.js';

// Mock axios
vi.mock('axios');
const mockedAxios = vi.mocked(axios);

describe('VotesService', () => {
  let votesService;
  let mockAxiosInstance;

  beforeEach(() => {
    // Reset all mocks
    vi.clearAllMocks();
    
    // Create mock axios instance
    mockAxiosInstance = {
      get: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() }
      }
    };
    
    mockedAxios.create.mockReturnValue(mockAxiosInstance);
    
    votesService = new VotesService();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('constructor', () => {
    it('should create axios client with correct configuration', () => {
      expect(mockedAxios.create).toHaveBeenCalledWith({
        baseURL: config.api.baseUrl,
        timeout: 15000,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    });

    it('should set up request and response interceptors', () => {
      expect(mockAxiosInstance.interceptors.request.use).toHaveBeenCalled();
      expect(mockAxiosInstance.interceptors.response.use).toHaveBeenCalled();
    });
  });

  describe('getVotingResults', () => {
    it('should fetch voting data successfully', async () => {
      const mockResponse = {
        data: {
          items: [
            {
              easy_vote_order: 1,
              hard_vote_order: 1,
              easy_votes: 5,
              easy_votes_top: 'Y',
              easy_course: 'ALE',
              easy_name: 'Alfheim Easy',
              hard_course: 'ALH',
              hard_name: 'Alfheim Hard',
              hard_votes: 3,
              hard_votes_top: null
            }
          ],
          hasMore: false,
          limit: 25,
          offset: 0,
          count: 1
        }
      };

      mockAxiosInstance.get.mockResolvedValue(mockResponse);

      const result = await votesService.getVotingResults();

      expect(mockAxiosInstance.get).toHaveBeenCalledWith(config.api.endpoints.votes);
      expect(result).toEqual(mockResponse.data);
    });

    it('should throw error when no data received', async () => {
      mockAxiosInstance.get.mockResolvedValue({ data: null });

      await expect(votesService.getVotingResults()).rejects.toThrow('No voting data received from API');
    });

    it('should throw error when items array is missing', async () => {
      mockAxiosInstance.get.mockResolvedValue({ 
        data: { 
          hasMore: false,
          count: 0
        } 
      });

      await expect(votesService.getVotingResults()).rejects.toThrow('Invalid voting data format received from API');
    });

    it('should throw error when items is not an array', async () => {
      mockAxiosInstance.get.mockResolvedValue({ 
        data: { 
          items: 'not an array',
          hasMore: false,
          count: 0
        } 
      });

      await expect(votesService.getVotingResults()).rejects.toThrow('Invalid voting data format received from API');
    });
  });

  describe('getHealthStatus', () => {
    it('should return healthy status when API is working', async () => {
      const mockResponse = {
        data: {
          items: [],
          hasMore: false,
          count: 0
        }
      };

      mockAxiosInstance.get.mockResolvedValue(mockResponse);

      const healthStatus = await votesService.getHealthStatus();

      expect(healthStatus.status).toBe('healthy');
      expect(healthStatus.responseTime).toBeGreaterThanOrEqual(0);
      expect(healthStatus.timestamp).toBeDefined();
      expect(healthStatus.circuitBreaker).toBeDefined();
    });

    it('should return unhealthy status when API fails', async () => {
      const error = new Error('API Error');
      mockAxiosInstance.get.mockRejectedValue(error);

      const healthStatus = await votesService.getHealthStatus();

      expect(healthStatus.status).toBe('unhealthy');
      expect(healthStatus.error).toBe('API Error');
      expect(healthStatus.timestamp).toBeDefined();
      expect(healthStatus.circuitBreaker).toBeDefined();
    });
  });

  describe('handleApiError', () => {
    it('should process API errors with user-friendly messages', () => {
      const originalError = new Error('Network error');
      originalError.code = 'ECONNREFUSED';

      const processedError = votesService.handleApiError(originalError, 'test_context');

      expect(processedError).toBeInstanceOf(Error);
      expect(processedError.originalError).toBe(originalError);
      expect(processedError.errorId).toBeDefined();
      expect(processedError.errorType).toBeDefined();
    });
  });

  describe('formatVotingData', () => {
    it('should parse API response and extract course data correctly', () => {
      const apiResponse = {
        items: [
          {
            easy_vote_order: 1,
            hard_vote_order: 2,
            easy_votes: 5,
            easy_votes_top: 'Y',
            easy_course: 'ALE',
            easy_name: 'Alfheim Easy',
            hard_course: 'ALH',
            hard_name: 'Alfheim Hard',
            hard_votes: 3,
            hard_votes_top: null
          },
          {
            easy_vote_order: 2,
            hard_vote_order: 1,
            easy_votes: 2,
            easy_votes_top: null,
            easy_course: 'BBE',
            easy_name: 'Bogey Bayou Easy',
            hard_course: 'BBH',
            hard_name: 'Bogey Bayou Hard',
            hard_votes: 7,
            hard_votes_top: 'Y'
          }
        ]
      };

      const result = votesService.formatVotingData(apiResponse);

      expect(result.easyCourses).toHaveLength(2);
      expect(result.hardCourses).toHaveLength(2);
      
      // Check easy courses
      expect(result.easyCourses[0]).toEqual({
        code: 'ALE',
        name: 'Alfheim Easy',
        votes: 5,
        isTop: true,
        order: 1
      });
      
      expect(result.easyCourses[1]).toEqual({
        code: 'BBE',
        name: 'Bogey Bayou Easy',
        votes: 2,
        isTop: false,
        order: 2
      });

      // Check hard courses (should be sorted by order)
      expect(result.hardCourses[0]).toEqual({
        code: 'BBH',
        name: 'Bogey Bayou Hard',
        votes: 7,
        isTop: true,
        order: 1
      });
      
      expect(result.hardCourses[1]).toEqual({
        code: 'ALH',
        name: 'Alfheim Hard',
        votes: 3,
        isTop: false,
        order: 2
      });
    });

    it('should handle null hard courses gracefully', () => {
      const apiResponse = {
        items: [
          {
            easy_vote_order: 1,
            easy_votes: 5,
            easy_votes_top: 'Y',
            easy_course: 'ALE',
            easy_name: 'Alfheim Easy',
            hard_course: null,
            hard_name: null,
            hard_votes: null,
            hard_votes_top: null
          }
        ]
      };

      const result = votesService.formatVotingData(apiResponse);

      expect(result.easyCourses).toHaveLength(1);
      expect(result.hardCourses).toHaveLength(0);
      expect(result.easyCourses[0].code).toBe('ALE');
    });

    it('should handle zero and negative votes correctly', () => {
      const apiResponse = {
        items: [
          {
            easy_vote_order: 1,
            easy_votes: 0,
            easy_votes_top: null,
            easy_course: 'ZER',
            easy_name: 'Zero Votes Course',
            hard_course: 'NEG',
            hard_name: 'Negative Votes Course',
            hard_votes: -2,
            hard_votes_top: null
          }
        ]
      };

      const result = votesService.formatVotingData(apiResponse);

      expect(result.easyCourses[0].votes).toBe(0);
      expect(result.hardCourses[0].votes).toBe(-2);
    });

    it('should handle missing vote data with defaults', () => {
      const apiResponse = {
        items: [
          {
            easy_course: 'DEF',
            easy_name: 'Default Course',
            // Missing votes and order fields
          }
        ]
      };

      const result = votesService.formatVotingData(apiResponse);

      expect(result.easyCourses[0]).toEqual({
        code: 'DEF',
        name: 'Default Course',
        votes: 0,
        isTop: false,
        order: 0
      });
    });

    it('should throw errors for invalid input', () => {
      expect(() => votesService.formatVotingData(null)).toThrow('No voting data provided for formatting');
      expect(() => votesService.formatVotingData({})).toThrow('Invalid voting data format - missing items');
      expect(() => votesService.formatVotingData({ items: null })).toThrow('Invalid voting data format - missing items');
    });
  });

  describe('formatCoursesForDisplay', () => {
    it('should format courses with vote counts and top indicators', () => {
      const courses = [
        {
          code: 'ALE',
          name: 'Alfheim Easy',
          votes: 5,
          isTop: true,
          order: 1
        },
        {
          code: 'BBE',
          name: 'Bogey Bayou Easy',
          votes: 2,
          isTop: false,
          order: 2
        }
      ];

      const result = votesService.formatCoursesForDisplay(courses);

      expect(result).toBe('🏆 **ALE** (5) - Alfheim Easy\n**BBE** (2) - Bogey Bayou Easy');
    });

    it('should handle zero and negative votes display', () => {
      const courses = [
        {
          code: 'ZER',
          name: 'Zero Course',
          votes: 0,
          isTop: false,
          order: 1
        },
        {
          code: 'NEG',
          name: 'Negative Course',
          votes: -3,
          isTop: false,
          order: 2
        }
      ];

      const result = votesService.formatCoursesForDisplay(courses);

      expect(result).toBe('**ZER** (0) - Zero Course\n**NEG** (-3) - Negative Course');
    });

    it('should return "No courses available" for empty array', () => {
      expect(votesService.formatCoursesForDisplay([])).toBe('No courses available');
      expect(votesService.formatCoursesForDisplay(null)).toBe('No courses available');
    });

    it('should truncate long strings that exceed Discord limits', () => {
      // Create multiple courses with long names to exceed 1024 character limit
      const longName = 'A'.repeat(200);
      const courses = [];
      
      // Create enough courses to exceed the 1024 character limit
      for (let i = 0; i < 10; i++) {
        courses.push({
          code: `LONG${i}`,
          name: longName,
          votes: i,
          isTop: false,
          order: i
        });
      }

      const result = votesService.formatCoursesForDisplay(courses);

      expect(result.length).toBeLessThanOrEqual(1024);
      expect(result).toContain('*... and more courses*');
    });
  });

  describe('splitIntoColumns', () => {
    it('should split formatted data into easy and hard columns', () => {
      const formattedData = {
        easyCourses: [
          {
            code: 'ALE',
            name: 'Alfheim Easy',
            votes: 5,
            isTop: true,
            order: 1
          }
        ],
        hardCourses: [
          {
            code: 'ALH',
            name: 'Alfheim Hard',
            votes: 3,
            isTop: false,
            order: 1
          }
        ]
      };

      const result = votesService.splitIntoColumns(formattedData);

      expect(result.easyColumn).toBe('🏆 **ALE** (5) - Alfheim Easy');
      expect(result.hardColumn).toBe('**ALH** (3) - Alfheim Hard');
    });

    it('should handle empty courses arrays', () => {
      const formattedData = {
        easyCourses: [],
        hardCourses: []
      };

      const result = votesService.splitIntoColumns(formattedData);

      expect(result.easyColumn).toBe('No courses available');
      expect(result.hardColumn).toBe('No courses available');
    });
  });

  describe('createVotesEmbed', () => {
    it('should create complete Discord embed structure', () => {
      const apiResponse = {
        items: [
          {
            easy_vote_order: 1,
            easy_votes: 5,
            easy_votes_top: 'Y',
            easy_course: 'ALE',
            easy_name: 'Alfheim Easy',
            hard_course: 'ALH',
            hard_name: 'Alfheim Hard',
            hard_votes: 3,
            hard_votes_top: null
          }
        ]
      };

      const result = votesService.createVotesEmbed(apiResponse);

      expect(result.title).toBe('🏆 Course Voting Results');
      expect(result.color).toBe(0x00AE86);
      expect(result.fields).toHaveLength(2);
      
      expect(result.fields[0]).toEqual({
        name: 'Easy Courses',
        value: '🏆 **ALE** (5) - Alfheim Easy',
        inline: true
      });
      
      expect(result.fields[1]).toEqual({
        name: 'Hard Courses',
        value: '**ALH** (3) - Alfheim Hard',
        inline: true
      });

      expect(result.footer.text).toBe('Vote counts updated in real-time');
      expect(result.timestamp).toBeDefined();
    });

    it('should handle empty API response', () => {
      const apiResponse = { items: [] };

      const result = votesService.createVotesEmbed(apiResponse);

      expect(result.fields[0].value).toBe('No courses available');
      expect(result.fields[1].value).toBe('No courses available');
    });
  });

  describe('createTextDisplay', () => {
    it('should create text-based display as fallback', () => {
      const apiResponse = {
        items: [
          {
            easy_vote_order: 1,
            easy_votes: 5,
            easy_votes_top: 'Y',
            easy_course: 'ALE',
            easy_name: 'Alfheim Easy',
            hard_course: 'ALH',
            hard_name: 'Alfheim Hard',
            hard_votes: 3,
            hard_votes_top: null
          }
        ]
      };

      const result = votesService.createTextDisplay(apiResponse);

      expect(result).toContain('🏆 **Course Voting Results**');
      expect(result).toContain('**Easy Courses:**');
      expect(result).toContain('🏆 **ALE** (5) - Alfheim Easy');
      expect(result).toContain('**Hard Courses:**');
      expect(result).toContain('**ALH** (3) - Alfheim Hard');
      expect(result).toContain('*Vote counts updated in real-time*');
    });

    it('should handle empty courses in text display', () => {
      const apiResponse = { items: [] };

      const result = votesService.createTextDisplay(apiResponse);

      expect(result).toContain('No easy courses available');
      expect(result).toContain('No hard courses available');
    });

    it('should truncate text display if too long', () => {
      // Create a response with many courses to exceed character limit
      const items = [];
      for (let i = 0; i < 50; i++) {
        items.push({
          easy_vote_order: i,
          easy_votes: i,
          easy_course: `COURSE${i}`,
          easy_name: `Very Long Course Name That Takes Up Space ${i}`.repeat(3),
          hard_course: `HARD${i}`,
          hard_name: `Very Long Hard Course Name That Takes Up Space ${i}`.repeat(3),
          hard_votes: i
        });
      }

      const result = votesService.createTextDisplay({ items });

      expect(result.length).toBeLessThanOrEqual(1950); // Allow some buffer for the truncation message
      expect(result).toContain('*... and more courses*');
    });

    it('should return error message when processing fails', () => {
      // Mock formatVotingData to throw an error
      const originalFormatVotingData = votesService.formatVotingData;
      votesService.formatVotingData = vi.fn().mockImplementation(() => {
        throw new Error('Processing failed');
      });

      const result = votesService.createTextDisplay({ items: [] });

      expect(result).toContain('❌ **Voting Results Unavailable**');
      expect(result).toContain('Unable to process voting data for display');

      // Restore original method
      votesService.formatVotingData = originalFormatVotingData;
    });
  });

  describe('Error Handling Scenarios', () => {
    describe('API Unavailability', () => {
      it('should handle connection refused errors', async () => {
        const error = new Error('Connection refused');
        error.code = 'ECONNREFUSED';
        mockAxiosInstance.get.mockRejectedValue(error);

        await expect(votesService.getVotingResults()).rejects.toThrow();
        
        const processedError = votesService.handleApiError(error, 'test');
        expect(processedError.message).toContain('tournament service');
      });

      it('should handle DNS resolution errors', async () => {
        const error = new Error('DNS lookup failed');
        error.code = 'ENOTFOUND';
        mockAxiosInstance.get.mockRejectedValue(error);

        await expect(votesService.getVotingResults()).rejects.toThrow();
        
        const processedError = votesService.handleApiError(error, 'test');
        expect(processedError.message).toContain('tournament service');
      });

      it('should handle timeout errors', async () => {
        const error = new Error('Request timeout');
        error.code = 'ETIMEDOUT';
        mockAxiosInstance.get.mockRejectedValue(error);

        await expect(votesService.getVotingResults()).rejects.toThrow();
        
        const processedError = votesService.handleApiError(error, 'test');
        expect(processedError.message).toContain('took too long');
      });
    });

    describe('HTTP Status Errors', () => {
      it('should handle 429 rate limiting', async () => {
        const error = new Error('Rate limited');
        error.response = { 
          status: 429,
          statusText: 'Too Many Requests',
          headers: { 'retry-after': '60' }
        };
        mockAxiosInstance.get.mockRejectedValue(error);

        await expect(votesService.getVotingResults()).rejects.toThrow();
        
        const processedError = votesService.handleApiError(error, 'test');
        expect(processedError.retryAfter).toBeDefined();
      });

      it('should handle 500 server errors', async () => {
        const error = new Error('Internal server error');
        error.response = { 
          status: 500,
          statusText: 'Internal Server Error'
        };
        mockAxiosInstance.get.mockRejectedValue(error);

        await expect(votesService.getVotingResults()).rejects.toThrow();
        
        const processedError = votesService.handleApiError(error, 'test');
        expect(processedError.message).toContain('unavailable');
      });

      it('should handle 404 not found errors', async () => {
        const error = new Error('Not found');
        error.response = { 
          status: 404,
          statusText: 'Not Found'
        };
        mockAxiosInstance.get.mockRejectedValue(error);

        await expect(votesService.getVotingResults()).rejects.toThrow();
        
        const processedError = votesService.handleApiError(error, 'test');
        expect(processedError.message).toContain('could not be found');
      });
    });

    describe('Malformed Response Handling', () => {
      it('should handle null response', async () => {
        mockAxiosInstance.get.mockResolvedValue(null);

        await expect(votesService.getVotingResults()).rejects.toThrow('No response received');
      });

      it('should handle response with wrong data type', async () => {
        mockAxiosInstance.get.mockResolvedValue({ data: 'invalid string' });

        await expect(votesService.getVotingResults()).rejects.toThrow('Invalid voting data format');
      });

      it('should handle response with invalid items structure', async () => {
        mockAxiosInstance.get.mockResolvedValue({ 
          data: { items: { notAnArray: true } }
        });

        await expect(votesService.getVotingResults()).rejects.toThrow('items not array');
      });
    });

    describe('Data Processing Error Handling', () => {
      it('should handle invalid vote count types', () => {
        expect(votesService.validateVoteCount('invalid', 'test')).toBe(0);
        expect(votesService.validateVoteCount(NaN, 'test')).toBe(0);
        expect(votesService.validateVoteCount(Infinity, 'test')).toBe(0);
        expect(votesService.validateVoteCount({}, 'test')).toBe(0);
      });

      it('should handle invalid order types', () => {
        expect(votesService.validateOrder('invalid', 'test')).toBe(0);
        expect(votesService.validateOrder(NaN, 'test')).toBe(0);
        expect(votesService.validateOrder(Infinity, 'test')).toBe(0);
        expect(votesService.validateOrder([], 'test')).toBe(0);
      });

      it('should handle malformed course items gracefully', () => {
        const apiResponse = {
          items: [
            null, // null item
            'invalid', // string instead of object
            {}, // empty object
            { easy_course: 'ALE' }, // missing name
            { easy_name: 'Alfheim' }, // missing code
            {
              easy_course: 123, // wrong type
              easy_name: ['array'], // wrong type
              easy_votes: 'invalid'
            }
          ]
        };

        const result = votesService.formatVotingData(apiResponse);
        
        // Should return empty arrays since no valid courses
        expect(result.easyCourses).toHaveLength(0);
        expect(result.hardCourses).toHaveLength(0);
      });

      it('should handle mixed valid and invalid items', () => {
        const apiResponse = {
          items: [
            {
              easy_vote_order: 1,
              easy_votes: 5,
              easy_course: 'ALE',
              easy_name: 'Alfheim Easy'
            },
            null, // invalid item
            {
              easy_vote_order: 2,
              easy_votes: 3,
              easy_course: 'BBE',
              easy_name: 'Bogey Bayou Easy'
            }
          ]
        };

        const result = votesService.formatVotingData(apiResponse);
        
        // Should process valid items and skip invalid ones
        expect(result.easyCourses).toHaveLength(2);
        expect(result.easyCourses[0].code).toBe('ALE');
        expect(result.easyCourses[1].code).toBe('BBE');
      });
    });

    describe('Graceful Degradation', () => {
      it('should throw error when all processing fails', () => {
        expect(() => votesService.formatVotingData(null)).toThrow('No voting data provided for formatting');
      });

      it('should handle formatVotingData throwing errors', () => {
        expect(() => {
          votesService.formatVotingData({ items: 'invalid' });
        }).toThrow('Invalid voting data format');
      });

      it('should provide fallback text when embed creation fails', () => {
        const apiResponse = { items: [] };
        const textDisplay = votesService.createTextDisplay(apiResponse);
        
        expect(textDisplay).toContain('Course Voting Results');
        expect(textDisplay).toContain('No easy courses available');
        expect(textDisplay).toContain('No hard courses available');
      });
    });
  });
});
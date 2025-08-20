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
});
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { CourseLeaderboardService } from '../services/CourseLeaderboardService.js';
import { config } from '../config/config.js';

describe('CourseLeaderboardService', () => {
  let service;

  beforeEach(() => {
    service = new CourseLeaderboardService();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('Constructor', () => {
    it('should create service instance with correct properties', () => {
      expect(service).toBeInstanceOf(CourseLeaderboardService);
      expect(service.serviceName).toBe('CourseLeaderboardService');
      expect(service.courseCache).toBeInstanceOf(Map);
      expect(service.courseCacheExpiry).toBeNull();
      expect(service.courseCacheTimeout).toBe(5 * 60 * 1000);
    });

    it('should inherit from BaseAuthenticatedService', () => {
      expect(service.logger).toBeDefined();
      expect(service.errorHandler).toBeDefined();
      expect(service.retryHandler).toBeDefined();
      expect(service.apiClient).toBeDefined();
    });
  });

  describe('Authentication Methods', () => {
    describe('getAuthToken', () => {
      it('should handle authentication token retrieval', async () => {
        // Mock tokenManager to avoid actual API calls
        const mockTokenManager = {
          getAuthHeader: vi.fn().mockResolvedValue({
            Authorization: 'Bearer test-token-123'
          })
        };
        service.tokenManager = mockTokenManager;

        const token = await service.getAuthToken();
        
        expect(token).toBe('test-token-123');
        expect(mockTokenManager.getAuthHeader).toHaveBeenCalledOnce();
      });

      it('should handle authentication errors', async () => {
        const mockTokenManager = {
          getAuthHeader: vi.fn().mockRejectedValue(new Error('Auth failed'))
        };
        service.tokenManager = mockTokenManager;

        await expect(service.getAuthToken()).rejects.toThrow();
      });
    });

    describe('refreshTokenIfNeeded', () => {
      it('should refresh token when expired', async () => {
        const mockTokenManager = {
          getTokenStatus: vi.fn().mockReturnValue({
            hasToken: true,
            isValid: false,
            timeUntilExpiry: 0
          }),
          clearToken: vi.fn(),
          getAuthHeader: vi.fn().mockResolvedValue({
            Authorization: 'Bearer new-token-456'
          })
        };
        service.tokenManager = mockTokenManager;

        const refreshed = await service.refreshTokenIfNeeded();
        
        expect(refreshed).toBe(true);
        expect(mockTokenManager.clearToken).toHaveBeenCalledOnce();
        expect(mockTokenManager.getAuthHeader).toHaveBeenCalledOnce();
      });

      it('should not refresh valid token', async () => {
        const mockTokenManager = {
          getTokenStatus: vi.fn().mockReturnValue({
            hasToken: true,
            isValid: true,
            timeUntilExpiry: 3600000 // 1 hour
          })
        };
        service.tokenManager = mockTokenManager;

        const refreshed = await service.refreshTokenIfNeeded();
        
        expect(refreshed).toBe(false);
      });
    });
  });

  describe('Course Data Methods', () => {
    describe('getCourseLeaderboard', () => {
      it('should validate required parameters', async () => {
        await expect(service.getCourseLeaderboard()).rejects.toThrow('Course code is required');
        await expect(service.getCourseLeaderboard('ALE')).rejects.toThrow('User ID is required');
        await expect(service.getCourseLeaderboard(123, 'user123')).rejects.toThrow('Course code is required and must be a string');
        await expect(service.getCourseLeaderboard('ALE', 123)).rejects.toThrow('User ID is required and must be a string');
      });

      it('should normalize course code to uppercase', async () => {
        // Mock the authenticatedGet method to avoid actual API calls
        service.authenticatedGet = vi.fn().mockResolvedValue({
          items: [],
          hasMore: false,
          count: 0
        });

        await service.getCourseLeaderboard('ale', 'user123');
        
        expect(service.authenticatedGet).toHaveBeenCalledWith(
          `${config.api.endpoints.leaderboards}/ALE`,
          { discord_id: 'user123' }
        );
      });
    });

    describe('getAvailableCourses', () => {
      it('should return cached courses when available', async () => {
        // Set up cache
        const cachedCourses = [
          { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
          { code: 'BBE', name: 'Bogeys Bonnie Easy', difficulty: 'Easy' }
        ];
        
        cachedCourses.forEach(course => {
          service.courseCache.set(course.code, course);
        });
        service.courseCacheExpiry = Date.now() + 60000; // 1 minute from now

        const courses = await service.getAvailableCourses();
        
        expect(courses).toEqual(cachedCourses);
      });

      it('should return fallback courses when API fails and no cache', async () => {
        // Mock API failure
        service.authenticatedGet = vi.fn().mockRejectedValue(new Error('API unavailable'));

        const courses = await service.getAvailableCourses();
        
        expect(courses).toEqual(service.getFallbackCourses());
        expect(courses.length).toBeGreaterThan(0);
        expect(courses[0]).toHaveProperty('code');
        expect(courses[0]).toHaveProperty('name');
        expect(courses[0]).toHaveProperty('difficulty');
      });
    });

    describe('getFallbackCourses', () => {
      it('should return predefined popular courses', () => {
        const fallbackCourses = service.getFallbackCourses();
        
        expect(Array.isArray(fallbackCourses)).toBe(true);
        expect(fallbackCourses.length).toBeGreaterThan(0);
        
        fallbackCourses.forEach(course => {
          expect(course).toHaveProperty('code');
          expect(course).toHaveProperty('name');
          expect(course).toHaveProperty('difficulty');
          expect(['Easy', 'Hard']).toContain(course.difficulty);
        });
      });
    });

    describe('clearCourseCache', () => {
      it('should clear cache and expiry', () => {
        service.courseCache.set('ALE', { code: 'ALE', name: 'Test' });
        service.courseCacheExpiry = Date.now() + 60000;

        service.clearCourseCache();

        expect(service.courseCache.size).toBe(0);
        expect(service.courseCacheExpiry).toBeNull();
      });
    });
  });

  describe('Health Status', () => {
    it('should return health status structure', async () => {
      // Mock dependencies to avoid actual API calls
      service.getAuthStatus = vi.fn().mockResolvedValue({
        hasToken: true,
        isValid: true
      });
      
      service.testAuthentication = vi.fn().mockResolvedValue({
        success: true,
        message: 'Authentication successful'
      });

      service.retryHandler = {
        getCircuitBreakerStatus: vi.fn().mockReturnValue({
          isOpen: false,
          failureCount: 0
        })
      };

      const health = await service.getHealthStatus();

      expect(health).toHaveProperty('status');
      expect(health).toHaveProperty('responseTime');
      expect(health).toHaveProperty('timestamp');
      expect(health).toHaveProperty('authentication');
      expect(health).toHaveProperty('circuitBreaker');
    });
  });
});
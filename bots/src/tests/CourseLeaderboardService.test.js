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

  describe('Data Processing Methods', () => {
    describe('formatLeaderboardData', () => {
      it('should format leaderboard data with user identification', () => {
        const apiResponse = {
          courseCode: 'ALE',
          items: [
            { pos: 1, player_name: 'Player1', score: -22, discord_id: '123', isApproved: true },
            { pos: 2, player_name: 'Player2', score: -21, discord_id: '456', isApproved: true },
            { pos: 3, player_name: 'TestUser', score: -20, discord_id: '789', isApproved: false }
          ],
          count: 3
        };

        const result = service.formatLeaderboardData(apiResponse, '789');

        expect(result.course.code).toBe('ALE');
        expect(result.entries).toHaveLength(3);
        expect(result.hasUserScores).toBe(true);
        expect(result.userEntries).toHaveLength(1);
        expect(result.userEntries[0].playerName).toBe('TestUser');
        expect(result.userEntries[0].isCurrentUser).toBe(true);
        expect(result.userEntries[0].isApproved).toBe(false);
      });

      it('should handle empty leaderboard', () => {
        const apiResponse = {
          courseCode: 'BBE',
          items: [],
          count: 0
        };

        const result = service.formatLeaderboardData(apiResponse, '123');

        expect(result.course.code).toBe('BBE');
        expect(result.entries).toHaveLength(0);
        expect(result.hasUserScores).toBe(false);
        expect(result.userEntries).toHaveLength(0);
      });

      it('should handle invalid input gracefully', () => {
        const result = service.formatLeaderboardData(null, '123');

        expect(result.error).toBeDefined();
        expect(result.entries).toHaveLength(0);
      });

      it('should identify multiple user scores', () => {
        const apiResponse = {
          courseCode: 'CLE',
          items: [
            { pos: 1, player_name: 'TestUser', score: -22, discord_id: '789', isApproved: true },
            { pos: 2, player_name: 'Player2', score: -21, discord_id: '456', isApproved: true },
            { pos: 5, player_name: 'TestUser', score: -18, discord_id: '789', isApproved: false }
          ],
          count: 3
        };

        const result = service.formatLeaderboardData(apiResponse, '789');

        expect(result.hasUserScores).toBe(true);
        expect(result.userEntries).toHaveLength(2);
        expect(result.userEntries[0].isApproved).toBe(true);
        expect(result.userEntries[1].isApproved).toBe(false);
      });
    });

    describe('createLeaderboardEmbed', () => {
      it('should create Discord embed with proper formatting', () => {
        const leaderboardData = {
          course: { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
          entries: [
            { position: 1, playerName: 'Player1', score: -22, isCurrentUser: false, isApproved: true },
            { position: 2, playerName: 'TestUser', score: -21, isCurrentUser: true, isApproved: true },
            { position: 3, playerName: 'Player3', score: -20, isCurrentUser: false, isApproved: false }
          ],
          totalEntries: 3,
          hasUserScores: true,
          userEntries: [{ position: 2, playerName: 'TestUser', score: -21, isApproved: true }],
          lastUpdated: new Date('2024-01-01T12:00:00Z')
        };

        const embed = service.createLeaderboardEmbed(leaderboardData);

        expect(embed.title).toBe('🏆 Alfheim Easy Leaderboard');
        expect(embed.color).toBe(0x00AE86);
        expect(embed.fields).toHaveLength(3); // Top Scores, Your Scores, Legend
        expect(embed.fields[0].name).toBe('📊 Top Scores');
        expect(embed.fields[0].value).toContain('🥇 Player1');
        expect(embed.fields[0].value).toContain('🥈 ➤ TestUser');
        expect(embed.fields[0].value).toContain('⭐ **[YOU]**');
        expect(embed.fields[0].value).toContain('[PERSONAL]');
      });

      it('should handle empty leaderboard in embed', () => {
        const leaderboardData = {
          course: { code: 'BBE', name: 'Bogeys Bonnie Easy', difficulty: 'Easy' },
          entries: [],
          totalEntries: 0,
          hasUserScores: false,
          userEntries: [],
          lastUpdated: new Date()
        };

        const embed = service.createLeaderboardEmbed(leaderboardData);

        expect(embed.title).toBe('🏆 Bogeys Bonnie Easy Leaderboard');
        expect(embed.fields).toHaveLength(1);
        expect(embed.fields[0].value).toContain('No scores recorded');
      });

      it('should limit display to top 10 entries', () => {
        const entries = Array.from({ length: 15 }, (_, i) => ({
          position: i + 1,
          playerName: `Player${i + 1}`,
          score: -20 + i,
          isCurrentUser: false,
          isApproved: true
        }));

        const leaderboardData = {
          course: { code: 'CLE', name: 'Cherry Blossom Easy', difficulty: 'Easy' },
          entries: entries,
          totalEntries: 15,
          hasUserScores: false,
          userEntries: [],
          lastUpdated: new Date()
        };

        const embed = service.createLeaderboardEmbed(leaderboardData);
        const topScoresField = embed.fields.find(f => f.name === '📊 Top Scores');
        const lines = topScoresField.value.split('\n');
        
        expect(lines.length).toBe(10); // Should only show top 10
      });

      it('should handle embed creation errors gracefully', () => {
        const embed = service.createLeaderboardEmbed(null);

        expect(embed.color).toBe(0xFF0000); // Error color
        expect(embed.title).toContain('Error');
      });
    });

    describe('createTextDisplay', () => {
      it('should create formatted text display', () => {
        const leaderboardData = {
          course: { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
          entries: [
            { position: 1, playerName: 'Player1', score: -22, isCurrentUser: false, isApproved: true },
            { position: 2, playerName: 'TestUser', score: -21, isCurrentUser: true, isApproved: true },
            { position: 3, playerName: 'Player3', score: -20, isCurrentUser: false, isApproved: false }
          ],
          totalEntries: 3,
          hasUserScores: true,
          userEntries: [{ position: 2, playerName: 'TestUser', score: -21, isApproved: true }],
          lastUpdated: new Date('2024-01-01T12:00:00Z')
        };

        const text = service.createTextDisplay(leaderboardData);

        expect(text).toContain('🏆 **Alfheim Easy Leaderboard**');
        expect(text).toContain('Course: ALE (Easy)');
        expect(text).toContain('🥇 Player1');
        expect(text).toContain('🥈 ➤ TestUser');
        expect(text).toContain('⭐ **[YOU]**');
        expect(text).toContain('[PERSONAL]');
        expect(text).toContain('🎯 **Your Scores**');
        expect(text).toContain('📋 **Legend**');
      });

      it('should handle empty leaderboard in text display', () => {
        const leaderboardData = {
          course: { code: 'BBE', name: 'Bogeys Bonnie Easy', difficulty: 'Easy' },
          entries: [],
          totalEntries: 0,
          hasUserScores: false,
          userEntries: [],
          lastUpdated: new Date()
        };

        const text = service.createTextDisplay(leaderboardData);

        expect(text).toContain('🏆 **Bogeys Bonnie Easy Leaderboard**');
        expect(text).toContain('No scores recorded');
      });

      it('should truncate long player names', () => {
        const leaderboardData = {
          course: { code: 'CLE', name: 'Cherry Blossom Easy', difficulty: 'Easy' },
          entries: [
            { position: 1, playerName: 'VeryLongPlayerNameThatExceedsLimit', score: -22, isCurrentUser: false, isApproved: true }
          ],
          totalEntries: 1,
          hasUserScores: false,
          userEntries: [],
          lastUpdated: new Date()
        };

        const text = service.createTextDisplay(leaderboardData);

        expect(text).toContain('VeryLongPlayerNam...');
      });

      it('should handle text display errors gracefully', () => {
        const text = service.createTextDisplay(null);

        expect(text).toContain('❌ **Error Creating Leaderboard**');
      });
    });

    describe('truncateTextDisplay', () => {
      it('should not truncate short text', () => {
        const shortText = 'This is a short message';
        const result = service.truncateTextDisplay(shortText);
        
        expect(result).toBe(shortText);
      });

      it('should truncate long text at line breaks', () => {
        const longText = 'Line 1\n'.repeat(300); // Create very long text (over 2000 chars)
        const result = service.truncateTextDisplay(longText);
        
        expect(result.length).toBeLessThan(longText.length);
        expect(result).toContain('message truncated');
      });
    });

    describe('Helper Methods', () => {
      it('should get course name from code using cache', () => {
        service.courseCache.set('ALE', { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' });
        
        const name = service.getCourseNameFromCode('ALE');
        expect(name).toBe('Alfheim Easy');
      });

      it('should get course name from fallback when not in cache', () => {
        const name = service.getCourseNameFromCode('BBE');
        expect(name).toBe('Bogeys Bonnie Easy');
      });

      it('should generate course name from code as last resort', () => {
        const name = service.getCourseNameFromCode('XYZ');
        expect(name).toBe('XY Easy');
        
        const hardName = service.getCourseNameFromCode('XYH');
        expect(hardName).toBe('XY Hard');
      });

      it('should get course difficulty from code', () => {
        expect(service.getCourseDifficulty('ALE')).toBe('Easy');
        expect(service.getCourseDifficulty('ALH')).toBe('Hard');
        expect(service.getCourseDifficulty(null)).toBe('Unknown');
        expect(service.getCourseDifficulty('')).toBe('Unknown');
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
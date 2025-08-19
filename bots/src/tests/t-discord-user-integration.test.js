import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { RegistrationService } from '../services/RegistrationService.js';
import axios from 'axios';

// Mock axios
vi.mock('axios');
const mockedAxios = vi.mocked(axios);

describe('t_discord_user Integration Tests', () => {
  let registrationService;
  let mockAxiosInstance;

  beforeEach(() => {
    // Reset all mocks
    vi.clearAllMocks();
    
    // Create mock axios instance
    mockAxiosInstance = {
      get: vi.fn(),
      post: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() }
      }
    };
    
    mockedAxios.create.mockReturnValue(mockAxiosInstance);
    
    registrationService = new RegistrationService();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Discord User Data Synchronization', () => {
    it('should send complete Discord user data for registration', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'testuser',
        globalName: 'Test User',
        avatar: 'avatar_hash_123',
        accentColor: 16711680,
        banner: 'banner_hash_456',
        discriminator: '0',
        avatarDecorationData: null
      };

      const mockResponse = {
        data: {
          success: true,
          message: 'Successfully registered for S14W01 at 22:00 UTC',
          registration: {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            room_no: null
          }
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockResponse);

      // Act
      await registrationService.registerPlayer(mockDiscordUser, 456, '22:00');

      // Assert
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/register',
        {
          session_id: 456,
          time_slot: '22:00',
          discord_user: {
            id: '864988785888329748',
            username: 'testuser',
            global_name: 'Test User',
            avatar: 'avatar_hash_123',
            accent_color: 16711680,
            banner: 'banner_hash_456',
            discriminator: '0',
            avatar_decoration_data: null
          }
        }
      );
    });

    it('should handle Discord user with minimal data', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '123456789012345678',
        username: 'minimaluser',
        globalName: null,
        avatar: null,
        accentColor: null,
        banner: null,
        discriminator: '0',
        avatarDecorationData: null
      };

      const mockResponse = {
        data: {
          success: true,
          message: 'Successfully registered',
          registration: {
            session_id: 789,
            week: 'S14W02',
            time_slot: '14:00',
            room_no: 3
          }
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockResponse);

      // Act
      await registrationService.registerPlayer(mockDiscordUser, 789, '14:00');

      // Assert
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/register',
        {
          session_id: 789,
          time_slot: '14:00',
          discord_user: {
            id: '123456789012345678',
            username: 'minimaluser',
            global_name: 'minimaluser', // Should fallback to username
            avatar: null,
            accent_color: null,
            banner: null,
            discriminator: '0',
            avatar_decoration_data: null
          }
        }
      );
    });

    it('should send Discord user data for unregistration', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'testuser',
        globalName: 'Test User',
        avatar: 'avatar_hash_123',
        accentColor: 16711680,
        banner: 'banner_hash_456',
        discriminator: '0',
        avatarDecorationData: null
      };

      const mockResponse = {
        data: {
          success: true,
          message: 'Successfully unregistered from S14W01'
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockResponse);

      // Act
      await registrationService.unregisterPlayer(mockDiscordUser, 456);

      // Assert
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/unregister',
        {
          session_id: 456,
          discord_user: {
            id: '864988785888329748',
            username: 'testuser',
            global_name: 'Test User',
            avatar: 'avatar_hash_123',
            accent_color: 16711680,
            banner: 'banner_hash_456',
            discriminator: '0',
            avatar_decoration_data: null
          }
        }
      );
    });

    it('should handle Discord user data with special characters', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '999888777666555444',
        username: 'user_with_émojis',
        globalName: 'User With Émojis 🎮',
        avatar: 'special_avatar_hash',
        accentColor: null,
        banner: null,
        discriminator: '0',
        avatarDecorationData: null
      };

      const mockResponse = {
        data: {
          success: true,
          message: 'Successfully registered',
          registration: {
            session_id: 999,
            week: 'S14W03',
            time_slot: '08:00',
            room_no: 1
          }
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockResponse);

      // Act
      await registrationService.registerPlayer(mockDiscordUser, 999, '08:00');

      // Assert
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/register',
        {
          session_id: 999,
          time_slot: '08:00',
          discord_user: {
            id: '999888777666555444',
            username: 'user_with_émojis',
            global_name: 'User With Émojis 🎮',
            avatar: 'special_avatar_hash',
            accent_color: null,
            banner: null,
            discriminator: '0',
            avatar_decoration_data: null
          }
        }
      );
    });
  });

  describe('Player Registration Data Retrieval', () => {
    it('should fetch player registrations by Discord ID', async () => {
      // Arrange
      const discordId = '864988785888329748';
      const mockResponse = {
        data: {
          player: {
            id: 123,
            name: 'Test Player',
            discord_id: discordId
          },
          registrations: [
            {
              session_id: 456,
              week: 'S14W01',
              time_slot: '22:00',
              session_date: '2024-08-17T00:00:00Z',
              room_no: 5
            }
          ]
        }
      };

      mockAxiosInstance.get.mockResolvedValue(mockResponse);

      // Act
      const result = await registrationService.getPlayerRegistrations(discordId);

      // Assert
      expect(mockAxiosInstance.get).toHaveBeenCalledWith(`/api/players/registrations/${discordId}`);
      expect(result).toEqual(mockResponse.data);
      expect(result.player.discord_id).toBe(discordId);
      expect(result.registrations).toHaveLength(1);
    });

    it('should handle player not found gracefully', async () => {
      // Arrange
      const discordId = '999999999999999999';
      const notFoundError = new Error('Request failed with status code 404');
      notFoundError.response = { status: 404 };

      mockAxiosInstance.get.mockRejectedValue(notFoundError);

      // Act
      const result = await registrationService.getPlayerRegistrations(discordId);

      // Assert
      expect(result).toEqual({
        player: null,
        registrations: []
      });
    });

    it('should handle empty registrations for existing player', async () => {
      // Arrange
      const discordId = '111222333444555666';
      const mockResponse = {
        data: {
          player: {
            id: 789,
            name: 'Player With No Registrations',
            discord_id: discordId
          },
          registrations: []
        }
      };

      mockAxiosInstance.get.mockResolvedValue(mockResponse);

      // Act
      const result = await registrationService.getPlayerRegistrations(discordId);

      // Assert
      expect(result.player).toBeTruthy();
      expect(result.registrations).toEqual([]);
    });
  });

  describe('Error Handling for User Synchronization', () => {
    it('should handle API errors during registration with user sync', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'testuser',
        globalName: 'Test User',
        avatar: 'avatar_hash_123'
      };

      const apiError = new Error('Request failed with status code 500');
      apiError.response = {
        status: 500,
        data: {
          success: false,
          error_code: 'INTERNAL_ERROR',
          message: 'Database connection failed'
        }
      };

      mockAxiosInstance.post.mockRejectedValue(apiError);

      // Act & Assert
      await expect(
        registrationService.registerPlayer(mockDiscordUser, 456, '22:00')
      ).rejects.toThrow();
    }, 10000); // 10 second timeout

    it('should handle business logic errors during registration', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'testuser',
        globalName: 'Test User'
      };

      const mockResponse = {
        data: {
          success: false,
          error_code: 'ALREADY_REGISTERED',
          message: 'Player is already registered for this tournament session'
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockResponse);

      // Act & Assert
      await expect(
        registrationService.registerPlayer(mockDiscordUser, 456, '22:00')
      ).rejects.toThrow('Player is already registered for this tournament session');
    });

    it('should handle registration closed error', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'testuser',
        globalName: 'Test User'
      };

      const mockResponse = {
        data: {
          success: false,
          error_code: 'REGISTRATION_CLOSED',
          message: 'Registration for this tournament session has closed'
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockResponse);

      // Act & Assert
      await expect(
        registrationService.registerPlayer(mockDiscordUser, 456, '22:00')
      ).rejects.toThrow('Registration for this tournament session has closed');
    });
  });

  describe('Timezone Integration with User Sync', () => {
    it('should send Discord user data when setting timezone preference', async () => {
      // Arrange
      const discordId = '864988785888329748';
      const timezone = 'America/New_York';
      const mockDiscordUser = {
        id: discordId,
        username: 'testuser',
        globalName: 'Test User',
        avatar: 'avatar_hash_123',
        accentColor: null,
        banner: null,
        discriminator: '0',
        avatarDecorationData: null
      };

      const mockResponse = {
        data: {
          success: true,
          message: 'Timezone preference updated successfully'
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockResponse);

      // Act
      await registrationService.setPlayerTimezone(discordId, timezone, mockDiscordUser);

      // Assert
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/players/timezone',
        {
          discord_id: discordId,
          timezone: timezone,
          discord_user: {
            id: discordId,
            username: 'testuser',
            global_name: 'Test User',
            avatar: 'avatar_hash_123',
            accent_color: null,
            banner: null,
            discriminator: '0',
            avatar_decoration_data: null
          }
        }
      );
    });
  });
});
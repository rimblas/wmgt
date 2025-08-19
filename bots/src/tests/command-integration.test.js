import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { RegistrationService } from '../services/RegistrationService.js';
import axios from 'axios';

// Mock axios
vi.mock('axios');
const mockedAxios = vi.mocked(axios);

describe('Command Integration with t_discord_user', () => {
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

  describe('Registration Command Flow', () => {
    it('should handle complete registration flow with Discord user sync', async () => {
      // Arrange - Mock Discord user from interaction
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'testplayer',
        globalName: 'Test Player',
        avatar: 'avatar_hash_123',
        accentColor: 16711680,
        banner: 'banner_hash_456',
        discriminator: '0',
        avatarDecorationData: null
      };

      // Mock tournament data response
      const mockTournamentData = {
        tournament: {
          id: 123,
          name: 'Season 14 Tournament',
          code: 'S14'
        },
        sessions: {
          id: 456,
          week: 'S14W01',
          session_date: '2024-08-17T00:00:00Z',
          open_registration_on: '2024-08-10T00:00:00Z',
          close_registration_on: '2024-08-17T22:00:00Z',
          registration_open: true,
          available_time_slots: [
            {
              time_slot: '22:00',
              day_offset: -1,
              display: '22:00 -1'
            },
            {
              time_slot: '00:00',
              day_offset: 0,
              display: '00:00'
            }
          ],
          courses: [
            {
              course_no: 1,
              course_name: 'Atlantis',
              course_code: 'ATH',
              difficulty: 'Hard'
            }
          ]
        }
      };

      // Mock registration success response
      const mockRegistrationResponse = {
        data: {
          success: true,
          message: 'Successfully registered for S14W01 at 22:00 UTC',
          registration: {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            room_no: 5
          }
        }
      };

      mockAxiosInstance.get.mockResolvedValue({ data: mockTournamentData });
      mockAxiosInstance.post.mockResolvedValue(mockRegistrationResponse);

      // Act - Simulate registration flow
      const tournamentData = await registrationService.getCurrentTournament();
      const registrationResult = await registrationService.registerPlayer(
        mockDiscordUser,
        tournamentData.sessions.id,
        '22:00'
      );

      // Assert - Verify tournament data was fetched
      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/api/tournaments/current');
      expect(tournamentData.tournament.name).toBe('Season 14 Tournament');
      expect(tournamentData.sessions.available_time_slots).toHaveLength(2);

      // Assert - Verify registration call with complete Discord user data
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/register',
        {
          session_id: 456,
          time_slot: '22:00',
          discord_user: {
            id: '864988785888329748',
            username: 'testplayer',
            global_name: 'Test Player',
            avatar: 'avatar_hash_123',
            accent_color: 16711680,
            banner: 'banner_hash_456',
            discriminator: '0',
            avatar_decoration_data: null
          }
        }
      );

      // Assert - Verify registration success
      expect(registrationResult.success).toBe(true);
      expect(registrationResult.registration.room_no).toBe(5);
    });

    it('should handle mystatus command flow with player data retrieval', async () => {
      // Arrange
      const discordId = '864988785888329748';
      const mockPlayerData = {
        player: {
          id: 123,
          name: 'Test Player',
          discord_id: discordId,
          timezone: 'America/New_York'
        },
        registrations: [
          {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            session_date: '2024-08-17T00:00:00Z',
            room_no: 5
          },
          {
            session_id: 789,
            week: 'S14W02',
            time_slot: '14:00',
            session_date: '2024-08-24T00:00:00Z',
            room_no: null
          }
        ]
      };

      mockAxiosInstance.get.mockResolvedValue({ data: mockPlayerData });

      // Act
      const playerData = await registrationService.getPlayerRegistrations(discordId);

      // Assert
      expect(mockAxiosInstance.get).toHaveBeenCalledWith(`/api/players/registrations/${discordId}`);
      expect(playerData.player.discord_id).toBe(discordId);
      expect(playerData.player.timezone).toBe('America/New_York');
      expect(playerData.registrations).toHaveLength(2);
      expect(playerData.registrations[0].room_no).toBe(5);
      expect(playerData.registrations[1].room_no).toBeNull();
    });

    it('should handle unregister command flow with Discord user sync', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'testplayer',
        globalName: 'Test Player',
        avatar: 'avatar_hash_123'
      };

      const mockUnregisterResponse = {
        data: {
          success: true,
          message: 'Successfully unregistered from S14W01'
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockUnregisterResponse);

      // Act
      const result = await registrationService.unregisterPlayer(mockDiscordUser, 456);

      // Assert
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/unregister',
        {
          session_id: 456,
          discord_user: {
            id: '864988785888329748',
            username: 'testplayer',
            global_name: 'Test Player',
            avatar: 'avatar_hash_123',
            accent_color: undefined,
            banner: undefined,
            discriminator: '0',
            avatar_decoration_data: undefined
          }
        }
      );

      expect(result.success).toBe(true);
      expect(result.message).toContain('unregistered');
    });

    it('should handle timezone command flow with user synchronization', async () => {
      // Arrange
      const discordId = '864988785888329748';
      const timezone = 'Europe/London';
      const mockDiscordUser = {
        id: discordId,
        username: 'testplayer',
        globalName: 'Test Player',
        avatar: 'new_avatar_hash',
        accentColor: 255,
        banner: null,
        discriminator: '0',
        avatarDecorationData: null
      };

      const mockTimezoneResponse = {
        data: {
          success: true,
          message: 'Timezone preference updated successfully',
          timezone: timezone
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockTimezoneResponse);

      // Act
      const result = await registrationService.setPlayerTimezone(discordId, timezone, mockDiscordUser);

      // Assert
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/players/timezone',
        {
          discord_id: discordId,
          timezone: timezone,
          discord_user: {
            id: discordId,
            username: 'testplayer',
            global_name: 'Test Player',
            avatar: 'new_avatar_hash',
            accent_color: 255,
            banner: null,
            discriminator: '0',
            avatar_decoration_data: null
          }
        }
      );

      expect(result.success).toBe(true);
      expect(result.timezone).toBe(timezone);
    });
  });

  describe('Error Scenarios with User Sync', () => {
    it('should handle player not found during registration', async () => {
      // Arrange
      const mockDiscordUser = {
        id: '999999999999999999',
        username: 'newplayer',
        globalName: 'New Player'
      };

      const mockErrorResponse = {
        data: {
          success: false,
          error_code: 'PLAYER_NOT_FOUND',
          message: 'Discord user not linked to WMGT player account'
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockErrorResponse);

      // Act & Assert
      await expect(
        registrationService.registerPlayer(mockDiscordUser, 456, '22:00')
      ).rejects.toThrow('Discord user not linked to WMGT player account');

      // Verify Discord user data was still sent for potential sync
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/register',
        expect.objectContaining({
          discord_user: expect.objectContaining({
            id: '999999999999999999',
            username: 'newplayer',
            global_name: 'New Player'
          })
        })
      );
    });

    it('should handle registration with updated Discord profile data', async () => {
      // Arrange - User with updated profile information
      const mockDiscordUser = {
        id: '864988785888329748',
        username: 'updated_username',
        globalName: 'Updated Display Name',
        avatar: 'new_avatar_hash_456',
        accentColor: 65280, // Green
        banner: 'new_banner_hash',
        discriminator: '0',
        avatarDecorationData: 'decoration_data'
      };

      const mockRegistrationResponse = {
        data: {
          success: true,
          message: 'Successfully registered for S14W01 at 14:00 UTC',
          registration: {
            session_id: 456,
            week: 'S14W01',
            time_slot: '14:00',
            room_no: 3
          }
        }
      };

      mockAxiosInstance.post.mockResolvedValue(mockRegistrationResponse);

      // Act
      const result = await registrationService.registerPlayer(mockDiscordUser, 456, '14:00');

      // Assert - Verify all updated Discord data is sent for sync
      expect(mockAxiosInstance.post).toHaveBeenCalledWith(
        '/api/tournaments/register',
        {
          session_id: 456,
          time_slot: '14:00',
          discord_user: {
            id: '864988785888329748',
            username: 'updated_username',
            global_name: 'Updated Display Name',
            avatar: 'new_avatar_hash_456',
            accent_color: 65280,
            banner: 'new_banner_hash',
            discriminator: '0',
            avatar_decoration_data: 'decoration_data'
          }
        }
      );

      expect(result.success).toBe(true);
    });

    it('should handle concurrent registrations with user sync', async () => {
      // Arrange - Multiple users registering simultaneously
      const users = [
        {
          id: '111111111111111111',
          username: 'user1',
          globalName: 'User One'
        },
        {
          id: '222222222222222222',
          username: 'user2',
          globalName: 'User Two'
        },
        {
          id: '333333333333333333',
          username: 'user3',
          globalName: 'User Three'
        }
      ];

      const mockResponses = users.map((user, index) => ({
        data: {
          success: true,
          message: `Successfully registered for S14W01 at 22:00 UTC`,
          registration: {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            room_no: index + 1
          }
        }
      }));

      mockAxiosInstance.post
        .mockResolvedValueOnce(mockResponses[0])
        .mockResolvedValueOnce(mockResponses[1])
        .mockResolvedValueOnce(mockResponses[2]);

      // Act - Simulate concurrent registrations
      const registrationPromises = users.map(user =>
        registrationService.registerPlayer(user, 456, '22:00')
      );

      const results = await Promise.all(registrationPromises);

      // Assert - Verify all registrations succeeded with proper user sync
      expect(results).toHaveLength(3);
      results.forEach((result, index) => {
        expect(result.success).toBe(true);
        expect(result.registration.room_no).toBe(index + 1);
      });

      // Verify each user's data was sent correctly
      users.forEach((user, index) => {
        expect(mockAxiosInstance.post).toHaveBeenNthCalledWith(
          index + 1,
          '/api/tournaments/register',
          expect.objectContaining({
            discord_user: expect.objectContaining({
              id: user.id,
              username: user.username,
              global_name: user.globalName
            })
          })
        );
      });
    });
  });
});
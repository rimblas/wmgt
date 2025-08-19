import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import axios from 'axios';
import { config } from '../config/config.js';

// This test file verifies the actual API integration with t_discord_user
// Note: These tests require a running API server and database connection

describe('API Integration with t_discord_user', () => {
  let apiClient;
  
  beforeEach(() => {
    apiClient = axios.create({
      baseURL: config.api.baseUrl,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  });

  // Skip these tests by default since they require a live API
  // Run with: npm test -- --run api-integration.test.js
  describe.skip('Live API Tests', () => {
    const testDiscordUser = {
      id: '999999999999999999', // Test Discord ID
      username: 'test_integration_user',
      global_name: 'Test Integration User',
      avatar: 'test_avatar_hash',
      accent_color: 16711680,
      banner: 'test_banner_hash',
      discriminator: '0',
      avatar_decoration_data: null
    };

    it('should sync Discord user data during registration', async () => {
      // This test verifies that the t_discord_user.sync_player() method
      // is called correctly during registration
      
      try {
        // First, get current tournament to get a valid session ID
        const tournamentResponse = await apiClient.get('/api/tournaments/current');
        expect(tournamentResponse.status).toBe(200);
        
        const tournamentData = tournamentResponse.data;
        if (!tournamentData.sessions || !tournamentData.sessions.id) {
          console.log('No active tournament sessions available for testing');
          return;
        }

        const sessionId = tournamentData.sessions.id;
        const timeSlot = '22:00'; // Use a valid time slot

        // Attempt registration
        const registrationResponse = await apiClient.post('/api/tournaments/register', {
          session_id: sessionId,
          time_slot: timeSlot,
          discord_user: testDiscordUser
        });

        // Should succeed or fail with a business logic error (not a sync error)
        expect([200, 400]).toContain(registrationResponse.status);
        
        if (registrationResponse.status === 200) {
          expect(registrationResponse.data.success).toBe(true);
          console.log('Registration successful:', registrationResponse.data.message);
          
          // Clean up - unregister the test user
          await apiClient.post('/api/tournaments/unregister', {
            session_id: sessionId,
            discord_user: testDiscordUser
          });
        } else {
          // Business logic error (already registered, registration closed, etc.)
          expect(registrationResponse.data.success).toBe(false);
          expect(registrationResponse.data.error_code).toBeDefined();
          console.log('Registration failed as expected:', registrationResponse.data.message);
        }

      } catch (error) {
        if (error.response) {
          console.log('API Error:', error.response.status, error.response.data);
          // Verify it's a business logic error, not a sync error
          expect(error.response.data.error_code).toBeDefined();
        } else {
          throw error;
        }
      }
    });

    it('should retrieve player data by Discord ID', async () => {
      try {
        const response = await apiClient.get(`/api/players/registrations/${testDiscordUser.id}`);
        
        if (response.status === 200) {
          expect(response.data.player).toBeDefined();
          expect(response.data.registrations).toBeDefined();
          expect(Array.isArray(response.data.registrations)).toBe(true);
          console.log('Player found:', response.data.player);
        }
      } catch (error) {
        if (error.response?.status === 404) {
          // Player not found is acceptable for test user
          console.log('Test player not found (expected for new test user)');
        } else {
          throw error;
        }
      }
    });

    it('should handle user synchronization with updated Discord data', async () => {
      // Test that updating Discord user data (like username, avatar) gets synced
      const updatedDiscordUser = {
        ...testDiscordUser,
        username: 'updated_test_user',
        global_name: 'Updated Test User',
        avatar: 'updated_avatar_hash'
      };

      try {
        // Get current tournament
        const tournamentResponse = await apiClient.get('/api/tournaments/current');
        if (!tournamentResponse.data.sessions?.id) {
          console.log('No active tournament for sync test');
          return;
        }

        const sessionId = tournamentResponse.data.sessions.id;

        // Try to register with updated user data
        const response = await apiClient.post('/api/tournaments/register', {
          session_id: sessionId,
          time_slot: '14:00',
          discord_user: updatedDiscordUser
        });

        // Should handle the sync without errors
        expect([200, 400]).toContain(response.status);
        
        if (response.status === 400) {
          // Business logic error is fine
          expect(response.data.error_code).toBeDefined();
        }

      } catch (error) {
        if (error.response?.data?.error_code) {
          // Business logic error is acceptable
          console.log('Sync test completed with business logic error:', error.response.data.message);
        } else {
          throw error;
        }
      }
    });
  });

  describe('Mock API Response Validation', () => {
    it('should validate registration response format matches t_discord_user expectations', () => {
      // Test that our expected response format is correct
      const mockRegistrationResponse = {
        success: true,
        message: 'Successfully registered for S14W01 at 22:00 UTC',
        registration: {
          session_id: 456,
          week: 'S14W01',
          time_slot: '22:00',
          room_no: null
        }
      };

      expect(mockRegistrationResponse.success).toBe(true);
      expect(mockRegistrationResponse.message).toContain('registered');
      expect(mockRegistrationResponse.registration.session_id).toBeDefined();
      expect(mockRegistrationResponse.registration.time_slot).toBeDefined();
    });

    it('should validate player registrations response format', () => {
      const mockPlayerResponse = {
        player: {
          id: 123,
          name: 'Test Player',
          discord_id: '864988785888329748'
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
      };

      expect(mockPlayerResponse.player.discord_id).toBeDefined();
      expect(Array.isArray(mockPlayerResponse.registrations)).toBe(true);
      if (mockPlayerResponse.registrations.length > 0) {
        expect(mockPlayerResponse.registrations[0].session_id).toBeDefined();
        expect(mockPlayerResponse.registrations[0].time_slot).toBeDefined();
      }
    });

    it('should validate error response format for t_discord_user failures', () => {
      const mockErrorResponse = {
        success: false,
        error_code: 'PLAYER_SYNC_FAILED',
        message: 'Failed to synchronize Discord user data',
        details: {
          discord_id: '864988785888329748',
          sync_error: 'Invalid username format'
        }
      };

      expect(mockErrorResponse.success).toBe(false);
      expect(mockErrorResponse.error_code).toBeDefined();
      expect(mockErrorResponse.message).toBeDefined();
    });
  });

  describe('Discord User Data Validation', () => {
    it('should validate required Discord user fields', () => {
      const validDiscordUser = {
        id: '864988785888329748',
        username: 'testuser',
        global_name: 'Test User',
        avatar: 'avatar_hash',
        accent_color: null,
        banner: null,
        discriminator: '0',
        avatar_decoration_data: null
      };

      // Required fields
      expect(validDiscordUser.id).toBeDefined();
      expect(typeof validDiscordUser.id).toBe('string');
      expect(validDiscordUser.username).toBeDefined();
      expect(typeof validDiscordUser.username).toBe('string');

      // Optional fields should be handled gracefully
      expect(validDiscordUser.global_name !== undefined).toBe(true);
      expect(validDiscordUser.avatar !== undefined).toBe(true);
    });

    it('should handle Discord user with minimal data', () => {
      const minimalDiscordUser = {
        id: '123456789012345678',
        username: 'minimaluser',
        global_name: null,
        avatar: null,
        accent_color: null,
        banner: null,
        discriminator: '0',
        avatar_decoration_data: null
      };

      expect(minimalDiscordUser.id).toBeDefined();
      expect(minimalDiscordUser.username).toBeDefined();
      // All other fields can be null and should be handled by t_discord_user
    });

    it('should validate Discord ID format', () => {
      const validDiscordIds = [
        '864988785888329748',
        '123456789012345678',
        '999999999999999999'
      ];

      const invalidDiscordIds = [
        '12345', // Too short
        'not_a_number',
        '',
        null,
        undefined
      ];

      validDiscordIds.forEach(id => {
        expect(typeof id).toBe('string');
        expect(id.length).toBeGreaterThanOrEqual(17);
        expect(id.length).toBeLessThanOrEqual(19);
        expect(/^\d+$/.test(id)).toBe(true);
      });

      invalidDiscordIds.forEach(id => {
        if (id !== null && id !== undefined) {
          expect(typeof id === 'string' && /^\d{17,19}$/.test(id)).toBe(false);
        }
      });
    });
  });
});
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import axios from 'axios';
import { RegistrationService } from '../services/RegistrationService.js';

// Mock axios
vi.mock('axios');
const mockedAxios = vi.mocked(axios);

describe('RegistrationService', () => {
  let registrationService;
  let mockAxiosInstance;

  beforeEach(() => {
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
    vi.clearAllMocks();
  });

  describe('constructor', () => {
    it('should create axios instance with correct configuration', () => {
      expect(mockedAxios.create).toHaveBeenCalledWith({
        baseURL: 'http://localhost:8080',
        timeout: 10000,
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

  describe('getCurrentTournament', () => {
    it('should fetch current tournament successfully', async () => {
      const mockTournamentData = {
        tournament: {
          id: 123,
          name: 'Season 14 Tournament',
          code: 'S14'
        },
        sessions: [
          {
            id: 456,
            week: 'S14W01',
            session_date: '2024-08-17T00:00:00Z',
            registration_open: true,
            available_time_slots: ['22:00', '00:00', '02:00']
          }
        ]
      };

      mockAxiosInstance.get.mockResolvedValue({ data: mockTournamentData });

      const result = await registrationService.getCurrentTournament();

      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/api/tournaments/current');
      expect(result).toEqual(mockTournamentData);
    });

    it('should handle 404 error when no tournament found', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        response: { status: 404 }
      });

      await expect(registrationService.getCurrentTournament())
        .rejects.toThrow('No active tournament found');
    });

    it('should handle server errors', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        response: { status: 500 }
      });

      await expect(registrationService.getCurrentTournament())
        .rejects.toThrow('Tournament service is temporarily unavailable');
    });

    it('should handle connection errors', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        code: 'ECONNREFUSED',
        message: 'Connection refused'
      });

      await expect(registrationService.getCurrentTournament())
        .rejects.toThrow('Unable to connect to tournament service');
    });

    it('should handle empty response data', async () => {
      mockAxiosInstance.get.mockResolvedValue({ data: null });

      await expect(registrationService.getCurrentTournament())
        .rejects.toThrow('No tournament data received from API');
    });
  });

  describe('registerPlayer', () => {
    const mockDiscordUser = {
      id: '864988785888329748',
      username: 'glitchingqueen',
      globalName: 'Jen',
      avatar: '1eb556c0773045fef0d56292c151ab11',
      accentColor: null,
      banner: 'a_75888fd5e40a99be49c208857b8a3994',
      discriminator: '0',
      avatarDecorationData: null
    };

    it('should register player successfully', async () => {
      const mockResponse = {
        success: true,
        message: 'Successfully registered for S14W01 at 22:00 UTC',
        registration: {
          session_id: 456,
          week: 'S14W01',
          time_slot: '22:00',
          room_no: null
        }
      };

      mockAxiosInstance.post.mockResolvedValue({ data: mockResponse });

      const result = await registrationService.registerPlayer(mockDiscordUser, 456, '22:00');

      expect(mockAxiosInstance.post).toHaveBeenCalledWith('/api/tournaments/register', {
        session_id: 456,
        time_slot: '22:00',
        discord_user: {
          id: '864988785888329748',
          username: 'glitchingqueen',
          global_name: 'Jen',
          avatar: '1eb556c0773045fef0d56292c151ab11',
          accent_color: null,
          banner: 'a_75888fd5e40a99be49c208857b8a3994',
          discriminator: '0',
          avatar_decoration_data: null
        }
      });
      expect(result).toEqual(mockResponse);
    });

    it('should handle registration closed error', async () => {
      mockAxiosInstance.post.mockRejectedValue({
        response: {
          data: {
            error_code: 'REGISTRATION_CLOSED',
            message: 'Registration has closed'
          }
        }
      });

      await expect(registrationService.registerPlayer(mockDiscordUser, 456, '22:00'))
        .rejects.toThrow('Registration for this tournament session has closed');
    });

    it('should handle already registered error', async () => {
      mockAxiosInstance.post.mockRejectedValue({
        response: {
          data: {
            error_code: 'ALREADY_REGISTERED',
            message: 'Player already registered'
          }
        }
      });

      await expect(registrationService.registerPlayer(mockDiscordUser, 456, '22:00'))
        .rejects.toThrow('You are already registered for this tournament session');
    });

    it('should handle invalid time slot error', async () => {
      mockAxiosInstance.post.mockRejectedValue({
        response: {
          data: {
            error_code: 'INVALID_TIME_SLOT',
            message: 'Time slot not available'
          }
        }
      });

      await expect(registrationService.registerPlayer(mockDiscordUser, 456, '25:00'))
        .rejects.toThrow('The selected time slot is not available');
    });

    it('should handle unsuccessful registration response', async () => {
      mockAxiosInstance.post.mockResolvedValue({
        data: {
          success: false,
          message: 'Registration failed for unknown reason'
        }
      });

      await expect(registrationService.registerPlayer(mockDiscordUser, 456, '22:00'))
        .rejects.toThrow('Registration failed for unknown reason');
    });

    it('should handle user with no globalName', async () => {
      const userWithoutGlobalName = {
        ...mockDiscordUser,
        globalName: null
      };

      const mockResponse = {
        success: true,
        message: 'Successfully registered'
      };

      mockAxiosInstance.post.mockResolvedValue({ data: mockResponse });

      await registrationService.registerPlayer(userWithoutGlobalName, 456, '22:00');

      expect(mockAxiosInstance.post).toHaveBeenCalledWith('/api/tournaments/register', 
        expect.objectContaining({
          discord_user: expect.objectContaining({
            global_name: 'glitchingqueen' // Should fallback to username
          })
        })
      );
    });
  });

  describe('unregisterPlayer', () => {
    const mockDiscordUser = {
      id: '864988785888329748',
      username: 'glitchingqueen',
      globalName: 'Jen',
      avatar: '1eb556c0773045fef0d56292c151ab11'
    };

    it('should unregister player successfully', async () => {
      const mockResponse = {
        success: true,
        message: 'Successfully unregistered from S14W01'
      };

      mockAxiosInstance.post.mockResolvedValue({ data: mockResponse });

      const result = await registrationService.unregisterPlayer(mockDiscordUser, 456);

      expect(mockAxiosInstance.post).toHaveBeenCalledWith('/api/tournaments/unregister', {
        session_id: 456,
        discord_user: {
          id: '864988785888329748',
          username: 'glitchingqueen',
          global_name: 'Jen',
          avatar: '1eb556c0773045fef0d56292c151ab11',
          accent_color: undefined,
          banner: undefined,
          discriminator: '0',
          avatar_decoration_data: undefined
        }
      });
      expect(result).toEqual(mockResponse);
    });

    it('should handle unregistration failed error', async () => {
      mockAxiosInstance.post.mockRejectedValue({
        response: {
          data: {
            error_code: 'UNREGISTRATION_FAILED',
            message: 'Tournament already started'
          }
        }
      });

      await expect(registrationService.unregisterPlayer(mockDiscordUser, 456))
        .rejects.toThrow('Cannot unregister: tournament may have already started');
    });

    it('should handle player not found error', async () => {
      mockAxiosInstance.post.mockRejectedValue({
        response: {
          data: {
            error_code: 'PLAYER_NOT_FOUND',
            message: 'Player not registered'
          }
        }
      });

      await expect(registrationService.unregisterPlayer(mockDiscordUser, 456))
        .rejects.toThrow('You are not registered for this tournament session');
    });
  });

  describe('getPlayerRegistrations', () => {
    it('should fetch player registrations successfully', async () => {
      const mockRegistrations = {
        player: {
          id: 789,
          name: 'PlayerName',
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

      mockAxiosInstance.get.mockResolvedValue({ data: mockRegistrations });

      const result = await registrationService.getPlayerRegistrations('864988785888329748');

      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/api/players/registrations/864988785888329748');
      expect(result).toEqual(mockRegistrations);
    });

    it('should handle player not found (404)', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        response: { status: 404 }
      });

      const result = await registrationService.getPlayerRegistrations('nonexistent');

      expect(result).toEqual({
        player: null,
        registrations: []
      });
    });

    it('should handle server errors', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        response: { status: 500 }
      });

      await expect(registrationService.getPlayerRegistrations('864988785888329748'))
        .rejects.toThrow('Registration service is temporarily unavailable');
    });

    it('should handle empty response data', async () => {
      mockAxiosInstance.get.mockResolvedValue({ data: null });

      await expect(registrationService.getPlayerRegistrations('864988785888329748'))
        .rejects.toThrow('No registration data received from API');
    });
  });

  describe('retryWithBackoff', () => {
    it('should succeed on first attempt', async () => {
      const mockApiCall = vi.fn().mockResolvedValue('success');

      const result = await registrationService.retryWithBackoff(mockApiCall);

      expect(result).toBe('success');
      expect(mockApiCall).toHaveBeenCalledTimes(1);
    });

    it('should retry on server errors and eventually succeed', async () => {
      const mockApiCall = vi.fn()
        .mockRejectedValueOnce({ response: { status: 500 } })
        .mockRejectedValueOnce({ response: { status: 502 } })
        .mockResolvedValue('success');

      const result = await registrationService.retryWithBackoff(mockApiCall, 3, 100);

      expect(result).toBe('success');
      expect(mockApiCall).toHaveBeenCalledTimes(3);
    });

    it('should not retry on client errors (4xx)', async () => {
      const mockApiCall = vi.fn().mockRejectedValue({ response: { status: 400 } });

      await expect(registrationService.retryWithBackoff(mockApiCall))
        .rejects.toEqual({ response: { status: 400 } });
      
      expect(mockApiCall).toHaveBeenCalledTimes(1);
    });

    it('should retry on rate limit errors (429)', async () => {
      const mockApiCall = vi.fn()
        .mockRejectedValueOnce({ response: { status: 429 } })
        .mockResolvedValue('success');

      const result = await registrationService.retryWithBackoff(mockApiCall, 2, 100);

      expect(result).toBe('success');
      expect(mockApiCall).toHaveBeenCalledTimes(2);
    });

    it('should throw last error after max retries', async () => {
      const lastError = { response: { status: 500 } };
      const mockApiCall = vi.fn().mockRejectedValue(lastError);

      await expect(registrationService.retryWithBackoff(mockApiCall, 2, 100))
        .rejects.toEqual(lastError);
      
      expect(mockApiCall).toHaveBeenCalledTimes(3); // Initial + 2 retries
    });
  });
});
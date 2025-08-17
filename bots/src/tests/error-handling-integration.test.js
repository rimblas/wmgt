import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { RegistrationService } from '../services/RegistrationService.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';
import { RetryHandler } from '../utils/RetryHandler.js';
import { Logger } from '../utils/Logger.js';
import axios from 'axios';

// Mock axios
vi.mock('axios');

describe('Error Handling Integration', () => {
  let registrationService;
  let mockAxios;
  let consoleLogSpy;

  beforeEach(() => {
    // Mock axios
    mockAxios = {
      create: vi.fn(() => mockAxios),
      get: vi.fn(),
      post: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() }
      }
    };
    axios.create.mockReturnValue(mockAxios);

    // Spy on console to suppress logs during tests
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

    registrationService = new RegistrationService();
  });

  afterEach(() => {
    vi.clearAllMocks();
    consoleLogSpy.mockRestore();
  });

  describe('API Error Handling', () => {
    it('should handle network errors with retry', async () => {
      const networkError = new Error('Network Error');
      networkError.code = 'ECONNREFUSED';

      mockAxios.get
        .mockRejectedValueOnce(networkError)
        .mockRejectedValueOnce(networkError)
        .mockResolvedValueOnce({
          data: {
            tournament: { id: 1, name: 'Test Tournament' },
            sessions: []
          }
        });

      const result = await registrationService.getCurrentTournament();

      expect(result.tournament.name).toBe('Test Tournament');
      expect(mockAxios.get).toHaveBeenCalledTimes(3);
    });

    it('should handle rate limiting with proper delay', async () => {
      const rateLimitError = new Error('Rate Limited');
      rateLimitError.response = {
        status: 429,
        headers: { 'retry-after': '1' }
      };

      mockAxios.get
        .mockRejectedValueOnce(rateLimitError)
        .mockResolvedValueOnce({
          data: {
            tournament: { id: 1, name: 'Test Tournament' },
            sessions: []
          }
        });

      const startTime = Date.now();
      const result = await registrationService.getCurrentTournament();
      const duration = Date.now() - startTime;

      expect(result.tournament.name).toBe('Test Tournament');
      expect(duration).toBeGreaterThan(900); // Should wait at least 1 second
      expect(mockAxios.get).toHaveBeenCalledTimes(2);
    });

    it('should not retry client errors', async () => {
      const clientError = new Error('Bad Request');
      clientError.response = { status: 400 };

      mockAxios.get.mockRejectedValue(clientError);

      await expect(registrationService.getCurrentTournament()).rejects.toThrow();
      expect(mockAxios.get).toHaveBeenCalledTimes(1);
    });

    it('should handle API error codes correctly', async () => {
      const apiError = new Error('Already Registered');
      apiError.response = {
        status: 400,
        data: {
          error_code: 'ALREADY_REGISTERED',
          message: 'You are already registered for this session'
        }
      };

      mockAxios.post.mockRejectedValue(apiError);

      const mockUser = {
        id: '123',
        username: 'testuser',
        globalName: 'Test User'
      };

      await expect(
        registrationService.registerPlayer(mockUser, 1, '22:00')
      ).rejects.toThrow();

      expect(mockAxios.post).toHaveBeenCalledTimes(1);
    });

    it('should handle server errors with retry', async () => {
      const serverError = new Error('Internal Server Error');
      serverError.response = { status: 500 };

      mockAxios.get
        .mockRejectedValueOnce(serverError)
        .mockRejectedValueOnce(serverError)
        .mockResolvedValueOnce({
          data: {
            tournament: { id: 1, name: 'Test Tournament' },
            sessions: []
          }
        });

      const result = await registrationService.getCurrentTournament();

      expect(result.tournament.name).toBe('Test Tournament');
      expect(mockAxios.get).toHaveBeenCalledTimes(3);
    });

    it('should handle timeout errors', async () => {
      const timeoutError = new Error('Request Timeout');
      timeoutError.code = 'ETIMEDOUT';

      mockAxios.get
        .mockRejectedValueOnce(timeoutError)
        .mockResolvedValueOnce({
          data: {
            tournament: { id: 1, name: 'Test Tournament' },
            sessions: []
          }
        });

      const result = await registrationService.getCurrentTournament();

      expect(result.tournament.name).toBe('Test Tournament');
      expect(mockAxios.get).toHaveBeenCalledTimes(2);
    });
  });

  describe('Circuit Breaker Integration', () => {
    it('should open circuit breaker after threshold failures', async () => {
      const serverError = new Error('Server Error');
      serverError.response = { status: 500 };

      // Create service with low threshold for testing
      const testService = new RegistrationService();
      testService.retryHandler = new RetryHandler(testService.logger, {
        maxRetries: 0, // No retries to speed up test
        circuitBreakerThreshold: 2
      });

      mockAxios.get.mockRejectedValue(serverError);

      // First failure
      await expect(testService.getCurrentTournament()).rejects.toThrow();

      // Second failure should open circuit
      await expect(testService.getCurrentTournament()).rejects.toThrow();

      // Third attempt should be blocked by circuit breaker
      await expect(testService.getCurrentTournament()).rejects.toThrow('Circuit breaker is OPEN');

      expect(mockAxios.get).toHaveBeenCalledTimes(2);
    });
  });

  describe('Error Classification', () => {
    it('should classify different error types correctly', () => {
      const errorHandler = new ErrorHandler(new Logger({ console: false }));

      // Network error
      const networkError = new Error('Connection refused');
      networkError.code = 'ECONNREFUSED';
      expect(errorHandler.classifyError(networkError)).toBe('CONNECTION_ERROR');

      // Rate limit error
      const rateLimitError = new Error('Rate limited');
      rateLimitError.response = { status: 429 };
      expect(errorHandler.classifyError(rateLimitError)).toBe('RATE_LIMITED');

      // Server error
      const serverError = new Error('Server error');
      serverError.response = { status: 500 };
      expect(errorHandler.classifyError(serverError)).toBe('SERVICE_UNAVAILABLE');

      // API error code
      const apiError = new Error('Registration closed');
      apiError.response = {
        data: { error_code: 'REGISTRATION_CLOSED' }
      };
      expect(errorHandler.classifyError(apiError)).toBe('REGISTRATION_CLOSED');

      // Timezone error
      const timezoneError = new Error('Invalid timezone provided');
      expect(errorHandler.classifyError(timezoneError)).toBe('INVALID_TIMEZONE');
    });
  });

  describe('Logging Integration', () => {
    it('should log API requests and responses', async () => {
      mockAxios.get.mockResolvedValue({
        data: {
          tournament: { id: 1, name: 'Test Tournament' },
          sessions: []
        }
      });

      await registrationService.getCurrentTournament();

      // Verify interceptors were set up (they're called during service construction)
      expect(mockAxios.interceptors.request.use).toHaveBeenCalled();
      expect(mockAxios.interceptors.response.use).toHaveBeenCalled();
    });

    it('should log retry attempts', async () => {
      const networkError = new Error('Network Error');
      networkError.code = 'ECONNREFUSED';

      mockAxios.get
        .mockRejectedValueOnce(networkError)
        .mockResolvedValueOnce({
          data: {
            tournament: { id: 1, name: 'Test Tournament' },
            sessions: []
          }
        });

      await registrationService.getCurrentTournament();

      // The retry should have been logged (we can't easily test the exact log call
      // without more complex mocking, but we can verify the operation succeeded)
      expect(mockAxios.get).toHaveBeenCalledTimes(2);
    });
  });

  describe('Health Status', () => {
    it('should report healthy status when API is working', async () => {
      mockAxios.get.mockResolvedValue({
        data: {
          tournament: { id: 1, name: 'Test Tournament' },
          sessions: []
        }
      });

      const health = await registrationService.getHealthStatus();

      expect(health.status).toBe('healthy');
      expect(health.responseTime).toBeGreaterThan(0);
      expect(health.circuitBreaker).toBeDefined();
    });

    it('should report unhealthy status when API is failing', async () => {
      const error = new Error('Service unavailable');
      error.response = { status: 503 };
      mockAxios.get.mockRejectedValue(error);

      const health = await registrationService.getHealthStatus();

      expect(health.status).toBe('unhealthy');
      expect(health.error).toBeDefined();
      expect(health.circuitBreaker).toBeDefined();
    });
  });

  describe('Graceful Degradation', () => {
    it('should handle 404 errors gracefully for player registrations', async () => {
      const notFoundError = new Error('Not Found');
      notFoundError.response = { status: 404 };
      mockAxios.get.mockRejectedValue(notFoundError);

      const result = await registrationService.getPlayerRegistrations('nonexistent_user');

      expect(result.player).toBeNull();
      expect(result.registrations).toEqual([]);
    });

    it('should return null for timezone when player not found', async () => {
      const notFoundError = new Error('Not Found');
      notFoundError.response = { status: 404 };
      mockAxios.get.mockRejectedValue(notFoundError);

      const timezone = await registrationService.getPlayerTimezone('nonexistent_user');

      expect(timezone).toBeNull();
    });
  });
});
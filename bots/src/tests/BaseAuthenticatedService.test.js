import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { BaseAuthenticatedService } from '../services/BaseAuthenticatedService.js';
import { tokenManager } from '../utils/TokenManager.js';

// Mock axios
vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() }
      },
      get: vi.fn(),
      post: vi.fn()
    }))
  }
}));

// Mock tokenManager
vi.mock('../utils/TokenManager.js', () => ({
  tokenManager: {
    getAuthHeader: vi.fn(),
    clearToken: vi.fn(),
    getTokenStatus: vi.fn()
  }
}));

describe('BaseAuthenticatedService', () => {
  let service;

  beforeEach(() => {
    service = new BaseAuthenticatedService('TestService');
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Constructor', () => {
    it('should initialize with correct service name', () => {
      expect(service.serviceName).toBe('TestService');
    });

    it('should setup axios client with base configuration', () => {
      expect(service.apiClient).toBeDefined();
    });
  });

  describe('Authentication Status', () => {
    it('should return authentication status', async () => {
      const mockTokenStatus = {
        hasToken: true,
        isValid: true,
        expiryTime: '2025-08-24T17:00:00.000Z',
        timeUntilExpiry: 3600000
      };

      tokenManager.getTokenStatus.mockReturnValue(mockTokenStatus);

      const authStatus = await service.getAuthStatus();
      expect(authStatus).toEqual(mockTokenStatus);
    });

    it('should handle authentication errors', async () => {
      tokenManager.getTokenStatus.mockImplementation(() => {
        throw new Error('Token error');
      });

      const authStatus = await service.getAuthStatus();
      expect(authStatus).toEqual({
        hasToken: false,
        isValid: false,
        error: 'Token error'
      });
    });
  });

  describe('Health Status', () => {
    it('should return healthy status with authentication info', async () => {
      const mockTokenStatus = {
        hasToken: true,
        isValid: true,
        expiryTime: '2025-08-24T17:00:00.000Z',
        timeUntilExpiry: 3600000
      };

      tokenManager.getTokenStatus.mockReturnValue(mockTokenStatus);

      const healthStatus = await service.getHealthStatus();
      expect(healthStatus.status).toBe('healthy');
      expect(healthStatus.authentication).toEqual(mockTokenStatus);
      expect(healthStatus.timestamp).toBeDefined();
      expect(healthStatus.responseTime).toBeGreaterThanOrEqual(0);
    });


  });

  describe('Error Handling', () => {
    it('should process API errors correctly', () => {
      const mockError = new Error('API Error');
      mockError.response = { status: 500 };

      const processedError = service.handleApiError(mockError, 'test_context');
      expect(processedError).toBeInstanceOf(Error);
      expect(processedError.originalError).toBe(mockError);
    });
  });
});
import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { TokenManager } from '../utils/TokenManager.js';
import { config } from '../config/config.js';

// Mock fetch globally
global.fetch = vi.fn();

describe('TokenManager', () => {
  let tokenManager;

  beforeEach(() => {
    tokenManager = new TokenManager();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Token Validation', () => {
    it('should return false for invalid token when no token exists', () => {
      expect(tokenManager.isTokenValid()).toBe(false);
    });

    it('should return false for expired token', () => {
      tokenManager.token = 'test-token';
      tokenManager.tokenExpiry = Date.now() - 1000; // Expired 1 second ago
      
      expect(tokenManager.isTokenValid()).toBe(false);
    });

    it('should return false for token expiring within buffer time', () => {
      tokenManager.token = 'test-token';
      // Token expires in 2 minutes, but buffer is 5 minutes
      tokenManager.tokenExpiry = Date.now() + (2 * 60 * 1000);
      
      expect(tokenManager.isTokenValid()).toBe(false);
    });

    it('should return true for valid token with sufficient time remaining', () => {
      tokenManager.token = 'test-token';
      // Token expires in 10 minutes, buffer is 5 minutes
      tokenManager.tokenExpiry = Date.now() + (10 * 60 * 1000);
      
      expect(tokenManager.isTokenValid()).toBe(true);
    });
  });

  describe('Token Request', () => {
    it('should successfully request a new token', async () => {
      const mockTokenResponse = {
        access_token: 'new-access-token',
        expires_in: 3600,
        token_type: 'Bearer'
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(mockTokenResponse)
      });

      const tokenData = await tokenManager.requestToken();

      expect(tokenData).toEqual(mockTokenResponse);
      expect(global.fetch).toHaveBeenCalledWith(
        config.api.oauth.tokenUrl,
        expect.objectContaining({
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json'
          }
        })
      );
    });

    it('should throw error for failed token request', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
        statusText: 'Unauthorized',
        text: () => Promise.resolve('Invalid credentials')
      });

      await expect(tokenManager.requestToken()).rejects.toThrow('Token request failed: 401 Unauthorized');
    });

    it('should throw error for invalid token response', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ error: 'invalid_grant' })
      });

      await expect(tokenManager.requestToken()).rejects.toThrow('Invalid token response: missing access_token');
    });
  });

  describe('Token Refresh', () => {
    it('should refresh token and set expiry time', async () => {
      const mockTokenResponse = {
        access_token: 'refreshed-token',
        expires_in: 3600
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(mockTokenResponse)
      });

      await tokenManager.refreshToken();

      expect(tokenManager.token).toBe('refreshed-token');
      expect(tokenManager.tokenExpiry).toBeGreaterThan(Date.now());
    });

    it('should clear token on refresh failure', async () => {
      // Create a new token manager with no retries for this test
      const testTokenManager = new TokenManager();
      testTokenManager.retryHandler = {
        executeWithRetry: vi.fn().mockRejectedValue(new Error('Network error'))
      };

      testTokenManager.token = 'existing-token';
      testTokenManager.tokenExpiry = Date.now() + 1000;

      await expect(testTokenManager.refreshToken()).rejects.toThrow();
      expect(testTokenManager.token).toBeNull();
      expect(testTokenManager.tokenExpiry).toBeNull();
    });
  });

  describe('Get Token', () => {
    it('should return existing valid token', async () => {
      tokenManager.token = 'valid-token';
      tokenManager.tokenExpiry = Date.now() + (10 * 60 * 1000); // 10 minutes

      const token = await tokenManager.getToken();
      expect(token).toBe('valid-token');
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it('should refresh token when invalid', async () => {
      const mockTokenResponse = {
        access_token: 'new-token',
        expires_in: 3600
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(mockTokenResponse)
      });

      const token = await tokenManager.getToken();
      expect(token).toBe('new-token');
      expect(global.fetch).toHaveBeenCalled();
    });
  });

  describe('Authorization Header', () => {
    it('should return proper authorization header', async () => {
      tokenManager.token = 'test-token';
      tokenManager.tokenExpiry = Date.now() + (10 * 60 * 1000);

      const authHeader = await tokenManager.getAuthHeader();
      expect(authHeader).toEqual({
        'Authorization': 'Bearer test-token'
      });
    });
  });

  describe('Token Status', () => {
    it('should return correct token status', () => {
      tokenManager.token = 'test-token';
      tokenManager.tokenExpiry = Date.now() + (10 * 60 * 1000);

      const status = tokenManager.getTokenStatus();
      expect(status.hasToken).toBe(true);
      expect(status.isValid).toBe(true);
      expect(status.expiryTime).toBeDefined();
      expect(status.timeUntilExpiry).toBeGreaterThan(0);
    });

    it('should return correct status for no token', () => {
      const status = tokenManager.getTokenStatus();
      expect(status.hasToken).toBe(false);
      expect(status.isValid).toBe(false);
      expect(status.expiryTime).toBeNull();
      expect(status.timeUntilExpiry).toBe(0);
    });
  });

  describe('Clear Token', () => {
    it('should clear all token data', () => {
      tokenManager.token = 'test-token';
      tokenManager.tokenExpiry = Date.now() + 1000;
      tokenManager.refreshPromise = Promise.resolve();

      tokenManager.clearToken();

      expect(tokenManager.token).toBeNull();
      expect(tokenManager.tokenExpiry).toBeNull();
      expect(tokenManager.refreshPromise).toBeNull();
    });
  });
});
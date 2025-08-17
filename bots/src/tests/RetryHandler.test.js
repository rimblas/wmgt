import { describe, it, expect, beforeEach, vi } from 'vitest';
import { RetryHandler } from '../utils/RetryHandler.js';

describe('RetryHandler', () => {
  let retryHandler;
  let mockLogger;

  beforeEach(() => {
    mockLogger = {
      error: vi.fn(),
      warn: vi.fn(),
      info: vi.fn(),
      debug: vi.fn(),
      performance: vi.fn(),
      retryAttempt: vi.fn()
    };
    
    retryHandler = new RetryHandler(mockLogger, {
      maxRetries: 3,
      baseDelay: 100, // Shorter delays for testing
      maxDelay: 1000,
      jitter: false // Disable jitter for predictable tests
    });
  });

  describe('executeWithRetry', () => {
    it('should succeed on first attempt', async () => {
      const mockOperation = vi.fn().mockResolvedValue('success');
      
      const result = await retryHandler.executeWithRetry(mockOperation, {}, 'test_operation');
      
      expect(result).toBe('success');
      expect(mockOperation).toHaveBeenCalledTimes(1);
      expect(mockLogger.performance).toHaveBeenCalled();
    });

    it('should retry on retryable errors', async () => {
      const mockOperation = vi.fn()
        .mockRejectedValueOnce(new Error('Network error'))
        .mockRejectedValueOnce(new Error('Network error'))
        .mockResolvedValue('success');
      
      const result = await retryHandler.executeWithRetry(mockOperation, {}, 'test_operation');
      
      expect(result).toBe('success');
      expect(mockOperation).toHaveBeenCalledTimes(3);
      expect(mockLogger.retryAttempt).toHaveBeenCalledTimes(2);
    });

    it('should not retry non-retryable errors', async () => {
      const error = new Error('Bad request');
      error.response = { status: 400 };
      const mockOperation = vi.fn().mockRejectedValue(error);
      
      await expect(
        retryHandler.executeWithRetry(mockOperation, {}, 'test_operation')
      ).rejects.toThrow('Bad request');
      
      expect(mockOperation).toHaveBeenCalledTimes(1);
      expect(mockLogger.retryAttempt).not.toHaveBeenCalled();
    });

    it('should exhaust retries and throw last error', async () => {
      const error = new Error('Server error');
      error.response = { status: 500 };
      const mockOperation = vi.fn().mockRejectedValue(error);
      
      await expect(
        retryHandler.executeWithRetry(mockOperation, {}, 'test_operation')
      ).rejects.toThrow('Server error');
      
      expect(mockOperation).toHaveBeenCalledTimes(4); // Initial + 3 retries
      expect(mockLogger.retryAttempt).toHaveBeenCalledTimes(3);
    });

    it('should respect noRetry flag', async () => {
      const error = new Error('No retry error');
      error.noRetry = true;
      const mockOperation = vi.fn().mockRejectedValue(error);
      
      await expect(
        retryHandler.executeWithRetry(mockOperation, {}, 'test_operation')
      ).rejects.toThrow('No retry error');
      
      expect(mockOperation).toHaveBeenCalledTimes(1);
    });
  });

  describe('shouldRetry', () => {
    it('should not retry if max attempts exceeded', () => {
      const error = new Error('Server error');
      error.response = { status: 500 };
      
      const shouldRetry = retryHandler.shouldRetry(error, 4, { maxRetries: 3 });
      expect(shouldRetry).toBe(false);
    });

    it('should retry server errors', () => {
      const error = new Error('Server error');
      error.response = { status: 500 };
      
      const shouldRetry = retryHandler.shouldRetry(error, 1, { maxRetries: 3 });
      expect(shouldRetry).toBe(true);
    });

    it('should retry network errors', () => {
      const error = new Error('Connection refused');
      error.code = 'ECONNREFUSED';
      
      const shouldRetry = retryHandler.shouldRetry(error, 1, { maxRetries: 3 });
      expect(shouldRetry).toBe(true);
    });

    it('should retry timeout errors', () => {
      const error = new Error('Request timeout');
      error.name = 'TimeoutError';
      
      const shouldRetry = retryHandler.shouldRetry(error, 1, { maxRetries: 3 });
      expect(shouldRetry).toBe(true);
    });

    it('should not retry validation errors', () => {
      const error = new Error('Validation failed');
      error.name = 'ValidationError';
      
      const shouldRetry = retryHandler.shouldRetry(error, 1, { maxRetries: 3 });
      expect(shouldRetry).toBe(false);
    });

    it('should retry rate limit errors', () => {
      const error = new Error('Rate limited');
      error.response = { status: 429 };
      
      const shouldRetry = retryHandler.shouldRetry(error, 1, { maxRetries: 3 });
      expect(shouldRetry).toBe(true);
    });
  });

  describe('calculateDelay', () => {
    it('should calculate exponential backoff delay', () => {
      const config = { baseDelay: 1000, backoffMultiplier: 2, maxDelay: 10000, jitter: false };
      
      expect(retryHandler.calculateDelay(0, config, new Error())).toBe(1000);
      expect(retryHandler.calculateDelay(1, config, new Error())).toBe(2000);
      expect(retryHandler.calculateDelay(2, config, new Error())).toBe(4000);
    });

    it('should respect maximum delay', () => {
      const config = { baseDelay: 1000, backoffMultiplier: 2, maxDelay: 3000, jitter: false };
      
      expect(retryHandler.calculateDelay(5, config, new Error())).toBe(3000);
    });

    it('should use retry-after header when available', () => {
      const error = new Error('Rate limited');
      error.response = { headers: { 'retry-after': '5' } };
      const config = { baseDelay: 1000, maxDelay: 10000 };
      
      const delay = retryHandler.calculateDelay(0, config, error);
      expect(delay).toBe(5000);
    });

    it('should use x-ratelimit-reset header when available', () => {
      const futureTime = Math.floor(Date.now() / 1000) + 3;
      const error = new Error('Rate limited');
      error.response = { headers: { 'x-ratelimit-reset': futureTime.toString() } };
      const config = { baseDelay: 1000, maxDelay: 10000 };
      
      const delay = retryHandler.calculateDelay(0, config, error);
      expect(delay).toBeGreaterThan(0);
      expect(delay).toBeLessThan(4000);
    });

    it('should add jitter when enabled', () => {
      const config = { 
        baseDelay: 1000, 
        backoffMultiplier: 2, 
        maxDelay: 10000, 
        jitter: true,
        jitterFactor: 0.1
      };
      
      const delay1 = retryHandler.calculateDelay(0, config, new Error());
      const delay2 = retryHandler.calculateDelay(0, config, new Error());
      
      // With jitter, delays should be different (most of the time)
      // We'll just check they're in the expected range
      expect(delay1).toBeGreaterThan(900);
      expect(delay1).toBeLessThan(1100);
      expect(delay2).toBeGreaterThan(900);
      expect(delay2).toBeLessThan(1100);
    });
  });

  describe('circuit breaker', () => {
    it('should open circuit after threshold failures', async () => {
      const error = new Error('Server error');
      error.response = { status: 500 };
      const mockOperation = vi.fn().mockRejectedValue(error);
      
      // Configure with low threshold for testing
      const handler = new RetryHandler(mockLogger, {
        maxRetries: 0, // No retries to speed up test
        circuitBreakerThreshold: 2
      });
      
      // First failure
      await expect(handler.executeWithRetry(mockOperation, {}, 'test')).rejects.toThrow();
      
      // Second failure should open circuit
      await expect(handler.executeWithRetry(mockOperation, {}, 'test')).rejects.toThrow();
      
      // Third attempt should be blocked by circuit breaker
      const mockOperation2 = vi.fn().mockResolvedValue('success');
      await expect(handler.executeWithRetry(mockOperation2, {}, 'test')).rejects.toThrow('Circuit breaker is OPEN');
      
      expect(mockOperation2).not.toHaveBeenCalled();
    });

    it('should reset circuit breaker on success', async () => {
      const handler = new RetryHandler(mockLogger, {
        circuitBreakerThreshold: 3
      });
      
      // Record some failures
      handler.recordFailure();
      handler.recordFailure();
      
      expect(handler.circuitBreaker.failures).toBe(2);
      
      // Reset on success
      handler.resetCircuitBreaker();
      
      expect(handler.circuitBreaker.failures).toBe(0);
      expect(handler.circuitBreaker.state).toBe('CLOSED');
    });

    it('should provide circuit breaker status', () => {
      const status = retryHandler.getCircuitBreakerStatus();
      
      expect(status).toHaveProperty('state');
      expect(status).toHaveProperty('failures');
      expect(status).toHaveProperty('lastFailureTime');
      expect(status).toHaveProperty('isOpen');
    });
  });

  describe('wrap', () => {
    it('should create wrapped function with retry logic', async () => {
      const originalFunction = vi.fn()
        .mockRejectedValueOnce(new Error('Temporary error'))
        .mockResolvedValue('success');
      
      const wrappedFunction = retryHandler.wrap(originalFunction, {}, 'wrapped_test');
      
      const result = await wrappedFunction('arg1', 'arg2');
      
      expect(result).toBe('success');
      expect(originalFunction).toHaveBeenCalledTimes(2);
      expect(originalFunction).toHaveBeenCalledWith('arg1', 'arg2');
    });
  });

  describe('static factory methods', () => {
    it('should create API retry handler with appropriate defaults', () => {
      const handler = RetryHandler.forApiCalls(mockLogger);
      
      expect(handler.options.maxRetries).toBe(3);
      expect(handler.options.baseDelay).toBe(1000);
      expect(handler.options.circuitBreakerThreshold).toBe(5);
    });

    it('should create Discord API retry handler with appropriate defaults', () => {
      const handler = RetryHandler.forDiscordApi(mockLogger);
      
      expect(handler.options.maxRetries).toBe(2);
      expect(handler.options.baseDelay).toBe(500);
      expect(handler.options.circuitBreakerThreshold).toBe(10);
    });
  });
});
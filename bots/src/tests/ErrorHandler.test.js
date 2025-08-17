import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ErrorHandler } from '../utils/ErrorHandler.js';
import { Logger } from '../utils/Logger.js';

describe('ErrorHandler', () => {
  let errorHandler;
  let mockLogger;

  beforeEach(() => {
    mockLogger = {
      error: vi.fn(),
      warn: vi.fn(),
      info: vi.fn(),
      debug: vi.fn()
    };
    errorHandler = new ErrorHandler(mockLogger);
  });

  describe('classifyError', () => {
    it('should classify network errors correctly', () => {
      const error = new Error('Connection refused');
      error.code = 'ECONNREFUSED';
      
      const errorType = errorHandler.classifyError(error);
      expect(errorType).toBe('CONNECTION_ERROR');
    });

    it('should classify rate limit errors correctly', () => {
      const error = new Error('Rate limited');
      error.response = { status: 429 };
      
      const errorType = errorHandler.classifyError(error);
      expect(errorType).toBe('RATE_LIMITED');
    });

    it('should classify API error codes correctly', () => {
      const error = new Error('Already registered');
      error.response = {
        status: 400,
        data: { error_code: 'ALREADY_REGISTERED' }
      };
      
      const errorType = errorHandler.classifyError(error);
      expect(errorType).toBe('ALREADY_REGISTERED');
    });

    it('should classify server errors correctly', () => {
      const error = new Error('Internal server error');
      error.response = { status: 500 };
      
      const errorType = errorHandler.classifyError(error);
      expect(errorType).toBe('SERVICE_UNAVAILABLE');
    });

    it('should classify timezone errors correctly', () => {
      const error = new Error('Invalid timezone provided');
      
      const errorType = errorHandler.classifyError(error);
      expect(errorType).toBe('INVALID_TIMEZONE');
    });

    it('should default to unknown error for unrecognized errors', () => {
      const error = new Error('Some random error');
      
      const errorType = errorHandler.classifyError(error);
      expect(errorType).toBe('UNKNOWN_ERROR');
    });
  });

  describe('shouldRetryError', () => {
    it('should not retry client errors except rate limits', () => {
      const error400 = new Error('Bad request');
      error400.response = { status: 400 };
      expect(errorHandler.shouldRetryError(error400)).toBe(false);

      const error429 = new Error('Rate limited');
      error429.response = { status: 429 };
      expect(errorHandler.shouldRetryError(error429)).toBe(true);
    });

    it('should retry server errors', () => {
      const error = new Error('Internal server error');
      error.response = { status: 500 };
      expect(errorHandler.shouldRetryError(error)).toBe(true);
    });

    it('should retry network errors', () => {
      const error = new Error('Connection refused');
      error.code = 'ECONNREFUSED';
      expect(errorHandler.shouldRetryError(error)).toBe(true);
    });

    it('should not retry validation errors', () => {
      const error = new Error('Invalid timezone');
      error.response = {
        data: { error_code: 'INVALID_TIMEZONE' }
      };
      expect(errorHandler.shouldRetryError(error)).toBe(false);
    });
  });

  describe('getRetryDelay', () => {
    it('should extract retry-after header', () => {
      const error = new Error('Rate limited');
      error.response = {
        headers: { 'retry-after': '5' }
      };
      
      const delay = errorHandler.getRetryDelay(error);
      expect(delay).toBe(5000);
    });

    it('should extract x-ratelimit-reset header', () => {
      const futureTime = Math.floor(Date.now() / 1000) + 10;
      const error = new Error('Rate limited');
      error.response = {
        headers: { 'x-ratelimit-reset': futureTime.toString() }
      };
      
      const delay = errorHandler.getRetryDelay(error);
      expect(delay).toBeGreaterThan(0);
      expect(delay).toBeLessThan(11000);
    });

    it('should return 0 for errors without rate limit headers', () => {
      const error = new Error('Some error');
      const delay = errorHandler.getRetryDelay(error);
      expect(delay).toBe(0);
    });
  });

  describe('handleError', () => {
    it('should generate error ID and log error', () => {
      const error = new Error('Test error');
      const result = errorHandler.handleError(error, 'test_context');
      
      expect(result.errorId).toMatch(/^ERR_[A-Z0-9_]+$/);
      expect(result.errorType).toBe('UNKNOWN_ERROR');
      expect(result.embed).toBeDefined();
      expect(mockLogger.error).toHaveBeenCalled();
    });

    it('should include metadata in logging', () => {
      const error = new Error('Test error');
      const metadata = { userId: '123', action: 'test' };
      
      errorHandler.handleError(error, 'test_context', metadata);
      
      expect(mockLogger.error).toHaveBeenCalledWith(
        'Error occurred',
        expect.objectContaining({
          metadata: expect.objectContaining(metadata)
        })
      );
    });

    it('should create appropriate embed for different error types', () => {
      const error = new Error('Registration closed');
      error.response = {
        data: { error_code: 'REGISTRATION_CLOSED' }
      };
      
      const result = errorHandler.handleError(error);
      
      expect(result.embed.data.title).toBe('🔒 Registration Closed');
      expect(result.embed.data.color).toBe(0xFFA500);
    });
  });

  describe('handleInteractionError', () => {
    it('should handle interaction errors and reply appropriately', async () => {
      const mockInteraction = {
        user: { id: '123' },
        commandName: 'test',
        guildId: '456',
        replied: false,
        deferred: false,
        reply: vi.fn().mockResolvedValue(undefined)
      };

      const error = new Error('Test error');
      
      await errorHandler.handleInteractionError(error, mockInteraction, 'test');
      
      expect(mockInteraction.reply).toHaveBeenCalledWith({
        embeds: expect.any(Array),
        ephemeral: true
      });
    });

    it('should use editReply for deferred interactions', async () => {
      const mockInteraction = {
        user: { id: '123' },
        commandName: 'test',
        guildId: '456',
        replied: false,
        deferred: true,
        editReply: vi.fn().mockResolvedValue(undefined)
      };

      const error = new Error('Test error');
      
      await errorHandler.handleInteractionError(error, mockInteraction, 'test');
      
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: expect.any(Array),
        ephemeral: true
      });
    });

    it('should handle reply failures gracefully', async () => {
      const mockInteraction = {
        user: { id: '123' },
        commandName: 'test',
        guildId: '456',
        replied: false,
        deferred: false,
        reply: vi.fn().mockRejectedValue(new Error('Reply failed'))
      };

      const error = new Error('Test error');
      
      // Should not throw
      await expect(
        errorHandler.handleInteractionError(error, mockInteraction, 'test')
      ).resolves.toBeUndefined();
      
      expect(mockLogger.error).toHaveBeenCalledWith(
        'Failed to send error response to user',
        expect.any(Object)
      );
    });
  });

  describe('createErrorEmbed', () => {
    it('should create error embed with correct properties', () => {
      const embed = errorHandler.createErrorEmbed(
        'Test Title',
        'Test Message',
        'Test Suggestion',
        0xFF0000
      );
      
      expect(embed.data.title).toBe('Test Title');
      expect(embed.data.description).toBe('Test Message');
      expect(embed.data.footer.text).toBe('Test Suggestion');
      expect(embed.data.color).toBe(0xFF0000);
    });

    it('should create embed without suggestion', () => {
      const embed = errorHandler.createErrorEmbed('Title', 'Message');
      
      expect(embed.data.title).toBe('Title');
      expect(embed.data.description).toBe('Message');
      expect(embed.data.footer).toBeUndefined();
    });
  });

  describe('createWarningEmbed', () => {
    it('should create warning embed with orange color', () => {
      const embed = errorHandler.createWarningEmbed('Warning', 'Message');
      expect(embed.data.color).toBe(0xFFA500);
    });
  });

  describe('createInfoEmbed', () => {
    it('should create info embed with blue color', () => {
      const embed = errorHandler.createInfoEmbed('Info', 'Message');
      expect(embed.data.color).toBe(0x0099FF);
    });
  });

  describe('generateErrorId', () => {
    it('should generate unique error IDs', () => {
      const id1 = errorHandler.generateErrorId();
      const id2 = errorHandler.generateErrorId();
      
      expect(id1).toMatch(/^ERR_[A-Z0-9_]+$/);
      expect(id2).toMatch(/^ERR_[A-Z0-9_]+$/);
      expect(id1).not.toBe(id2);
    });
  });
});
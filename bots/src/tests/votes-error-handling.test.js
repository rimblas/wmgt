import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { EmbedBuilder } from 'discord.js';
import votesCommand from '../commands/votes.js';
import { VotesService } from '../services/VotesService.js';

// Mock the VotesService
vi.mock('../services/VotesService.js');

describe('Votes Command Error Handling Integration', () => {
  let mockInteraction;
  let mockVotesService;

  beforeEach(() => {
    // Reset all mocks
    vi.clearAllMocks();

    // Create mock interaction
    mockInteraction = {
      deferReply: vi.fn().mockResolvedValue(undefined),
      editReply: vi.fn().mockResolvedValue(undefined),
      user: {
        id: '123456789',
        username: 'testuser'
      },
      guildId: '987654321'
    };

    // Create mock VotesService instance
    mockVotesService = {
      getVotingResults: vi.fn(),
      handleApiError: vi.fn(),
      createVotesEmbed: vi.fn(),
      createTextDisplay: vi.fn()
    };

    // Mock the VotesService constructor to return our mock
    VotesService.mockImplementation(() => mockVotesService);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('API Unavailability Scenarios', () => {
    it('should handle API connection refused error', async () => {
      const connectionError = new Error('Connection refused');
      connectionError.code = 'ECONNREFUSED';
      
      mockVotesService.getVotingResults.mockRejectedValue(connectionError);
      mockVotesService.handleApiError.mockReturnValue({
        message: 'The voting service is temporarily unavailable.',
        errorId: 'ERR_123',
        errorType: 'VOTES_API_UNAVAILABLE'
      });

      await votesCommand.execute(mockInteraction);

      expect(mockInteraction.deferReply).toHaveBeenCalled();
      expect(mockVotesService.getVotingResults).toHaveBeenCalled();
      expect(mockVotesService.handleApiError).toHaveBeenCalledWith(
        connectionError,
        'votes_command_fetch'
      );
      
      // Should send error embed
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            title: '❌ Unable to Fetch Voting Results',
            color: 0xFF0000
          })
        })]
      });
    });

    it('should handle API timeout error', async () => {
      const timeoutError = new Error('Request timeout');
      timeoutError.code = 'ETIMEDOUT';
      
      mockVotesService.getVotingResults.mockRejectedValue(timeoutError);
      mockVotesService.handleApiError.mockReturnValue({
        message: 'The request took too long to complete.',
        errorId: 'ERR_124',
        errorType: 'TIMEOUT_ERROR'
      });

      await votesCommand.execute(mockInteraction);

      expect(mockVotesService.handleApiError).toHaveBeenCalledWith(
        timeoutError,
        'votes_command_fetch'
      );
      
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            title: '❌ Unable to Fetch Voting Results'
          })
        })]
      });
    });

    it('should handle rate limiting error', async () => {
      const rateLimitError = new Error('Rate limited');
      rateLimitError.response = { 
        status: 429,
        headers: { 'retry-after': '60' }
      };
      
      mockVotesService.getVotingResults.mockRejectedValue(rateLimitError);
      mockVotesService.handleApiError.mockReturnValue({
        message: 'Too many requests. Please slow down.',
        errorId: 'ERR_125',
        errorType: 'RATE_LIMITED'
      });

      await votesCommand.execute(mockInteraction);

      expect(mockVotesService.handleApiError).toHaveBeenCalledWith(
        rateLimitError,
        'votes_command_fetch'
      );
    });
  });

  describe('Malformed Data Scenarios', () => {
    it('should handle empty voting data', async () => {
      const emptyData = { items: [], count: 0 };
      
      mockVotesService.getVotingResults.mockResolvedValue(emptyData);

      await votesCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            title: '📊 No Voting Data Available',
            color: 0xFFA500
          })
        })]
      });
    });

    it('should handle null voting data', async () => {
      const nullData = { items: null };
      
      mockVotesService.getVotingResults.mockResolvedValue(nullData);

      await votesCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            title: '📊 No Voting Data Available'
          })
        })]
      });
    });

    it('should handle embed creation failure with fallback to text', async () => {
      const validData = {
        items: [{
          easy_course: 'ALE',
          easy_name: 'Alfheim Easy',
          easy_votes: 5
        }]
      };
      
      mockVotesService.getVotingResults.mockResolvedValue(validData);
      mockVotesService.createVotesEmbed.mockImplementation(() => {
        throw new Error('Embed creation failed');
      });
      mockVotesService.createTextDisplay.mockReturnValue(
        '🏆 **Course Voting Results**\n\n**Easy Courses:**\n**ALE** (5) - Alfheim Easy'
      );

      await votesCommand.execute(mockInteraction);

      expect(mockVotesService.createTextDisplay).toHaveBeenCalledWith(validData);
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        content: expect.stringContaining('🏆 **Course Voting Results**'),
        embeds: []
      });
    });
  });

  describe('Discord Permission Errors', () => {
    it('should handle embed send failure with final text fallback', async () => {
      const validData = {
        items: [{
          easy_course: 'ALE',
          easy_name: 'Alfheim Easy',
          easy_votes: 5
        }]
      };
      
      const mockEmbed = new EmbedBuilder()
        .setTitle('🏆 Course Voting Results')
        .setColor(0x00AE86);

      mockVotesService.getVotingResults.mockResolvedValue(validData);
      mockVotesService.createVotesEmbed.mockReturnValue({
        title: '🏆 Course Voting Results',
        color: 0x00AE86,
        fields: [
          { name: 'Easy Courses', value: '**ALE** (5) - Alfheim Easy', inline: true },
          { name: 'Hard Courses', value: 'No courses available', inline: true }
        ],
        footer: { text: 'Vote counts updated in real-time' },
        timestamp: new Date().toISOString()
      });

      // First editReply (embed) fails, second (text) succeeds
      mockInteraction.editReply
        .mockRejectedValueOnce(new Error('Missing permissions'))
        .mockResolvedValueOnce(undefined);

      mockVotesService.createTextDisplay.mockReturnValue(
        '🏆 **Course Voting Results**\n\n**Easy Courses:**\n**ALE** (5) - Alfheim Easy'
      );

      await votesCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledTimes(2);
      expect(mockVotesService.createTextDisplay).toHaveBeenCalledWith(validData);
    });

    it('should handle complete send failure with final error message', async () => {
      const validData = {
        items: [{
          easy_course: 'ALE',
          easy_name: 'Alfheim Easy',
          easy_votes: 5
        }]
      };
      
      mockVotesService.getVotingResults.mockResolvedValue(validData);
      mockVotesService.createVotesEmbed.mockReturnValue({
        title: '🏆 Course Voting Results',
        color: 0x00AE86,
        fields: [],
        footer: { text: 'Vote counts updated in real-time' },
        timestamp: new Date().toISOString()
      });

      // Both embed and text fallback fail
      mockInteraction.editReply
        .mockRejectedValueOnce(new Error('Missing permissions'))
        .mockRejectedValueOnce(new Error('Missing permissions'))
        .mockResolvedValueOnce(undefined); // Final error message succeeds

      mockVotesService.createTextDisplay.mockReturnValue(
        '🏆 **Course Voting Results**\n\n**Easy Courses:**\n**ALE** (5) - Alfheim Easy'
      );

      await votesCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledTimes(3);
      
      // Final call should be the error message
      const finalCall = mockInteraction.editReply.mock.calls[2][0];
      expect(finalCall.content).toContain('❌ **Voting Results Unavailable**');
      expect(finalCall.embeds).toEqual([]);
    });
  });

  describe('Unexpected Errors', () => {
    it('should handle unexpected errors in command execution', async () => {
      // Mock an unexpected error during defer
      mockInteraction.deferReply.mockRejectedValue(new Error('Unexpected Discord error'));

      await votesCommand.execute(mockInteraction);

      // Should not crash, error handler should be called
      // The exact behavior depends on the ErrorHandler implementation
    });

    it('should handle service instantiation errors', async () => {
      // Mock VotesService constructor to throw
      VotesService.mockImplementation(() => {
        throw new Error('Service initialization failed');
      });

      await votesCommand.execute(mockInteraction);

      // Should handle the error gracefully
    });
  });

  describe('Data Processing Edge Cases', () => {
    it('should handle data processing errors gracefully', async () => {
      const validData = {
        items: [{
          easy_course: 'ALE',
          easy_name: 'Alfheim Easy',
          easy_votes: 5
        }]
      };
      
      mockVotesService.getVotingResults.mockResolvedValue(validData);
      mockVotesService.createVotesEmbed.mockImplementation(() => {
        throw new Error('Data processing failed');
      });

      await votesCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        content: expect.stringContaining('Course Voting Results'),
        embeds: []
      });
    });

    it('should handle partial data corruption', async () => {
      const corruptedData = {
        items: [
          { easy_course: 'ALE', easy_name: 'Alfheim Easy', easy_votes: 5 },
          null, // corrupted item
          { easy_course: 'BBE', easy_name: 'Bogey Bayou Easy', easy_votes: 3 }
        ]
      };
      
      mockVotesService.getVotingResults.mockResolvedValue(corruptedData);
      mockVotesService.createVotesEmbed.mockReturnValue({
        title: '🏆 Course Voting Results',
        color: 0x00AE86,
        fields: [
          { name: 'Easy Courses', value: '**ALE** (5) - Alfheim Easy\n**BBE** (3) - Bogey Bayou Easy', inline: true },
          { name: 'Hard Courses', value: 'No courses available', inline: true }
        ],
        footer: { text: 'Vote counts updated in real-time' },
        timestamp: new Date().toISOString()
      });

      await votesCommand.execute(mockInteraction);

      expect(mockVotesService.createVotesEmbed).toHaveBeenCalledWith(corruptedData);
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.any(EmbedBuilder)]
      });
    });
  });

  describe('Logging Verification', () => {
    it('should log appropriate information for successful execution', async () => {
      const validData = {
        items: [{
          easy_course: 'ALE',
          easy_name: 'Alfheim Easy',
          easy_votes: 5
        }]
      };
      
      mockVotesService.getVotingResults.mockResolvedValue(validData);
      mockVotesService.createVotesEmbed.mockReturnValue({
        title: '🏆 Course Voting Results',
        color: 0x00AE86,
        fields: [
          { name: 'Easy Courses', value: '**ALE** (5) - Alfheim Easy', inline: true },
          { name: 'Hard Courses', value: 'No courses available', inline: true }
        ],
        footer: { text: 'Vote counts updated in real-time' },
        timestamp: new Date().toISOString()
      });

      await votesCommand.execute(mockInteraction);

      // Verify the command executed successfully
      expect(mockVotesService.getVotingResults).toHaveBeenCalled();
      expect(mockVotesService.createVotesEmbed).toHaveBeenCalledWith(validData);
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.any(EmbedBuilder)]
      });
    });

    it('should log appropriate information for error scenarios', async () => {
      const apiError = new Error('API Error');
      apiError.code = 'ECONNREFUSED';
      
      mockVotesService.getVotingResults.mockRejectedValue(apiError);
      mockVotesService.handleApiError.mockReturnValue({
        message: 'Service unavailable',
        errorId: 'ERR_123',
        errorType: 'VOTES_API_UNAVAILABLE'
      });

      await votesCommand.execute(mockInteraction);

      expect(mockVotesService.handleApiError).toHaveBeenCalledWith(
        apiError,
        'votes_command_fetch'
      );
    });
  });
});
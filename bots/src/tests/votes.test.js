import { describe, it, expect, vi, beforeEach } from 'vitest';
import { SlashCommandBuilder, EmbedBuilder } from 'discord.js';
import votesCommand from '../commands/votes.js';

// Mock the VotesService
vi.mock('../services/VotesService.js', () => ({
  VotesService: vi.fn().mockImplementation(() => ({
    getVotingResults: vi.fn(),
    handleApiError: vi.fn(),
    createVotesEmbed: vi.fn()
  }))
}));

// Mock the logger
vi.mock('../utils/Logger.js', () => ({
  logger: {
    child: vi.fn(() => ({
      info: vi.fn(),
      debug: vi.fn(),
      error: vi.fn()
    }))
  }
}));

// Mock the ErrorHandler
vi.mock('../utils/ErrorHandler.js', () => ({
  ErrorHandler: vi.fn().mockImplementation(() => ({
    handleInteractionError: vi.fn()
  }))
}));

describe('votes command', () => {
  let mockInteraction;
  let mockVotesService;

  beforeEach(async () => {
    // Reset all mocks
    vi.clearAllMocks();

    // Create mock interaction
    mockInteraction = {
      deferReply: vi.fn().mockResolvedValue(undefined),
      editReply: vi.fn().mockResolvedValue(undefined),
      user: {
        id: 'test-user-id',
        username: 'testuser'
      },
      guildId: 'test-guild-id'
    };

    // Get the mocked VotesService instance
    const { VotesService } = await import('../services/VotesService.js');
    mockVotesService = new VotesService();
  });

  describe('command definition', () => {
    it('should have correct command data', () => {
      expect(votesCommand.data).toBeInstanceOf(SlashCommandBuilder);
      expect(votesCommand.data.name).toBe('votes');
      expect(votesCommand.data.description).toBe('Display current course voting results');
    });

    it('should have execute function', () => {
      expect(typeof votesCommand.execute).toBe('function');
    });
  });

  describe('command execution', () => {
    it('should successfully display voting results', async () => {
      // Mock successful API response
      const mockVotingData = {
        items: [
          {
            easy_course: 'ABC',
            easy_name: 'Test Course Easy',
            easy_votes: 5,
            easy_votes_top: 'Y',
            easy_vote_order: 1,
            hard_course: 'DEF',
            hard_name: 'Test Course Hard',
            hard_votes: 3,
            hard_votes_top: null,
            hard_vote_order: 1
          }
        ],
        hasMore: false,
        count: 1
      };

      const mockEmbedData = {
        title: '🏆 Course Voting Results',
        color: 0x00AE86,
        fields: [
          {
            name: 'Easy Courses',
            value: '🏆 ABC (5) - Test Course Easy',
            inline: true
          },
          {
            name: 'Hard Courses',
            value: 'DEF (3) - Test Course Hard',
            inline: true
          }
        ],
        footer: {
          text: 'Vote counts updated in real-time'
        },
        timestamp: new Date().toISOString()
      };

      mockVotesService.getVotingResults.mockResolvedValue(mockVotingData);
      mockVotesService.createVotesEmbed.mockReturnValue(mockEmbedData);

      await votesCommand.execute(mockInteraction);

      // Verify interaction flow
      expect(mockInteraction.deferReply).toHaveBeenCalledOnce();
      expect(mockInteraction.editReply).toHaveBeenCalledTimes(2); // Loading + final result

      // Verify API calls
      expect(mockVotesService.getVotingResults).toHaveBeenCalledOnce();
      expect(mockVotesService.createVotesEmbed).toHaveBeenCalledWith(mockVotingData);

      // Verify final embed was sent
      const finalCall = mockInteraction.editReply.mock.calls[1][0];
      expect(finalCall.embeds).toHaveLength(1);
      expect(finalCall.embeds[0]).toBeInstanceOf(EmbedBuilder);
    });

    it('should handle API errors gracefully', async () => {
      const mockError = new Error('API Error');
      const mockProcessedError = new Error('Service temporarily unavailable');

      mockVotesService.getVotingResults.mockRejectedValue(mockError);
      mockVotesService.handleApiError.mockReturnValue(mockProcessedError);

      await votesCommand.execute(mockInteraction);

      // Verify error handling
      expect(mockVotesService.handleApiError).toHaveBeenCalledWith(mockError, 'votes_command_fetch');

      // Verify error embed was sent
      const errorCall = mockInteraction.editReply.mock.calls[1][0];
      expect(errorCall.embeds).toHaveLength(1);
      expect(errorCall.embeds[0]).toBeInstanceOf(EmbedBuilder);
    });

    it('should handle empty voting data', async () => {
      const mockEmptyData = {
        items: [],
        hasMore: false,
        count: 0
      };

      mockVotesService.getVotingResults.mockResolvedValue(mockEmptyData);

      await votesCommand.execute(mockInteraction);

      // Verify no data embed was sent
      const noDataCall = mockInteraction.editReply.mock.calls[1][0];
      expect(noDataCall.embeds).toHaveLength(1);
      expect(noDataCall.embeds[0]).toBeInstanceOf(EmbedBuilder);
    });

    it('should handle embed creation errors', async () => {
      const mockVotingData = {
        items: [{ easy_course: 'ABC', easy_name: 'Test' }],
        hasMore: false,
        count: 1
      };

      mockVotesService.getVotingResults.mockResolvedValue(mockVotingData);
      mockVotesService.createVotesEmbed.mockImplementation(() => {
        throw new Error('Embed creation failed');
      });

      await votesCommand.execute(mockInteraction);

      // Verify error embed was sent
      const errorCall = mockInteraction.editReply.mock.calls[1][0];
      expect(errorCall.embeds).toHaveLength(1);
      expect(errorCall.embeds[0]).toBeInstanceOf(EmbedBuilder);
    });
  });
});
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { performance } from 'perf_hooks';

// Mock Discord.js before importing the command
vi.mock('discord.js', () => ({
  SlashCommandBuilder: class {
    setName(name) { this.name = name; return this; }
    setDescription(desc) { this.description = desc; return this; }
    addStringOption(fn) { 
      const option = {
        setName: (name) => { option.name = name; return option; },
        setDescription: (desc) => { option.description = desc; return option; },
        setRequired: (req) => { option.required = req; return option; },
        setAutocomplete: (auto) => { option.autocomplete = auto; return option; }
      };
      fn(option);
      this.options = [option];
      return this;
    }
  },
  EmbedBuilder: class {
    constructor() {
      this.data = {};
    }
    setTitle(title) { this.data.title = title; return this; }
    setDescription(desc) { this.data.description = desc; return this; }
    setColor(color) { this.data.color = color; return this; }
    addFields(...fields) { this.data.fields = [...(this.data.fields || []), ...fields]; return this; }
    setFooter(footer) { this.data.footer = footer; return this; }
    setTimestamp(timestamp) { this.data.timestamp = timestamp; return this; }
  }
}));

describe('Course Command Performance Tests', () => {
  let courseCommand;
  let mockInteraction;
  let mockService;

  beforeEach(async () => {
    // Mock the CourseLeaderboardService
    mockService = {
      getCourseLeaderboard: vi.fn(),
      getAvailableCourses: vi.fn(),
      formatLeaderboardData: vi.fn(),
      createLeaderboardEmbed: vi.fn(),
      createTextDisplay: vi.fn(),
      clearCourseCache: vi.fn()
    };

    // Mock the service import
    vi.doMock('../services/CourseLeaderboardService.js', () => ({
      CourseLeaderboardService: class {
        constructor() {
          return mockService;
        }
      }
    }));

    // Import the command after mocking
    const { default: command } = await import('../commands/course.js');
    courseCommand = command;

    // Create mock interaction
    mockInteraction = {
      user: {
        id: '123456789012345678',
        username: 'testuser',
        globalName: 'Test User'
      },
      options: {
        getString: vi.fn().mockReturnValue('ALE')
      },
      reply: vi.fn().mockResolvedValue(),
      editReply: vi.fn().mockResolvedValue(),
      followUp: vi.fn().mockResolvedValue(),
      deferReply: vi.fn().mockResolvedValue(),
      responded: false,
      deferred: false,
      isRepliable: vi.fn().mockReturnValue(true)
    };
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.resetModules();
  });

  describe('Command Execution Performance', () => {
    it('should execute command within 3 seconds requirement', async () => {
      // Setup successful response mocks
      const mockApiResponse = {
        items: Array.from({ length: 20 }, (_, i) => ({
          pos: i + 1,
          player_name: `Player${i + 1}`,
          score: -15 + i,
          discord_id: `${100000 + i}`,
          isApproved: true
        })),
        count: 20
      };

      const mockFormattedData = {
        course: { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
        entries: mockApiResponse.items.map((item, i) => ({
          position: i + 1,
          playerName: item.player_name,
          score: item.score,
          isCurrentUser: false,
          isApproved: item.isApproved
        })),
        totalEntries: 20,
        hasUserScores: false,
        userEntries: [],
        lastUpdated: new Date()
      };

      const mockEmbed = {
        title: '🏆 Alfheim Easy Leaderboard',
        color: 0x00AE86,
        fields: [
          {
            name: '📊 Top Scores',
            value: mockApiResponse.items.slice(0, 10).map((item, i) => 
              `${i + 1}. ${item.player_name} - (${item.score})`
            ).join('\n'),
            inline: false
          }
        ]
      };

      mockService.getCourseLeaderboard.mockResolvedValue(mockApiResponse);
      mockService.formatLeaderboardData.mockReturnValue(mockFormattedData);
      mockService.createLeaderboardEmbed.mockReturnValue(mockEmbed);

      const startTime = performance.now();
      
      await courseCommand.execute(mockInteraction);
      
      const endTime = performance.now();
      const executionTime = endTime - startTime;

      expect(executionTime).toBeLessThan(3000); // 3 seconds requirement
      expect(mockInteraction.reply).toHaveBeenCalled();
      
      console.log(`Command execution time: ${executionTime.toFixed(2)}ms`);
    });

    it('should handle autocomplete within performance limits', async () => {
      const mockCourses = Array.from({ length: 100 }, (_, i) => ({
        code: `C${i.toString().padStart(2, '0')}E`,
        name: `Course ${i + 1} Easy`,
        difficulty: 'Easy'
      }));

      mockService.getAvailableCourses.mockResolvedValue(mockCourses);

      const mockAutocompleteInteraction = {
        user: {
          id: '123456789012345678',
          username: 'testuser'
        },
        options: {
          getFocused: vi.fn().mockReturnValue('al')
        },
        respond: vi.fn().mockResolvedValue()
      };

      const startTime = performance.now();
      
      await courseCommand.autocomplete(mockAutocompleteInteraction);
      
      const endTime = performance.now();
      const autocompleteTime = endTime - startTime;

      expect(autocompleteTime).toBeLessThan(1000); // Autocomplete should be fast
      expect(mockAutocompleteInteraction.respond).toHaveBeenCalled();
      
      console.log(`Autocomplete execution time: ${autocompleteTime.toFixed(2)}ms`);
    });

    it('should handle error scenarios within time limits', async () => {
      // Mock service to throw error
      mockService.getCourseLeaderboard.mockRejectedValue(new Error('API Error'));

      const startTime = performance.now();
      
      await courseCommand.execute(mockInteraction);
      
      const endTime = performance.now();
      const errorHandlingTime = endTime - startTime;

      expect(errorHandlingTime).toBeLessThan(2000); // Error handling should be fast
      expect(mockInteraction.reply).toHaveBeenCalled();
      
      console.log(`Error handling time: ${errorHandlingTime.toFixed(2)}ms`);
    });
  });

  describe('Concurrent Command Executions', () => {
    it('should handle multiple concurrent command executions', async () => {
      // Setup mock responses
      const mockApiResponse = {
        items: [
          { pos: 1, player_name: 'Player1', score: -20, discord_id: '123', isApproved: true }
        ],
        count: 1
      };

      const mockFormattedData = {
        course: { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
        entries: [{ position: 1, playerName: 'Player1', score: -20, isCurrentUser: false, isApproved: true }],
        totalEntries: 1,
        hasUserScores: false,
        userEntries: [],
        lastUpdated: new Date()
      };

      const mockEmbed = {
        title: '🏆 Alfheim Easy Leaderboard',
        color: 0x00AE86,
        fields: [{ name: '📊 Top Scores', value: '1. Player1 - (-20)', inline: false }]
      };

      mockService.getCourseLeaderboard.mockResolvedValue(mockApiResponse);
      mockService.formatLeaderboardData.mockReturnValue(mockFormattedData);
      mockService.createLeaderboardEmbed.mockReturnValue(mockEmbed);

      // Create multiple mock interactions
      const interactions = Array.from({ length: 10 }, (_, i) => ({
        user: {
          id: `${123456789012345678 + i}`,
          username: `testuser${i}`,
          globalName: `Test User ${i}`
        },
        options: {
          getString: vi.fn().mockReturnValue('ALE')
        },
        reply: vi.fn().mockResolvedValue(),
        editReply: vi.fn().mockResolvedValue(),
        followUp: vi.fn().mockResolvedValue(),
        deferReply: vi.fn().mockResolvedValue(),
        responded: false,
        deferred: false,
        isRepliable: vi.fn().mockReturnValue(true)
      }));

      const startTime = performance.now();
      
      // Execute commands concurrently
      const promises = interactions.map(interaction => 
        courseCommand.execute(interaction)
      );
      
      await Promise.all(promises);
      
      const endTime = performance.now();
      const totalTime = endTime - startTime;

      expect(totalTime).toBeLessThan(5000); // All 10 commands within 5 seconds
      
      // Verify all interactions were handled
      interactions.forEach(interaction => {
        expect(interaction.reply).toHaveBeenCalled();
      });
      
      console.log(`10 concurrent commands completed in: ${totalTime.toFixed(2)}ms`);
      console.log(`Average per command: ${(totalTime / 10).toFixed(2)}ms`);
    });

    it('should handle mixed autocomplete and execute operations', async () => {
      // Setup mocks
      const mockCourses = [
        { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
        { code: 'BBE', name: 'Bogeys Bonnie Easy', difficulty: 'Easy' }
      ];

      const mockApiResponse = {
        items: [{ pos: 1, player_name: 'Player1', score: -20, discord_id: '123', isApproved: true }],
        count: 1
      };

      mockService.getAvailableCourses.mockResolvedValue(mockCourses);
      mockService.getCourseLeaderboard.mockResolvedValue(mockApiResponse);
      mockService.formatLeaderboardData.mockReturnValue({
        course: { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
        entries: [{ position: 1, playerName: 'Player1', score: -20, isCurrentUser: false, isApproved: true }],
        totalEntries: 1,
        hasUserScores: false,
        userEntries: [],
        lastUpdated: new Date()
      });
      mockService.createLeaderboardEmbed.mockReturnValue({
        title: '🏆 Alfheim Easy Leaderboard',
        fields: [{ name: '📊 Top Scores', value: '1. Player1 - (-20)' }]
      });

      // Create autocomplete interactions
      const autocompleteInteractions = Array.from({ length: 5 }, (_, i) => ({
        user: {
          id: `${123456789012345678 + i}`,
          username: `testuser${i}`
        },
        options: {
          getFocused: vi.fn().mockReturnValue('al')
        },
        respond: vi.fn().mockResolvedValue()
      }));

      // Create execute interactions
      const executeInteractions = Array.from({ length: 5 }, (_, i) => ({
        user: {
          id: `${123456789012345678 + i}`,
          username: `testuser${i}`
        },
        options: {
          getString: vi.fn().mockReturnValue('ALE')
        },
        reply: vi.fn().mockResolvedValue(),
        editReply: vi.fn().mockResolvedValue(),
        followUp: vi.fn().mockResolvedValue(),
        deferReply: vi.fn().mockResolvedValue(),
        responded: false,
        deferred: false,
        isRepliable: vi.fn().mockReturnValue(true)
      }));

      const startTime = performance.now();
      
      // Mix autocomplete and execute operations
      const promises = [
        ...autocompleteInteractions.map(interaction => 
          courseCommand.autocomplete(interaction)
        ),
        ...executeInteractions.map(interaction => 
          courseCommand.execute(interaction)
        )
      ];
      
      await Promise.all(promises);
      
      const endTime = performance.now();
      const totalTime = endTime - startTime;

      expect(totalTime).toBeLessThan(4000); // Mixed operations within 4 seconds
      
      console.log(`5 autocomplete + 5 execute operations: ${totalTime.toFixed(2)}ms`);
    });
  });

  describe('Memory Usage During Command Execution', () => {
    it('should not leak memory during repeated command executions', async () => {
      // Setup mocks
      const mockApiResponse = {
        items: Array.from({ length: 50 }, (_, i) => ({
          pos: i + 1,
          player_name: `Player${i + 1}`,
          score: -20 + i,
          discord_id: `${100000 + i}`,
          isApproved: true
        })),
        count: 50
      };

      mockService.getCourseLeaderboard.mockResolvedValue(mockApiResponse);
      mockService.formatLeaderboardData.mockReturnValue({
        course: { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
        entries: mockApiResponse.items.map((item, i) => ({
          position: i + 1,
          playerName: item.player_name,
          score: item.score,
          isCurrentUser: false,
          isApproved: true
        })),
        totalEntries: 50,
        hasUserScores: false,
        userEntries: [],
        lastUpdated: new Date()
      });
      mockService.createLeaderboardEmbed.mockReturnValue({
        title: '🏆 Alfheim Easy Leaderboard',
        fields: [{ name: '📊 Top Scores', value: 'Mock leaderboard data' }]
      });

      const initialMemory = process.memoryUsage();
      
      // Execute command many times
      for (let i = 0; i < 50; i++) {
        const interaction = {
          user: {
            id: `${123456789012345678 + i}`,
            username: `testuser${i}`
          },
          options: {
            getString: vi.fn().mockReturnValue('ALE')
          },
          reply: vi.fn().mockResolvedValue(),
          editReply: vi.fn().mockResolvedValue(),
          followUp: vi.fn().mockResolvedValue(),
          deferReply: vi.fn().mockResolvedValue(),
          responded: false,
          deferred: false,
          isRepliable: vi.fn().mockReturnValue(true)
        };
        
        await courseCommand.execute(interaction);
        
        // Force garbage collection every 10 iterations if available
        if (i % 10 === 0 && global.gc) {
          global.gc();
        }
      }
      
      if (global.gc) {
        global.gc();
      }
      
      const finalMemory = process.memoryUsage();
      const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;
      
      // Memory increase should be reasonable
      expect(memoryIncrease).toBeLessThan(20 * 1024 * 1024); // Less than 20MB
      
      console.log(`Memory increase after 50 command executions: ${(memoryIncrease / 1024 / 1024).toFixed(2)}MB`);
    });

    it('should clean up resources after command errors', async () => {
      // Mock service to throw errors
      mockService.getCourseLeaderboard.mockRejectedValue(new Error('API Error'));

      const initialMemory = process.memoryUsage();
      
      // Execute commands that will fail
      for (let i = 0; i < 25; i++) {
        const interaction = {
          user: {
            id: `${123456789012345678 + i}`,
            username: `testuser${i}`
          },
          options: {
            getString: vi.fn().mockReturnValue('ALE')
          },
          reply: vi.fn().mockResolvedValue(),
          editReply: vi.fn().mockResolvedValue(),
          followUp: vi.fn().mockResolvedValue(),
          deferReply: vi.fn().mockResolvedValue(),
          responded: false,
          deferred: false,
          isRepliable: vi.fn().mockReturnValue(true)
        };
        
        await courseCommand.execute(interaction);
      }
      
      if (global.gc) {
        global.gc();
      }
      
      const finalMemory = process.memoryUsage();
      const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;
      
      // Memory increase should be minimal even with errors
      expect(memoryIncrease).toBeLessThan(5 * 1024 * 1024); // Less than 5MB
      
      console.log(`Memory increase after 25 failed commands: ${(memoryIncrease / 1024 / 1024).toFixed(2)}MB`);
    });
  });

  describe('Performance Under Load', () => {
    it('should maintain performance with varying response times', async () => {
      // Mock service with variable delays
      mockService.getCourseLeaderboard.mockImplementation(() => {
        const delay = Math.random() * 200; // 0-200ms random delay
        return new Promise(resolve => {
          setTimeout(() => {
            resolve({
              items: [{ pos: 1, player_name: 'Player1', score: -20, discord_id: '123', isApproved: true }],
              count: 1
            });
          }, delay);
        });
      });

      mockService.formatLeaderboardData.mockReturnValue({
        course: { code: 'ALE', name: 'Alfheim Easy', difficulty: 'Easy' },
        entries: [{ position: 1, playerName: 'Player1', score: -20, isCurrentUser: false, isApproved: true }],
        totalEntries: 1,
        hasUserScores: false,
        userEntries: [],
        lastUpdated: new Date()
      });

      mockService.createLeaderboardEmbed.mockReturnValue({
        title: '🏆 Alfheim Easy Leaderboard',
        fields: [{ name: '📊 Top Scores', value: '1. Player1 - (-20)' }]
      });

      const startTime = performance.now();
      const executionTimes = [];
      
      // Execute 20 commands with varying delays
      for (let i = 0; i < 20; i++) {
        const interaction = {
          user: {
            id: `${123456789012345678 + i}`,
            username: `testuser${i}`
          },
          options: {
            getString: vi.fn().mockReturnValue('ALE')
          },
          reply: vi.fn().mockResolvedValue(),
          editReply: vi.fn().mockResolvedValue(),
          followUp: vi.fn().mockResolvedValue(),
          deferReply: vi.fn().mockResolvedValue(),
          responded: false,
          deferred: false,
          isRepliable: vi.fn().mockReturnValue(true)
        };
        
        const cmdStartTime = performance.now();
        await courseCommand.execute(interaction);
        const cmdEndTime = performance.now();
        
        executionTimes.push(cmdEndTime - cmdStartTime);
      }
      
      const endTime = performance.now();
      const totalTime = endTime - startTime;
      const avgTime = executionTimes.reduce((a, b) => a + b, 0) / executionTimes.length;
      const maxTime = Math.max(...executionTimes);
      const minTime = Math.min(...executionTimes);

      expect(totalTime).toBeLessThan(10000); // Total within 10 seconds
      expect(maxTime).toBeLessThan(3000); // No single command over 3 seconds
      
      console.log(`20 commands with variable delays:`);
      console.log(`  Total time: ${totalTime.toFixed(2)}ms`);
      console.log(`  Average time: ${avgTime.toFixed(2)}ms`);
      console.log(`  Min time: ${minTime.toFixed(2)}ms`);
      console.log(`  Max time: ${maxTime.toFixed(2)}ms`);
    });
  });
});
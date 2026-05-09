import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock Logger before importing SpinButtonHandler
vi.mock('../utils/Logger.js', () => ({
  logger: {
    child: () => ({
      info: vi.fn(),
      debug: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    })
  }
}));

// Mock ErrorHandler
vi.mock('../utils/ErrorHandler.js', () => ({
  ErrorHandler: vi.fn().mockImplementation(() => ({
    handleInteractionError: vi.fn().mockResolvedValue(undefined)
  }))
}));

// Mock SpinService
vi.mock('../services/SpinService.js', () => ({
  SpinService: vi.fn().mockImplementation(() => ({
    loadCourses: vi.fn(),
    filterCourses: vi.fn(),
    selectRandom: vi.fn(),
    buildEmbed: vi.fn()
  }))
}));

// Mock CourseLeaderboardService
vi.mock('../services/CourseLeaderboardService.js', () => ({
  CourseLeaderboardService: vi.fn().mockImplementation(() => ({
    getCourseLeaderboard: vi.fn(),
    formatLeaderboardData: vi.fn()
  }))
}));

import { SpinButtonHandler } from '../services/SpinButtonHandler.js';

describe('SpinButtonHandler - formatLeaderboardField', () => {
  let handler;

  beforeEach(() => {
    handler = new SpinButtonHandler();
  });

  it('returns null when leaderboardData is null', () => {
    const result = handler.formatLeaderboardField(null);
    expect(result).toBeNull();
  });

  it('returns null when leaderboardData has empty entries array', () => {
    const result = handler.formatLeaderboardField({ entries: [] });
    expect(result).toBeNull();
  });

  it('returns null when leaderboardData has undefined entries', () => {
    const result = handler.formatLeaderboardField({ entries: undefined });
    expect(result).toBeNull();
  });

  it('formats single distinct score with player name correctly (🥇 only)', () => {
    const data = { entries: [{ position: 1, playerName: "PlayerA", score: -12 }] };
    const result = handler.formatLeaderboardField(data);
    expect(result).toEqual({
      name: '🏆 Best Scores',
      value: '🥇 `-12` **PlayerA**',
      inline: false
    });
  });

  it('formats 2 distinct scores (🥇 with name, 🥈 score only)', () => {
    const data = { entries: [
      { position: 1, playerName: "PlayerA", score: -12 },
      { position: 2, playerName: "PlayerB", score: -11 }
    ]};
    const result = handler.formatLeaderboardField(data);
    expect(result).toEqual({
      name: '🏆 Best Scores',
      value: '🥇 `-12` **PlayerA**\n🥈 `-11` **PlayerB**',
      inline: false
    });
  });

  it('formats 3 distinct scores (🥇 with name, 🥈 with name, 🥉 with name)', () => {
    const data = { entries: [
      { position: 1, playerName: "PlayerA", score: -12 },
      { position: 2, playerName: "PlayerB", score: -11 },
      { position: 3, playerName: "PlayerC", score: -10 }
    ]};
    const result = handler.formatLeaderboardField(data);
    expect(result).toEqual({
      name: '🏆 Best Scores',
      value: '🥇 `-12` **PlayerA**\n🥈 `-11` **PlayerB**\n🥉 `-10` **PlayerC**',
      inline: false
    });
  });

  it('handles tie at 1st place — multiple player names comma-delimited', () => {
    const data = { entries: [
      { position: 1, playerName: "PlayerA", score: -12 },
      { position: 2, playerName: "PlayerB", score: -12 },
      { position: 3, playerName: "PlayerC", score: -11 }
    ]};
    const result = handler.formatLeaderboardField(data);
    expect(result).toEqual({
      name: '🏆 Best Scores',
      value: '🥇 `-12` **PlayerA, PlayerB**\n🥈 `-11` **PlayerC**',
      inline: false
    });
  });

  it('caps 1st place names at 5 with "+N more" indicator', () => {
    const data = { entries: [
      { position: 1, playerName: "Player1", score: -12 },
      { position: 2, playerName: "Player2", score: -12 },
      { position: 3, playerName: "Player3", score: -12 },
      { position: 4, playerName: "Player4", score: -12 },
      { position: 5, playerName: "Player5", score: -12 },
      { position: 6, playerName: "Player6", score: -12 },
      { position: 7, playerName: "Player7", score: -12 },
      { position: 8, playerName: "Player8", score: -12 }
    ]};
    const result = handler.formatLeaderboardField(data);
    expect(result).toEqual({
      name: '🏆 Best Scores',
      value: '🥇 `-12` **Player1, Player2, Player3, Player4, Player5 +3 more**',
      inline: false
    });
  });

  it('score formatting — negative scores without +, zero/positive with +', () => {
    const data = { entries: [
      { position: 1, playerName: "PlayerA", score: -5 },
      { position: 2, playerName: "PlayerB", score: 0 },
      { position: 3, playerName: "PlayerC", score: 2 }
    ]};
    const result = handler.formatLeaderboardField(data);
    expect(result.value).toBe('🥇 `-5` **PlayerA**\n🥈 `+0` **PlayerB**\n🥉 `+2` **PlayerC**');
  });

  it('field value does not exceed 1024 characters with many tied players', () => {
    // Create 100 players all tied at the same score with long names
    const entries = [];
    for (let i = 1; i <= 100; i++) {
      const padded = String(i).padStart(3, '0');
      entries.push({
        position: i,
        playerName: `VeryLongPlayerNameThatTakesUpSpace_${padded}`,
        score: -10
      });
    }
    const data = { entries };
    const result = handler.formatLeaderboardField(data);
    expect(result.value.length).toBeLessThanOrEqual(1024);
  });
});

describe('SpinButtonHandler - fetchTop3Leaderboard', () => {
  let handler;

  beforeEach(() => {
    handler = new SpinButtonHandler();
  });

  it('returns null when CourseLeaderboardService throws an error', async () => {
    handler.courseLeaderboardService.getCourseLeaderboard.mockRejectedValue(new Error('API unavailable'));

    const result = await handler.fetchTop3Leaderboard('ALE', '123456');

    expect(result).toBeNull();
  });

  it('returns null when API returns empty items array', async () => {
    handler.courseLeaderboardService.getCourseLeaderboard.mockResolvedValue({ items: [], hasMore: false, count: 0 });
    handler.courseLeaderboardService.formatLeaderboardData.mockReturnValue({ entries: [] });

    const result = await handler.fetchTop3Leaderboard('ALE', '123456');

    expect(result).toBeNull();
  });

  it('returns null when timeout is exceeded (mock slow response)', async () => {
    vi.useFakeTimers();

    try {
      // Mock a promise that never resolves (simulating a slow API)
      handler.courseLeaderboardService.getCourseLeaderboard.mockImplementation(() => new Promise(() => {}));

      const resultPromise = handler.fetchTop3Leaderboard('ALE', '123456');

      // Advance timers by 5000ms to trigger the timeout
      await vi.advanceTimersByTimeAsync(5000);

      const result = await resultPromise;

      expect(result).toBeNull();
    } finally {
      vi.useRealTimers();
    }
  });

  it('logs warning when leaderboard fetch fails', async () => {
    handler.courseLeaderboardService.getCourseLeaderboard.mockRejectedValue(new Error('API unavailable'));

    await handler.fetchTop3Leaderboard('ALE', '123456');

    expect(handler.logger.warn).toHaveBeenCalled();
  });

  it('returns formatted data limited to top 3 distinct scores when API succeeds', async () => {
    // Mock API response with 6 entries spanning 4 distinct scores
    const mockApiResponse = {
      items: [
        { pos: 1, player_name: 'PlayerA', score: -12, discord_id: '111', isapproved: 'true' },
        { pos: 2, player_name: 'PlayerB', score: -11, discord_id: '222', isapproved: 'true' },
        { pos: 3, player_name: 'PlayerC', score: -11, discord_id: '333', isapproved: 'true' },
        { pos: 4, player_name: 'PlayerD', score: -10, discord_id: '444', isapproved: 'true' },
        { pos: 5, player_name: 'PlayerE', score: -9, discord_id: '555', isapproved: 'true' },
        { pos: 6, player_name: 'PlayerF', score: -9, discord_id: '666', isapproved: 'true' }
      ],
      hasMore: false,
      count: 6
    };

    // Mock formatLeaderboardData to return formatted entries for all 4 distinct scores
    const mockFormattedData = {
      course: { code: 'ALE', name: 'Alfheim', difficulty: '(Easy)' },
      entries: [
        { position: 1, playerName: 'PlayerA', score: -12, discordId: '111', isApproved: true, isCurrentUser: false },
        { position: 2, playerName: 'PlayerB', score: -11, discordId: '222', isApproved: true, isCurrentUser: false },
        { position: 3, playerName: 'PlayerC', score: -11, discordId: '333', isApproved: true, isCurrentUser: false },
        { position: 4, playerName: 'PlayerD', score: -10, discordId: '444', isApproved: true, isCurrentUser: false },
        { position: 5, playerName: 'PlayerE', score: -9, discordId: '555', isApproved: true, isCurrentUser: false },
        { position: 6, playerName: 'PlayerF', score: -9, discordId: '666', isApproved: true, isCurrentUser: false }
      ],
      totalEntries: 6,
      userEntries: [],
      hasUserScores: false,
      lastUpdated: new Date()
    };

    handler.courseLeaderboardService.getCourseLeaderboard.mockResolvedValue(mockApiResponse);
    handler.courseLeaderboardService.formatLeaderboardData.mockReturnValue(mockFormattedData);

    const result = await handler.fetchTop3Leaderboard('ALE', '123456');

    // Should only contain entries for the top 3 distinct scores: -12, -11, -10
    expect(result).not.toBeNull();
    expect(result.entries).toHaveLength(4); // PlayerA(-12), PlayerB(-11), PlayerC(-11), PlayerD(-10)

    const returnedScores = [...new Set(result.entries.map(e => e.score))];
    expect(returnedScores).toEqual([-12, -11, -10]);

    // Entries for the 4th distinct score (-9) should be excluded
    const hasScore9 = result.entries.some(e => e.score === -9);
    expect(hasScore9).toBe(false);
  });
});

describe('SpinButtonHandler - handleSpin integration', () => {
  let handler;
  let interaction;

  beforeEach(() => {
    handler = new SpinButtonHandler();

    interaction = {
      customId: 'spin_easy',
      user: { id: '123456' },
      update: vi.fn().mockResolvedValue(undefined),
      followUp: vi.fn().mockResolvedValue(undefined)
    };

    // Set up SpinService mocks
    const mockCourses = [
      { name: 'Alfheim', code: 'ALE', difficulty: 'Easy', image: 'https://example.com/alfheim.png' }
    ];
    handler.spinService.loadCourses.mockResolvedValue(mockCourses);
    handler.spinService.filterCourses.mockReturnValue(mockCourses);
    handler.spinService.selectRandom.mockReturnValue(mockCourses[0]);

    // buildEmbed returns a mock embed with setFooter and addFields methods
    const mockEmbed = {
      setFooter: vi.fn().mockReturnThis(),
      addFields: vi.fn().mockReturnThis()
    };
    handler.spinService.buildEmbed.mockReturnValue(mockEmbed);
  });

  it('sends embed without leaderboard field when API fails', async () => {
    // Mock leaderboard service to reject with an error
    handler.courseLeaderboardService.getCourseLeaderboard.mockRejectedValue(new Error('API unavailable'));

    await handler.handleSpin(interaction);

    // Get the mock embed that was returned by buildEmbed
    const mockEmbed = handler.spinService.buildEmbed.mock.results[0].value;

    // addFields should NOT have been called (leaderboard fetch failed, no field added)
    expect(mockEmbed.addFields).not.toHaveBeenCalled();

    // followUp should still have been called (spin result was still sent)
    expect(interaction.followUp).toHaveBeenCalled();
  });

  it('sends embed without leaderboard field when no scores exist for course', async () => {
    // Mock leaderboard service to return empty results (no scores for this course)
    handler.courseLeaderboardService.getCourseLeaderboard.mockResolvedValue({ items: [], hasMore: false, count: 0 });
    handler.courseLeaderboardService.formatLeaderboardData.mockReturnValue({ entries: [] });

    await handler.handleSpin(interaction);

    // Get the mock embed that was returned by buildEmbed
    const mockEmbed = handler.spinService.buildEmbed.mock.results[0].value;

    // addFields should NOT have been called (no scores = no leaderboard field)
    expect(mockEmbed.addFields).not.toHaveBeenCalled();

    // followUp should still have been called (spin result still sent)
    expect(interaction.followUp).toHaveBeenCalled();
  });

  it('completes within reasonable time even when leaderboard API is slow (timeout triggers)', async () => {
    vi.useFakeTimers();

    try {
      // Mock getCourseLeaderboard to return a promise that never resolves (simulating a slow API)
      handler.courseLeaderboardService.getCourseLeaderboard.mockImplementation(() => new Promise(() => {}));

      // Start the handleSpin call
      const spinPromise = handler.handleSpin(interaction);

      // Advance timers by 5000ms to trigger the leaderboard timeout
      await vi.advanceTimersByTimeAsync(5000);

      // Await the result
      await spinPromise;

      // The spin result should still have been sent (followUp was called)
      expect(interaction.followUp).toHaveBeenCalled();

      // The leaderboard field should NOT have been added (timed out, no field)
      const mockEmbed = handler.spinService.buildEmbed.mock.results[0].value;
      expect(mockEmbed.addFields).not.toHaveBeenCalled();
    } finally {
      vi.useRealTimers();
    }
  });

  it('includes "🏆 Best Scores" field in embed when leaderboard data is available', async () => {
    // Set up CourseLeaderboardService mocks to return valid leaderboard data
    const mockApiResponse = {
      items: [
        { pos: 1, player_name: 'PlayerA', score: -12, discord_id: '111', isapproved: 'true' },
        { pos: 2, player_name: 'PlayerB', score: -11, discord_id: '222', isapproved: 'true' },
        { pos: 3, player_name: 'PlayerC', score: -10, discord_id: '333', isapproved: 'true' }
      ],
      hasMore: false,
      count: 3
    };

    const mockFormattedData = {
      course: { code: 'ALE', name: 'Alfheim', difficulty: '(Easy)' },
      entries: [
        { position: 1, playerName: 'PlayerA', score: -12, discordId: '111', isApproved: true, isCurrentUser: false },
        { position: 2, playerName: 'PlayerB', score: -11, discordId: '222', isApproved: true, isCurrentUser: false },
        { position: 3, playerName: 'PlayerC', score: -10, discordId: '333', isApproved: true, isCurrentUser: false }
      ],
      totalEntries: 3,
      userEntries: [],
      hasUserScores: false,
      lastUpdated: new Date()
    };

    handler.courseLeaderboardService.getCourseLeaderboard.mockResolvedValue(mockApiResponse);
    handler.courseLeaderboardService.formatLeaderboardData.mockReturnValue(mockFormattedData);

    await handler.handleSpin(interaction);

    // Get the mock embed that was returned by buildEmbed
    const mockEmbed = handler.spinService.buildEmbed.mock.results[0].value;

    // Assert addFields was called with an object containing name: '🏆 Best Scores'
    expect(mockEmbed.addFields).toHaveBeenCalledWith(
      expect.objectContaining({ name: '🏆 Best Scores' })
    );
  });
});

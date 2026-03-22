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

import { SpinButtonHandler, DIFFICULTY_MAP, DIFFICULTY_LABEL } from '../services/SpinButtonHandler.js';

function createMockInteraction(customId) {
  return {
    customId,
    update: vi.fn().mockResolvedValue(undefined),
    followUp: vi.fn().mockResolvedValue(undefined),
    user: { id: '123456789', username: 'TestPlayer' },
    guildId: '987654321'
  };
}

function createMockEmbed() {
  return { data: {}, setFooter: vi.fn().mockReturnThis() };
}

const SAMPLE_COURSES = [
  { code: 'ALE', name: 'Alfheim', difficulty: 'Easy' },
  { code: 'SWL', name: 'Sweetopia', difficulty: 'Easy' },
  { code: 'LAB', name: 'Labyrinth', difficulty: 'Hard' },
  { code: 'MYS', name: 'Myst', difficulty: 'Hard' }
];

describe('SpinButtonHandler', () => {
  let handler;
  let interaction;
  let mockEmbed;

  beforeEach(() => {
    handler = new SpinButtonHandler();
    mockEmbed = createMockEmbed();

    handler.spinService.loadCourses.mockResolvedValue(SAMPLE_COURSES);
    handler.spinService.filterCourses.mockReturnValue(SAMPLE_COURSES);
    handler.spinService.selectRandom.mockReturnValue(SAMPLE_COURSES[0]);
    handler.spinService.buildEmbed.mockReturnValue(mockEmbed);
  });

  // ─── Difficulty Mapping ───────────────────────────────────────────

  describe('difficulty mapping', () => {
    it('should map spin_any to null', () => {
      expect(DIFFICULTY_MAP.spin_any).toBeNull();
    });

    it('should map spin_easy to "Easy"', () => {
      expect(DIFFICULTY_MAP.spin_easy).toBe('Easy');
    });

    it('should map spin_hard to "Hard"', () => {
      expect(DIFFICULTY_MAP.spin_hard).toBe('Hard');
    });

    it('should pass correct difficulty to filterCourses for each customId', async () => {
      for (const [customId, expected] of Object.entries(DIFFICULTY_MAP)) {
        handler.spinService.filterCourses.mockReturnValue(SAMPLE_COURSES);
        interaction = createMockInteraction(customId);
        await handler.handleSpin(interaction);
        expect(handler.spinService.filterCourses).toHaveBeenCalledWith(SAMPLE_COURSES, expected);
      }
    });
  });

  // ─── Footer Label ─────────────────────────────────────────────────

  describe('footer label', () => {
    it('should set footer to "Random Any" for spin_any', async () => {
      interaction = createMockInteraction('spin_any');
      await handler.handleSpin(interaction);
      expect(mockEmbed.setFooter).toHaveBeenCalledWith({ text: 'Random Any' });
    });

    it('should set footer to "Random Easy" for spin_easy', async () => {
      interaction = createMockInteraction('spin_easy');
      await handler.handleSpin(interaction);
      expect(mockEmbed.setFooter).toHaveBeenCalledWith({ text: 'Random Easy' });
    });

    it('should set footer to "Random Hard" for spin_hard', async () => {
      interaction = createMockInteraction('spin_hard');
      await handler.handleSpin(interaction);
      expect(mockEmbed.setFooter).toHaveBeenCalledWith({ text: 'Random Hard' });
    });
  });

  // ─── Happy Path Flow ──────────────────────────────────────────────

  describe('happy path', () => {
    beforeEach(() => {
      interaction = createMockInteraction('spin_easy');
    });

    it('should dismiss the ephemeral prompt via interaction.update()', async () => {
      await handler.handleSpin(interaction);

      expect(interaction.update).toHaveBeenCalledTimes(1);
      const updateArg = interaction.update.mock.calls[0][0];
      expect(updateArg.embeds).toEqual([]);
      expect(updateArg.components).toEqual([]);
    });

    it('should send a public follow-up with the course embed', async () => {
      await handler.handleSpin(interaction);

      expect(interaction.followUp).toHaveBeenCalledTimes(1);
      const followUpArg = interaction.followUp.mock.calls[0][0];
      expect(followUpArg.embeds).toEqual([mockEmbed]);
      // Should NOT be ephemeral
      expect(followUpArg.ephemeral).toBeUndefined();
    });

    it('should not include any components (no spin-again buttons)', async () => {
      await handler.handleSpin(interaction);

      const followUpArg = interaction.followUp.mock.calls[0][0];
      expect(followUpArg.components).toBeUndefined();
    });

    it('should call loadCourses, filterCourses, selectRandom, buildEmbed', async () => {
      await handler.handleSpin(interaction);

      expect(handler.spinService.loadCourses).toHaveBeenCalledTimes(1);
      expect(handler.spinService.filterCourses).toHaveBeenCalledTimes(1);
      expect(handler.spinService.selectRandom).toHaveBeenCalledTimes(1);
      expect(handler.spinService.buildEmbed).toHaveBeenCalledTimes(1);
    });
  });

  // ─── Error: loadCourses throws ────────────────────────────────────

  describe('error: loadCourses throws', () => {
    beforeEach(() => {
      handler.spinService.loadCourses.mockRejectedValue(new Error('File not found'));
      interaction = createMockInteraction('spin_any');
    });

    it('should dismiss the prompt and follow up with an ephemeral error embed', async () => {
      await handler.handleSpin(interaction);

      expect(interaction.update).toHaveBeenCalledTimes(1);
      expect(interaction.followUp).toHaveBeenCalledTimes(1);

      const followUpArg = interaction.followUp.mock.calls[0][0];
      expect(followUpArg.ephemeral).toBe(true);
      expect(followUpArg.embeds).toHaveLength(1);
      expect(followUpArg.embeds[0].data.title).toBe('❌ Course Data Unavailable');
    });
  });

  // ─── Error: filterCourses returns empty ───────────────────────────

  describe('error: filterCourses returns empty', () => {
    beforeEach(() => {
      handler.spinService.filterCourses.mockReturnValue([]);
      interaction = createMockInteraction('spin_hard');
    });

    it('should dismiss the prompt and follow up with an ephemeral warning embed', async () => {
      await handler.handleSpin(interaction);

      expect(interaction.update).toHaveBeenCalledTimes(1);
      expect(interaction.followUp).toHaveBeenCalledTimes(1);

      const followUpArg = interaction.followUp.mock.calls[0][0];
      expect(followUpArg.ephemeral).toBe(true);
      expect(followUpArg.embeds).toHaveLength(1);
      expect(followUpArg.embeds[0].data.title).toBe('🎰 No Courses Found');
    });
  });

  // ─── Error: unexpected error ──────────────────────────────────────

  describe('error: unexpected error', () => {
    it('should call ErrorHandler.handleInteractionError', async () => {
      const unexpectedError = new Error('Something broke');
      handler.spinService.filterCourses.mockImplementation(() => { throw unexpectedError; });

      interaction = createMockInteraction('spin_any');
      await handler.handleSpin(interaction);

      expect(handler.errorHandler.handleInteractionError).toHaveBeenCalledWith(
        unexpectedError,
        interaction,
        'SpinButtonHandler.handleSpin'
      );
    });
  });
});

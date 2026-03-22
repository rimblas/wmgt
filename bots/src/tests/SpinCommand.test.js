import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ButtonStyle } from 'discord.js';

// Mock logger before importing the command
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

import spinCommand from '../commands/spin.js';

/**
 * Create a mock Discord ChatInputCommandInteraction
 */
function createMockInteraction(overrides = {}) {
  return {
    reply: vi.fn().mockResolvedValue(undefined),
    user: { id: '123456789', username: 'TestPlayer' },
    guildId: '987654321',
    ...overrides
  };
}

describe('Spin Command - Updated (Button UI)', () => {
  const json = spinCommand.data.toJSON();

  describe('command registration', () => {
    it('should have the name "spin"', () => {
      expect(json.name).toBe('spin');
    });

    it('should have a non-empty description', () => {
      expect(json.description).toBeDefined();
      expect(json.description.length).toBeGreaterThan(0);
    });

    it('should have no options (difficulty option removed)', () => {
      expect(json.options).toEqual([]);
    });
  });

  describe('execute - reply with buttons', () => {
    let interaction;

    beforeEach(() => {
      interaction = createMockInteraction();
    });

    it('should reply with an ephemeral message', async () => {
      await spinCommand.execute(interaction);

      expect(interaction.reply).toHaveBeenCalledTimes(1);
      const replyArg = interaction.reply.mock.calls[0][0];
      expect(replyArg.ephemeral).toBe(true);
    });

    it('should include a prompt message', async () => {
      await spinCommand.execute(interaction);

      const replyArg = interaction.reply.mock.calls[0][0];
      expect(replyArg.content).toBe('Pick a difficulty to spin a random course!');
    });

    it('should include exactly one action row with three buttons', async () => {
      await spinCommand.execute(interaction);

      const replyArg = interaction.reply.mock.calls[0][0];
      expect(replyArg.components).toHaveLength(1);

      const row = replyArg.components[0];
      expect(row.components).toHaveLength(3);
    });

    it('should have "🎲 Any" button with customId spin_any and Secondary style', async () => {
      await spinCommand.execute(interaction);

      const buttons = interaction.reply.mock.calls[0][0].components[0].components;
      const anyBtn = buttons.find(b => b.data.custom_id === 'spin_any');
      expect(anyBtn).toBeDefined();
      expect(anyBtn.data.label).toBe('🎲 Any');
      expect(anyBtn.data.style).toBe(ButtonStyle.Secondary);
    });

    it('should have "🟢 Easy" button with customId spin_easy and Success style', async () => {
      await spinCommand.execute(interaction);

      const buttons = interaction.reply.mock.calls[0][0].components[0].components;
      const easyBtn = buttons.find(b => b.data.custom_id === 'spin_easy');
      expect(easyBtn).toBeDefined();
      expect(easyBtn.data.label).toBe('🟢 Easy');
      expect(easyBtn.data.style).toBe(ButtonStyle.Success);
    });

    it('should have "🔵 Hard" button with customId spin_hard and Primary style', async () => {
      await spinCommand.execute(interaction);

      const buttons = interaction.reply.mock.calls[0][0].components[0].components;
      const hardBtn = buttons.find(b => b.data.custom_id === 'spin_hard');
      expect(hardBtn).toBeDefined();
      expect(hardBtn.data.label).toBe('🔵 Hard');
      expect(hardBtn.data.style).toBe(ButtonStyle.Primary);
    });

    it('should have buttons in order: Any, Easy, Hard', async () => {
      await spinCommand.execute(interaction);

      const buttons = interaction.reply.mock.calls[0][0].components[0].components;
      expect(buttons[0].data.custom_id).toBe('spin_any');
      expect(buttons[1].data.custom_id).toBe('spin_easy');
      expect(buttons[2].data.custom_id).toBe('spin_hard');
    });
  });
});

import { EmbedBuilder } from 'discord.js';
import { logger } from '../utils/Logger.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';
import { SpinService } from './SpinService.js';

/** Maps button customId to SpinService difficulty filter value. */
const DIFFICULTY_MAP = {
  spin_any: null,
  spin_easy: 'Easy',
  spin_hard: 'Hard'
};

/** Maps button customId to the footer label shown on the result embed. */
const DIFFICULTY_LABEL = {
  spin_any: 'Random Any',
  spin_easy: 'Random Easy',
  spin_hard: 'Random Hard'
};

/**
 * Handles button click interactions originating from the /spin command.
 * Routes spin_any, spin_easy, and spin_hard button clicks to perform
 * random course selection via SpinService.
 */
export class SpinButtonHandler {
  constructor() {
    this.spinService = new SpinService();
    this.logger = logger.child({ service: 'SpinButtonHandler' });
    this.errorHandler = new ErrorHandler(this.logger);
  }

  /**
   * Handle a spin button click: parse difficulty, load/filter/pick a course,
   * and display the result as a permanent (non-ephemeral) embed visible to all users.
   *
   * Updates the original ephemeral prompt to remove the buttons, then sends
   * a public follow-up with the course embed.
   *
   * @param {import('discord.js').ButtonInteraction} interaction
   */
  async handleSpin(interaction) {
    try {
      const difficulty = DIFFICULTY_MAP[interaction.customId];

      // Load courses
      let courses;
      try {
        courses = await this.spinService.loadCourses();
      } catch (loadError) {
        this.logger.error('Failed to load course data', { error: loadError.message });
        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Course Data Unavailable')
          .setDescription('Unable to load course data. Please try again later.');
        await interaction.update({ content: 'Spin failed.', embeds: [], components: [] });
        await interaction.followUp({ embeds: [errorEmbed], ephemeral: true });
        return;
      }

      // Filter
      const filtered = this.spinService.filterCourses(courses, difficulty);

      if (filtered.length === 0) {
        const warnEmbed = new EmbedBuilder()
          .setColor(0xFFA500)
          .setTitle('🎰 No Courses Found')
          .setDescription('No courses match the selected difficulty.');
        await interaction.update({ content: 'No courses found.', embeds: [], components: [] });
        await interaction.followUp({ embeds: [warnEmbed], ephemeral: true });
        return;
      }

      // Pick & build embed
      const selected = this.spinService.selectRandom(filtered);
      const embed = this.spinService.buildEmbed(selected);

      // Add selected-difficulty indicator to footer
      const footerLabel = DIFFICULTY_LABEL[interaction.customId];
      if (footerLabel) {
        embed.setFooter({ text: `Result for: ${footerLabel}` });
      }

      // Dismiss the ephemeral prompt, then send a public follow-up visible to everyone
      await interaction.update({ content: 'Spun!', embeds: [], components: [] });
      await interaction.followUp({ embeds: [embed] });
    } catch (error) {
      this.logger.error('Unexpected error in handleSpin', { error: error.message });
      await this.errorHandler.handleInteractionError(error, interaction, 'SpinButtonHandler.handleSpin');
    }
  }
}

export { DIFFICULTY_MAP, DIFFICULTY_LABEL };

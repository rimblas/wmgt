import { SlashCommandBuilder } from 'discord.js';
import { SpinService } from '../services/SpinService.js';
import { logger } from '../utils/Logger.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';

const spinService = new SpinService();
const commandLogger = logger.child({ command: 'spin' });
const errorHandler = new ErrorHandler(commandLogger);

export default {
  data: new SlashCommandBuilder()
    .setName('spin')
    .setDescription('Randomly select a Walkabout Mini Golf course')
    .addStringOption(option =>
      option.setName('difficulty')
        .setDescription('Filter by difficulty')
        .setRequired(false)
        .addChoices(
          { name: 'Easy', value: 'Easy' },
          { name: 'Hard', value: 'Hard' }
        )),

  async execute(interaction) {
    try {
      await interaction.deferReply();

      commandLogger.info('Spin command executed', {
        userId: interaction.user.id,
        username: interaction.user.username,
        guildId: interaction.guildId
      });

      const difficulty = interaction.options.getString('difficulty');

      let courses;
      try {
        courses = await spinService.loadCourses();
      } catch (error) {
        commandLogger.error('Failed to load course data', {
          error: error.message,
          stack: error.stack,
          userId: interaction.user.id
        });

        const errorEmbed = errorHandler.createErrorEmbed(
          '❌ Course Data Unavailable',
          'Unable to load course data. Please try again later.',
          'If the problem persists, contact an Admin.'
        );

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      const filtered = spinService.filterCourses(courses, difficulty);

      if (filtered.length === 0) {
        commandLogger.warn('No courses match filter', {
          difficulty,
          userId: interaction.user.id
        });

        const noMatchEmbed = errorHandler.createWarningEmbed(
          '🎰 No Courses Found',
          `No courses match the selected difficulty: **${difficulty}**.`,
          'Try spinning without a difficulty filter.'
        );

        return await interaction.editReply({ embeds: [noMatchEmbed] });
      }

      const selected = spinService.selectRandom(filtered);
      const embed = spinService.buildEmbed(selected);

      await interaction.editReply({ embeds: [embed] });

      commandLogger.info('Spin command completed successfully', {
        userId: interaction.user.id,
        selectedCourse: selected.code,
        difficulty: difficulty || 'all'
      });

    } catch (error) {
      commandLogger.error('Unexpected error in spin command', {
        error: error.message,
        stack: error.stack,
        userId: interaction.user.id,
        guildId: interaction.guildId
      });

      await errorHandler.handleInteractionError(error, interaction, 'spin_command');
    }
  }
};

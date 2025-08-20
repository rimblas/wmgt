import {
  SlashCommandBuilder,
  EmbedBuilder
} from 'discord.js';
import { VotesService } from '../services/VotesService.js';
import { logger } from '../utils/Logger.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';

const votesService = new VotesService();
const commandLogger = logger.child({ command: 'votes' });
const errorHandler = new ErrorHandler(commandLogger);

export default {
  data: new SlashCommandBuilder()
    .setName('votes')
    .setDescription('Display current course voting results'),

  async execute(interaction) {
    try {
      // Defer reply to allow time for API calls
      await interaction.deferReply();

      commandLogger.info('Votes command executed', {
        userId: interaction.user.id,
        username: interaction.user.username,
        guildId: interaction.guildId
      });

      // Show loading message
      const loadingEmbed = new EmbedBuilder()
        .setColor(0x0099FF)
        .setTitle('⏳ Fetching Voting Results...')
        .setDescription('Please wait while we retrieve the current course voting data.');

      await interaction.editReply({ embeds: [loadingEmbed] });

      // Fetch voting results from API
      let votingData;
      try {
        votingData = await votesService.getVotingResults();
        
        commandLogger.debug('Voting data retrieved successfully', {
          itemsCount: votingData.items?.length || 0,
          hasMore: votingData.hasMore,
          count: votingData.count
        });
      } catch (error) {
        commandLogger.error('Failed to fetch voting results', {
          error: error.message,
          stack: error.stack,
          userId: interaction.user.id
        });

        // Handle API errors with user-friendly messages
        const processedError = votesService.handleApiError(error, 'votes_command_fetch');
        
        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Unable to Fetch Voting Results')
          .setDescription(processedError.message)
          .setFooter({ text: 'Please try again later or contact an Admin if the problem persists.' });

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      // Check if voting data is available
      if (!votingData.items || votingData.items.length === 0) {
        const noDataEmbed = new EmbedBuilder()
          .setColor(0xFFA500)
          .setTitle('📊 No Voting Data Available')
          .setDescription('There are currently no course voting results to display.')
          .setFooter({ text: 'Voting may not have started yet or no courses are available for voting.' });

        return await interaction.editReply({ embeds: [noDataEmbed] });
      }

      // Create voting results embed
      let votesEmbed;
      try {
        const embedData = votesService.createVotesEmbed(votingData);
        
        votesEmbed = new EmbedBuilder()
          .setTitle(embedData.title)
          .setColor(embedData.color)
          .setFooter(embedData.footer)
          .setTimestamp(new Date(embedData.timestamp));

        // Add fields for Easy and Hard courses
        embedData.fields.forEach(field => {
          votesEmbed.addFields({
            name: field.name,
            value: field.value,
            inline: field.inline
          });
        });

        commandLogger.info('Votes embed created successfully', {
          fieldsCount: embedData.fields.length,
          userId: interaction.user.id
        });

      } catch (error) {
        commandLogger.error('Failed to create votes embed', {
          error: error.message,
          stack: error.stack,
          userId: interaction.user.id,
          votingDataItems: votingData.items?.length || 0
        });

        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Data Processing Error')
          .setDescription('Unable to process the voting data for display. The data may be in an unexpected format.')
          .setFooter({ text: 'Please try again later or contact an Admin.' });

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      // Send the voting results embed
      await interaction.editReply({ embeds: [votesEmbed] });

      commandLogger.info('Votes command completed successfully', {
        userId: interaction.user.id,
        easyCoursesCount: votingData.items.filter(item => item.easy_course).length,
        hardCoursesCount: votingData.items.filter(item => item.hard_course).length
      });

    } catch (error) {
      commandLogger.error('Unexpected error in votes command', {
        error: error.message,
        stack: error.stack,
        userId: interaction.user.id,
        guildId: interaction.guildId
      });

      // Use error handler to create appropriate response
      await errorHandler.handleInteractionError(error, interaction, 'votes_command');
    }
  }
};
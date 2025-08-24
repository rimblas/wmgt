import {
  SlashCommandBuilder,
  EmbedBuilder
} from 'discord.js';
import { CourseLeaderboardService } from '../services/CourseLeaderboardService.js';
import { logger } from '../utils/Logger.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';

const courseLeaderboardService = new CourseLeaderboardService();
const commandLogger = logger.child({ command: 'course' });
const errorHandler = new ErrorHandler(commandLogger);

export default {
  data: new SlashCommandBuilder()
    .setName('course')
    .setDescription('Display leaderboard scores for a selected course')
    .addStringOption(option =>
      option.setName('course')
        .setDescription('Select a course to view leaderboard')
        .setRequired(true)
        .setAutocomplete(true)
    ),

  async execute(interaction) {
    try {
      // Defer reply to allow time for API calls
      await interaction.deferReply();

      const courseCode = interaction.options.getString('course');
      const userId = interaction.user.id;

      commandLogger.info('Course command executed', {
        userId: userId,
        username: interaction.user.username,
        guildId: interaction.guildId,
        courseCode: courseCode
      });

      // Validate course code parameter
      if (!courseCode || typeof courseCode !== 'string') {
        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Invalid Course Selection')
          .setDescription('Please select a valid course from the autocomplete options.')
          .setFooter({ text: 'Use the autocomplete feature to see available courses.' });

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      // Show loading message
      const loadingEmbed = new EmbedBuilder()
        .setColor(0x0099FF)
        .setTitle('⏳ Fetching Course Leaderboard...')
        .setDescription(`Please wait while we retrieve the leaderboard for course **${courseCode.toUpperCase()}**.`);

      await interaction.editReply({ embeds: [loadingEmbed] });

      // Fetch leaderboard data from API
      let leaderboardData;
      try {
        const apiResponse = await courseLeaderboardService.getCourseLeaderboard(courseCode, userId);
        leaderboardData = courseLeaderboardService.formatLeaderboardData(apiResponse, userId);
        
        commandLogger.debug('Leaderboard data retrieved successfully', {
          courseCode: courseCode,
          entriesCount: leaderboardData.entries?.length || 0,
          hasUserScores: leaderboardData.hasUserScores,
          totalEntries: leaderboardData.totalEntries
        });
      } catch (error) {
        commandLogger.error('Failed to fetch course leaderboard', {
          error: error.message,
          stack: error.stack,
          userId: userId,
          courseCode: courseCode
        });

        // Handle API errors with user-friendly messages
        const processedError = courseLeaderboardService.handleApiError(error, 'course_command_fetch');
        
        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Unable to Fetch Course Leaderboard')
          .setDescription(processedError.message)
          .setFooter({ text: 'Please try again later or contact an Admin if the problem persists.' });

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      // Check if leaderboard data is available
      if (!leaderboardData.entries || leaderboardData.entries.length === 0) {
        const noDataEmbed = new EmbedBuilder()
          .setColor(0xFFA500)
          .setTitle('📊 No Scores Available')
          .setDescription(`No scores have been recorded for course **${leaderboardData.course.name}** yet.`)
          .addFields({
            name: 'Course Information',
            value: `**Code:** ${leaderboardData.course.code}\n**Difficulty:** ${leaderboardData.course.difficulty}`,
            inline: false
          })
          .setFooter({ text: 'Be the first to play this course and set a score!' });

        return await interaction.editReply({ embeds: [noDataEmbed] });
      }

      // Create leaderboard embed with fallback to text display
      let leaderboardEmbed;
      let fallbackToText = false;
      
      try {
        const embedData = courseLeaderboardService.createLeaderboardEmbed(leaderboardData);
        
        leaderboardEmbed = new EmbedBuilder()
          .setTitle(embedData.title)
          .setColor(embedData.color)
          .setDescription(embedData.description)
          .setFooter(embedData.footer)
          .setTimestamp(new Date(embedData.timestamp));

        // Add fields from the embed data
        embedData.fields.forEach(field => {
          leaderboardEmbed.addFields({
            name: field.name,
            value: field.value,
            inline: field.inline
          });
        });

        commandLogger.info('Course leaderboard embed created successfully', {
          courseCode: courseCode,
          fieldsCount: embedData.fields.length,
          userId: userId
        });

      } catch (error) {
        commandLogger.error('Failed to create course leaderboard embed', {
          error: error.message,
          stack: error.stack,
          userId: userId,
          courseCode: courseCode,
          leaderboardEntries: leaderboardData.entries?.length || 0
        });

        // Set flag to use text fallback
        fallbackToText = true;
        
        commandLogger.info('Attempting fallback to text-based display', {
          userId: userId,
          courseCode: courseCode,
          reason: 'embed_creation_failed'
        });
      }

      // Try to send the leaderboard embed, with fallback to text
      try {
        if (!fallbackToText) {
          await interaction.editReply({ embeds: [leaderboardEmbed] });
        } else {
          // Fallback to text-based display
          const textDisplay = courseLeaderboardService.createTextDisplay(leaderboardData);
          await interaction.editReply({ 
            content: textDisplay,
            embeds: [] // Clear any existing embeds
          });
          
          commandLogger.info('Successfully sent text-based course leaderboard', {
            userId: userId,
            courseCode: courseCode,
            textLength: textDisplay.length
          });
        }
      } catch (sendError) {
        commandLogger.error('Failed to send course leaderboard (both embed and text)', {
          error: sendError.message,
          stack: sendError.stack,
          userId: userId,
          courseCode: courseCode,
          wasUsingFallback: fallbackToText
        });

        // Final fallback - simple error message
        const errorMessage = `❌ **Course Leaderboard Unavailable**\n\nUnable to display leaderboard for course **${courseCode.toUpperCase()}** due to a technical issue. Please try again later or contact support.`;
        
        try {
          await interaction.editReply({ 
            content: errorMessage,
            embeds: []
          });
        } catch (finalError) {
          commandLogger.error('Failed to send final error message', {
            error: finalError.message,
            userId: userId,
            courseCode: courseCode
          });
        }
        
        return;
      }

      commandLogger.info('Course command completed successfully', {
        userId: userId,
        courseCode: courseCode,
        entriesDisplayed: Math.min(leaderboardData.entries.length, 10),
        totalEntries: leaderboardData.totalEntries,
        hasUserScores: leaderboardData.hasUserScores
      });

    } catch (error) {
      commandLogger.error('Unexpected error in course command', {
        error: error.message,
        stack: error.stack,
        userId: interaction.user.id,
        guildId: interaction.guildId,
        courseCode: interaction.options?.getString('course')
      });

      // Use error handler to create appropriate response
      await errorHandler.handleInteractionError(error, interaction, 'course_command');
    }
  },

  async autocomplete(interaction) {
    try {
      const focusedValue = interaction.options.getFocused();
      
      commandLogger.debug('Course autocomplete requested', {
        userId: interaction.user.id,
        focusedValue: focusedValue,
        guildId: interaction.guildId
      });

      // Get available courses
      let courses;
      try {
        courses = await courseLeaderboardService.getAvailableCourses();
      } catch (error) {
        commandLogger.error('Failed to fetch courses for autocomplete', {
          error: error.message,
          userId: interaction.user.id,
          focusedValue: focusedValue
        });

        // Return fallback courses on error
        courses = courseLeaderboardService.getFallbackCourses();
      }

      // Filter courses based on user input with fuzzy matching
      const filtered = courses.filter(course => {
        if (!focusedValue) return true; // Show all if no input
        
        const searchTerm = focusedValue.toLowerCase();
        const courseCode = course.code.toLowerCase();
        const courseName = course.name.toLowerCase();
        
        // Match course code or course name
        return courseCode.includes(searchTerm) || courseName.includes(searchTerm);
      });

      // Sort by relevance (exact matches first, then partial matches)
      filtered.sort((a, b) => {
        if (!focusedValue) return a.code.localeCompare(b.code);
        
        const searchTerm = focusedValue.toLowerCase();
        const aCodeMatch = a.code.toLowerCase().startsWith(searchTerm);
        const bCodeMatch = b.code.toLowerCase().startsWith(searchTerm);
        
        // Prioritize code matches over name matches
        if (aCodeMatch && !bCodeMatch) return -1;
        if (!aCodeMatch && bCodeMatch) return 1;
        
        // Then sort alphabetically
        return a.code.localeCompare(b.code);
      });

      // Limit to 25 results as per Discord API limits
      const choices = filtered.slice(0, 25).map(course => ({
        name: `${course.code} - ${course.name}`,
        value: course.code
      }));

      commandLogger.debug('Course autocomplete results prepared', {
        userId: interaction.user.id,
        focusedValue: focusedValue,
        totalCourses: courses.length,
        filteredCount: filtered.length,
        choicesCount: choices.length
      });

      await interaction.respond(choices);

    } catch (error) {
      commandLogger.error('Error in course autocomplete', {
        error: error.message,
        stack: error.stack,
        userId: interaction.user.id,
        focusedValue: interaction.options?.getFocused()
      });

      // Return empty choices on error to prevent Discord API errors
      try {
        await interaction.respond([]);
      } catch (respondError) {
        commandLogger.error('Failed to respond to autocomplete with empty array', {
          error: respondError.message,
          userId: interaction.user.id
        });
      }
    }
  }
};
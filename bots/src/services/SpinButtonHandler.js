import { EmbedBuilder } from 'discord.js';
import { logger } from '../utils/Logger.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';
import { SpinService } from './SpinService.js';
import { CourseLeaderboardService } from './CourseLeaderboardService.js';

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
    this.courseLeaderboardService = new CourseLeaderboardService();
    this.logger = logger.child({ service: 'SpinButtonHandler' });
    this.errorHandler = new ErrorHandler(this.logger);
  }

  /**
   * Fetch top 3 leaderboard scores for a course.
   * Returns null on any failure (graceful degradation).
   * @param {string} courseCode - 3-letter course code (e.g., "ALE")
   * @param {string} userId - Discord user ID for highlighting
   * @returns {Promise<Object|null>} Formatted leaderboard data limited to top 3 distinct scores, or null
   */
  async fetchTop3Leaderboard(courseCode, userId) {
    try {
      const LEADERBOARD_TIMEOUT_MS = 5000;

      const fetchPromise = (async () => {
        const apiResponse = await this.courseLeaderboardService.getCourseLeaderboard(courseCode, userId);
        const formatted = this.courseLeaderboardService.formatLeaderboardData(apiResponse, userId);

        if (!formatted || !formatted.entries || formatted.entries.length === 0) {
          return null;
        }

        // Limit to entries for the top 3 distinct scores
        const distinctScores = [];
        for (const entry of formatted.entries) {
          if (!distinctScores.includes(entry.score)) {
            distinctScores.push(entry.score);
            if (distinctScores.length === 3) break;
          }
        }

        const limitedEntries = formatted.entries.filter(entry => distinctScores.includes(entry.score));

        return {
          ...formatted,
          entries: limitedEntries
        };
      })();

      let timeoutId;
      const timeoutPromise = new Promise((resolve) => {
        timeoutId = setTimeout(() => {
          this.logger.warn('Leaderboard fetch timed out', { courseCode, userId, timeoutMs: LEADERBOARD_TIMEOUT_MS });
          resolve(null);
        }, LEADERBOARD_TIMEOUT_MS);
      });

      const result = await Promise.race([fetchPromise, timeoutPromise]);
      clearTimeout(timeoutId);
      return result;
    } catch (error) {
      this.logger.warn('Failed to fetch leaderboard for spin result', {
        courseCode,
        userId,
        error: error.message
      });
      return null;
    }
  }

  /**
   * Format leaderboard data into a Discord embed field showing top 3 distinct scores.
   * All places show medal + score + player names (comma-delimited).
   * Names are progressively trimmed from lower places first if the field exceeds 1024 chars.
   * @param {Object|null} leaderboardData - Formatted data from CourseLeaderboardService
   * @returns {{ name: string, value: string, inline: boolean }|null} Embed field or null
   */
  formatLeaderboardField(leaderboardData) {
    if (!leaderboardData || !leaderboardData.entries || leaderboardData.entries.length === 0) {
      return null;
    }

    const medals = ['🥇', '🥈', '🥉'];
    const MAX_NAMES = 5;
    const DISCORD_FIELD_LIMIT = 1024;

    // Group entries by distinct score values
    const scoreGroups = new Map();
    for (const entry of leaderboardData.entries) {
      if (!scoreGroups.has(entry.score)) {
        scoreGroups.set(entry.score, []);
      }
      scoreGroups.get(entry.score).push(entry.playerName);
    }

    // Take up to 3 distinct score groups
    const groups = [...scoreGroups.entries()].slice(0, 3);

    // Helper: format a single line with a given name cap
    const formatLine = (medal, score, names, maxNames) => {
      const scoreDisplay = score < 0 ? `${score}` : `+${score}`;
      const formattedScore = `\`${scoreDisplay}\``;
      if (maxNames <= 0 || !names || names.length === 0) {
        return `${medal} ${formattedScore}`;
      }
      const cap = Math.min(maxNames, names.length);
      let nameDisplay;
      if (names.length > cap) {
        nameDisplay = `${names.slice(0, cap).join(', ')} +${names.length - cap} more`;
      } else {
        nameDisplay = names.join(', ');
      }
      return `${medal} ${formattedScore} **${nameDisplay}**`;
    };

    // Start with max names for each place, then trim from bottom up
    const nameCaps = groups.map(([, names]) => Math.min(MAX_NAMES, names.length));

    const buildValue = () => {
      const lines = groups.map(([score, names], i) =>
        formatLine(medals[i], score, names, nameCaps[i])
      );
      return lines.join('\n');
    };

    let value = buildValue();

    // Progressively reduce names from 3rd → 2nd → 1st until within limit
    if (value.length > DISCORD_FIELD_LIMIT) {
      for (let place = groups.length - 1; place >= 0; place--) {
        while (nameCaps[place] > 0 && value.length > DISCORD_FIELD_LIMIT) {
          nameCaps[place]--;
          value = buildValue();
        }
        if (value.length <= DISCORD_FIELD_LIMIT) break;
      }
    }

    // Last resort: hard truncate
    if (value.length > DISCORD_FIELD_LIMIT) {
      value = value.slice(0, DISCORD_FIELD_LIMIT);
    }

    return { name: '🏆 Best Scores', value, inline: false };
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

      // Fetch and attach leaderboard data (non-blocking — null means skip)
      const leaderboardData = await this.fetchTop3Leaderboard(selected.code, interaction.user.id);
      const leaderboardField = this.formatLeaderboardField(leaderboardData);
      if (leaderboardField) {
        embed.addFields(leaderboardField);
        const distinctScoresShown = leaderboardField.value.split('\n').length;
        this.logger.debug('Leaderboard included in spin result', {
          courseCode: selected.code,
          distinctScoresShown
        });
      }

      // Add selected-difficulty indicator to footer
      const footerLabel = DIFFICULTY_LABEL[interaction.customId];
      if (footerLabel) {
        embed.setFooter({ text: `Result for: ${footerLabel}` });
      }

      // Dismiss the ephemeral prompt, then send a public follow-up visible to everyone
      await interaction.update({ content: `Spun "${footerLabel}"!`, embeds: [], components: [] });
      await interaction.followUp({ embeds: [embed] });
    } catch (error) {
      this.logger.error('Unexpected error in handleSpin', { error: error.message });
      await this.errorHandler.handleInteractionError(error, interaction, 'SpinButtonHandler.handleSpin');
    }
  }
}

export { DIFFICULTY_MAP, DIFFICULTY_LABEL };

import { SlashCommandBuilder, ButtonBuilder, ButtonStyle, ActionRowBuilder } from 'discord.js';
import { logger } from '../utils/Logger.js';

const commandLogger = logger.child({ command: 'spin' });

export default {
  data: new SlashCommandBuilder()
    .setName('spin')
    .setDescription('Randomly select a Walkabout Mini Golf course'),

  async execute(interaction) {
    commandLogger.info('Spin command executed', {
      userId: interaction.user.id,
      username: interaction.user.username,
      guildId: interaction.guildId
    });

    const row = new ActionRowBuilder().addComponents(
      new ButtonBuilder()
        .setCustomId('spin_any')
        .setLabel('🎲 Any')
        .setStyle(ButtonStyle.Secondary),
      new ButtonBuilder()
        .setCustomId('spin_easy')
        .setLabel('🟢 Easy')
        .setStyle(ButtonStyle.Success),
      new ButtonBuilder()
        .setCustomId('spin_hard')
        .setLabel('🔵 Hard')
        .setStyle(ButtonStyle.Primary)
    );

    await interaction.reply({
      content: 'Pick a difficulty to spin a random course!',
      components: [row],
      ephemeral: true
    });
  }
};

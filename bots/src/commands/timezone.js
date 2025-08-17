import { SlashCommandBuilder } from 'discord.js';

export default {
  data: new SlashCommandBuilder()
    .setName('timezone')
    .setDescription('Set your preferred timezone')
    .addStringOption(option =>
      option.setName('timezone')
        .setDescription('Your timezone (e.g., America/New_York, Europe/London, Asia/Tokyo)')
        .setRequired(true)
    ),
  
  async execute(interaction) {
    // Placeholder implementation - will be completed in task 8
    await interaction.reply({
      content: '🚧 Timezone command is under development. This will be implemented in task 8.',
      ephemeral: true
    });
  }
};
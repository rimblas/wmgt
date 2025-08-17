import { SlashCommandBuilder } from 'discord.js';

export default {
  data: new SlashCommandBuilder()
    .setName('register')
    .setDescription('Register for a tournament session')
    .addStringOption(option =>
      option.setName('timezone')
        .setDescription('Your timezone (e.g., America/New_York, Europe/London)')
        .setRequired(false)
    ),
  
  async execute(interaction) {
    // Placeholder implementation - will be completed in task 5
    await interaction.reply({
      content: '🚧 Registration command is under development. This will be implemented in task 5.',
      ephemeral: true
    });
  }
};
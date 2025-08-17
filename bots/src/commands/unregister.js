import { SlashCommandBuilder } from 'discord.js';

export default {
  data: new SlashCommandBuilder()
    .setName('unregister')
    .setDescription('Unregister from a tournament session'),
  
  async execute(interaction) {
    // Placeholder implementation - will be completed in task 6
    await interaction.reply({
      content: '🚧 Unregister command is under development. This will be implemented in task 6.',
      ephemeral: true
    });
  }
};
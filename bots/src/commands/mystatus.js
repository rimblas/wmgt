import { SlashCommandBuilder, EmbedBuilder } from 'discord.js';
import { RegistrationService } from '../services/RegistrationService.js';
import { TimezoneService } from '../services/TimezoneService.js';

export default {
  data: new SlashCommandBuilder()
    .setName('mystatus')
    .setDescription('View your current tournament registrations')
    .addStringOption(option =>
      option.setName('timezone')
        .setDescription('Your timezone (e.g., America/New_York, EST, UTC)')
        .setRequired(false)
    ),
  
  async execute(interaction) {
    const registrationService = new RegistrationService();
    const timezoneService = new TimezoneService();
    
    // Get user's timezone preference (from command option or default to UTC)
    const userTimezone = interaction.options.getString('timezone') || 'UTC';
    
    try {
      // Validate timezone if provided
      if (!timezoneService.validateTimezone(userTimezone)) {
        await interaction.reply({
          content: `❌ Invalid timezone: \`${userTimezone}\`\n\nPlease use a valid timezone like:\n• \`America/New_York\` (Eastern Time)\n• \`America/Chicago\` (Central Time)\n• \`America/Los_Angeles\` (Pacific Time)\n• \`Europe/London\` (GMT/BST)\n• \`UTC\` (Coordinated Universal Time)\n\nOr use common abbreviations like \`EST\`, \`PST\`, \`GMT\`, etc.`,
          ephemeral: true
        });
        return;
      }

      // Show loading message
      await interaction.deferReply({ ephemeral: true });

      // Fetch user's registrations
      const registrationData = await registrationService.getPlayerRegistrations(interaction.user.id);
      
      // Create embed for displaying registration status
      const embed = new EmbedBuilder()
        .setColor(0x0099FF)
        .setTitle('🏆 Your Tournament Registrations')
        .setAuthor({
          name: interaction.user.displayName || interaction.user.username,
          iconURL: interaction.user.displayAvatarURL()
        })
        .setTimestamp();

      // Check if user has any registrations
      if (!registrationData.registrations || registrationData.registrations.length === 0) {
        embed.setDescription('📭 You are not currently registered for any tournaments.')
          .addFields({
            name: '💡 Want to register?',
            value: 'Use `/register` to sign up for the current tournament!',
            inline: false
          });
      } else {
        // Format and display registrations
        const registrations = registrationData.registrations;
        const playerName = registrationData.player?.name || interaction.user.displayName;
        
        embed.setDescription(`**Player:** ${playerName}\n**Active Registrations:** ${registrations.length}`);

        // Add each registration as a field
        for (const registration of registrations) {
          try {
            // Format the session date and time slot with timezone conversion
            const sessionDate = registration.session_date;
            const timeSlot = registration.time_slot;
            
            // Create a moment for the time slot on the session date
            const utcDateTime = `${sessionDate.split('T')[0]}T${timeSlot}:00.000Z`;
            const formattedTime = timezoneService.formatTimeDisplay(
              utcDateTime, 
              userTimezone, 
              { 
                showDate: true, 
                format12Hour: true, 
                showTimezone: true 
              }
            );

            // Build registration details
            let registrationDetails = `**Time:** ${formattedTime}\n`;
            
            if (registration.room_no) {
              registrationDetails += `**Room:** ${registration.room_no}\n`;
            } else {
              registrationDetails += `**Room:** *Not assigned yet*\n`;
            }
            
            registrationDetails += `**Session ID:** ${registration.session_id}`;

            embed.addFields({
              name: `📅 ${registration.week}`,
              value: registrationDetails,
              inline: false
            });
          } catch (timeError) {
            console.error('Error formatting time for registration:', timeError);
            // Fallback display without timezone conversion
            embed.addFields({
              name: `📅 ${registration.week}`,
              value: `**Time:** ${registration.time_slot} UTC\n**Room:** ${registration.room_no || '*Not assigned yet*'}\n**Session ID:** ${registration.session_id}`,
              inline: false
            });
          }
        }

        // Add footer with timezone info
        embed.setFooter({
          text: `Times shown in ${userTimezone} | Use /timezone to change your preference`
        });
      }

      await interaction.editReply({ embeds: [embed] });

    } catch (error) {
      console.error('Error in mystatus command:', error);
      
      let errorMessage = '❌ Failed to fetch your registration status.';
      
      if (error.message.includes('temporarily unavailable')) {
        errorMessage = '⚠️ The registration service is temporarily unavailable. Please try again later.';
      } else if (error.message.includes('connect')) {
        errorMessage = '🔌 Unable to connect to the tournament service. Please try again later.';
      }

      if (interaction.deferred) {
        await interaction.editReply({ content: errorMessage });
      } else {
        await interaction.reply({ content: errorMessage, ephemeral: true });
      }
    }
  }
};
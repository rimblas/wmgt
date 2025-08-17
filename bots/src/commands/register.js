import { 
  SlashCommandBuilder, 
  EmbedBuilder, 
  ActionRowBuilder, 
  StringSelectMenuBuilder,
  ButtonBuilder,
  ButtonStyle,
  ComponentType
} from 'discord.js';
import { RegistrationService } from '../services/RegistrationService.js';
import { TimezoneService } from '../services/TimezoneService.js';
import { logger } from '../utils/Logger.js';
import { ErrorHandler } from '../utils/ErrorHandler.js';

const registrationService = new RegistrationService();
const timezoneService = new TimezoneService();
const commandLogger = logger.child({ command: 'register' });
const errorHandler = new ErrorHandler(commandLogger);

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
    try {
      // Defer reply to allow time for API calls
      await interaction.deferReply({ ephemeral: true });

      // Get user's timezone preference
      let userTimezone = interaction.options.getString('timezone');
      
      // If no timezone provided, try to get stored preference
      if (!userTimezone) {
        userTimezone = await timezoneService.getUserTimezone(registrationService, interaction.user.id, 'UTC');
      }
      
      // Validate timezone if provided
      if (!timezoneService.validateTimezone(userTimezone)) {
        const commonTimezones = timezoneService.getCommonTimezones();
        const timezoneList = commonTimezones.map(tz => `• ${tz.value} - ${tz.label}`).join('\n');
        
        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Invalid Timezone')
          .setDescription(`The timezone "${userTimezone}" is not valid.`)
          .addFields({
            name: 'Common Timezones',
            value: timezoneList,
            inline: false
          })
          .setFooter({ text: 'Please use a valid IANA timezone name or common abbreviation.' });

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      // Fetch current tournament data
      let tournamentData;
      try {
        tournamentData = await registrationService.getCurrentTournament();
      } catch (error) {
        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Tournament Data Error')
          .setDescription(error.message)
          .setFooter({ text: 'Please try again later or contact support.' });

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      // Check if there are any active sessions
      if (!tournamentData.sessions || tournamentData.sessions.length === 0) {
        const noSessionsEmbed = new EmbedBuilder()
          .setColor(0xFFA500)
          .setTitle('📅 No Active Sessions')
          .setDescription('There are currently no tournament sessions available for registration.')
          .setFooter({ text: 'Check back later for new tournament sessions.' });

        return await interaction.editReply({ embeds: [noSessionsEmbed] });
      }

      // Filter for sessions with open registration
      const openSessions = tournamentData.sessions.filter(session => session.registration_open);
      
      if (openSessions.length === 0) {
        const closedEmbed = new EmbedBuilder()
          .setColor(0xFFA500)
          .setTitle('🔒 Registration Closed')
          .setDescription('Registration is currently closed for all tournament sessions.')
          .setFooter({ text: 'Registration may open again for future sessions.' });

        return await interaction.editReply({ embeds: [closedEmbed] });
      }

      // For now, handle single session (most common case)
      // TODO: In future, add session selection if multiple sessions are available
      const session = openSessions[0];

      // Format time slots with timezone conversion
      let formattedTimeSlots;
      try {
        formattedTimeSlots = timezoneService.formatTournamentTimeSlots(
          session.available_time_slots,
          session.session_date,
          userTimezone
        );
      } catch (error) {
        const errorEmbed = new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Timezone Error')
          .setDescription(`Error processing timezone "${userTimezone}": ${error.message}`)
          .setFooter({ text: 'Please try with a different timezone.' });

        return await interaction.editReply({ embeds: [errorEmbed] });
      }

      // Create tournament info embed
      const tournamentEmbed = new EmbedBuilder()
        .setColor(0x00AE86)
        .setTitle(`🏆 ${tournamentData.tournament.name}`)
        .setDescription(`Register for **${session.week}** tournament session`)
        .addFields(
          {
            name: '📅 Session Date',
            value: session.session_date ? new Date(session.session_date).toDateString() : 'TBD',
            inline: true
          },
          {
            name: '🌍 Your Timezone',
            value: userTimezone,
            inline: true
          },
          {
            name: '⏰ Registration Closes',
            value: session.close_registration_on ? 
              `<t:${Math.floor(new Date(session.close_registration_on).getTime() / 1000)}:R>` : 
              'TBD',
            inline: true
          }
        );

      // Add course information if available
      if (session.courses && session.courses.length > 0) {
        const courseList = session.courses.map(course => 
          `• **${course.course_name}** (${course.course_code}) - ${course.difficulty}`
        ).join('\n');
        
        tournamentEmbed.addFields({
          name: '🏌️ Courses',
          value: courseList,
          inline: false
        });
      }

      // Create time slot selection menu
      const timeSlotOptions = formattedTimeSlots.map(slot => ({
        label: `${slot.utcTime} UTC → ${slot.localTime} ${slot.localTimezone}`,
        description: slot.dateChanged ? 
          `UTC: ${slot.utcDate}, Local: ${slot.localDate}` : 
          `${slot.utcDate}`,
        value: slot.value
      }));

      // Split options into chunks of 25 (Discord limit)
      const optionChunks = [];
      for (let i = 0; i < timeSlotOptions.length; i += 25) {
        optionChunks.push(timeSlotOptions.slice(i, i + 25));
      }

      const selectMenus = optionChunks.map((chunk, index) => {
        return new StringSelectMenuBuilder()
          .setCustomId(`register_timeslot_${index}`)
          .setPlaceholder(`Choose a time slot ${optionChunks.length > 1 ? `(${index + 1}/${optionChunks.length})` : ''}`)
          .addOptions(chunk);
      });

      const actionRows = selectMenus.map(menu => new ActionRowBuilder().addComponents(menu));

      // Add cancel button
      const cancelButton = new ButtonBuilder()
        .setCustomId('register_cancel')
        .setLabel('Cancel')
        .setStyle(ButtonStyle.Secondary)
        .setEmoji('❌');

      actionRows.push(new ActionRowBuilder().addComponents(cancelButton));

      await interaction.editReply({
        embeds: [tournamentEmbed],
        components: actionRows
      });

      // Handle time slot selection
      const filter = (i) => i.user.id === interaction.user.id;
      const collector = interaction.channel.createMessageComponentCollector({
        filter,
        componentType: ComponentType.StringSelect,
        time: 300000 // 5 minutes
      });

      collector.on('collect', async (selectInteraction) => {
        if (selectInteraction.customId.startsWith('register_timeslot_')) {
          await handleTimeSlotSelection(selectInteraction, session, userTimezone, tournamentData);
        }
      });

      // Handle cancel button
      const buttonCollector = interaction.channel.createMessageComponentCollector({
        filter,
        componentType: ComponentType.Button,
        time: 300000 // 5 minutes
      });

      buttonCollector.on('collect', async (buttonInteraction) => {
        if (buttonInteraction.customId === 'register_cancel') {
          await buttonInteraction.update({
            embeds: [
              new EmbedBuilder()
                .setColor(0x808080)
                .setTitle('❌ Registration Cancelled')
                .setDescription('Tournament registration has been cancelled.')
            ],
            components: []
          });
          collector.stop();
          buttonCollector.stop();
        }
      });

      collector.on('end', (collected, reason) => {
        if (reason === 'time' && collected.size === 0) {
          interaction.editReply({
            embeds: [
              new EmbedBuilder()
                .setColor(0x808080)
                .setTitle('⏰ Registration Timeout')
                .setDescription('Registration timed out. Please run the command again to register.')
            ],
            components: []
          }).catch(() => {}); // Ignore errors if interaction is already handled
        }
      });

    } catch (error) {
      commandLogger.error('Error in register command', {
        error: error.message,
        stack: error.stack,
        userId: interaction.user.id,
        guildId: interaction.guildId
      });
      
      // Use error handler to create appropriate response
      await errorHandler.handleInteractionError(error, interaction, 'register_command');
    }
  }
};

/**
 * Handle time slot selection and registration confirmation
 */
async function handleTimeSlotSelection(interaction, session, userTimezone, tournamentData) {
  try {
    await interaction.deferUpdate();

    const selectedTimeSlot = interaction.values[0];
    
    // Format the selected time slot for display
    const formattedSlot = timezoneService.formatTournamentTimeSlots(
      [selectedTimeSlot],
      session.session_date,
      userTimezone
    )[0];

    // Create confirmation embed
    const confirmEmbed = new EmbedBuilder()
      .setColor(0xFFA500)
      .setTitle('⚠️ Confirm Registration')
      .setDescription(`Please confirm your registration for **${session.week}**`)
      .addFields(
        {
          name: '🏆 Tournament',
          value: tournamentData.tournament.name,
          inline: true
        },
        {
          name: '⏰ Time Slot',
          value: `${formattedSlot.utcTime} UTC\n${formattedSlot.localTime} ${formattedSlot.localTimezone}`,
          inline: true
        },
        {
          name: '📅 Date',
          value: formattedSlot.dateChanged ? 
            `UTC: ${formattedSlot.utcDate}\nLocal: ${formattedSlot.localDate}` :
            formattedSlot.utcDate,
          inline: true
        }
      )
      .setFooter({ text: 'This action cannot be undone easily. Make sure the time works for you!' });

    // Create confirmation buttons
    const confirmButton = new ButtonBuilder()
      .setCustomId(`confirm_register_${session.id}_${selectedTimeSlot}`)
      .setLabel('Confirm Registration')
      .setStyle(ButtonStyle.Success)
      .setEmoji('✅');

    const cancelButton = new ButtonBuilder()
      .setCustomId('register_cancel_confirm')
      .setLabel('Cancel')
      .setStyle(ButtonStyle.Secondary)
      .setEmoji('❌');

    const confirmRow = new ActionRowBuilder().addComponents(confirmButton, cancelButton);

    await interaction.editReply({
      embeds: [confirmEmbed],
      components: [confirmRow]
    });

    // Handle confirmation
    const filter = (i) => i.user.id === interaction.user.id;
    const confirmCollector = interaction.channel.createMessageComponentCollector({
      filter,
      componentType: ComponentType.Button,
      time: 60000 // 1 minute for confirmation
    });

    confirmCollector.on('collect', async (confirmInteraction) => {
      if (confirmInteraction.customId.startsWith('confirm_register_')) {
        await handleRegistrationConfirmation(confirmInteraction, session, selectedTimeSlot, userTimezone, tournamentData);
      } else if (confirmInteraction.customId === 'register_cancel_confirm') {
        await confirmInteraction.update({
          embeds: [
            new EmbedBuilder()
              .setColor(0x808080)
              .setTitle('❌ Registration Cancelled')
              .setDescription('Tournament registration has been cancelled.')
          ],
          components: []
        });
      }
      confirmCollector.stop();
    });

    confirmCollector.on('end', (collected, reason) => {
      if (reason === 'time' && collected.size === 0) {
        interaction.editReply({
          embeds: [
            new EmbedBuilder()
              .setColor(0x808080)
              .setTitle('⏰ Confirmation Timeout')
              .setDescription('Registration confirmation timed out. Please run the command again to register.')
          ],
          components: []
        }).catch(() => {}); // Ignore errors if interaction is already handled
      }
    });

  } catch (error) {
    console.error('Error handling time slot selection:', error);
    
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Selection Error')
          .setDescription('An error occurred while processing your time slot selection.')
      ],
      components: []
    });
  }
}

/**
 * Handle final registration confirmation and API call
 */
async function handleRegistrationConfirmation(interaction, session, timeSlot, userTimezone, tournamentData) {
  try {
    await interaction.deferUpdate();

    // Show loading message
    const loadingEmbed = new EmbedBuilder()
      .setColor(0x0099FF)
      .setTitle('⏳ Processing Registration...')
      .setDescription('Please wait while we register you for the tournament.');

    await interaction.editReply({
      embeds: [loadingEmbed],
      components: []
    });

    // Attempt registration
    try {
      const registrationResult = await registrationService.registerPlayer(
        interaction.user,
        session.id,
        timeSlot
      );

      // Format the time slot for success message
      const formattedSlot = timezoneService.formatTournamentTimeSlots(
        [timeSlot],
        session.session_date,
        userTimezone
      )[0];

      // Create success embed
      const successEmbed = new EmbedBuilder()
        .setColor(0x00FF00)
        .setTitle('✅ Registration Successful!')
        .setDescription(`You have been successfully registered for **${session.week}**`)
        .addFields(
          {
            name: '🏆 Tournament',
            value: tournamentData.tournament.name,
            inline: true
          },
          {
            name: '⏰ Time Slot',
            value: `${formattedSlot.utcTime} UTC\n${formattedSlot.localTime} ${formattedSlot.localTimezone}`,
            inline: true
          },
          {
            name: '📅 Date',
            value: formattedSlot.dateChanged ? 
              `UTC: ${formattedSlot.utcDate}\nLocal: ${formattedSlot.localDate}` :
              formattedSlot.utcDate,
            inline: true
          }
        );

      // Add room information if available
      if (registrationResult.registration?.room_no) {
        successEmbed.addFields({
          name: '🏠 Room Assignment',
          value: `Room ${registrationResult.registration.room_no}`,
          inline: true
        });
      }

      successEmbed.setFooter({ 
        text: 'Use /mystatus to view all your registrations or /unregister to cancel.' 
      });

      await interaction.editReply({
        embeds: [successEmbed]
      });

    } catch (registrationError) {
      console.error('Registration API error:', registrationError);
      
      const errorEmbed = new EmbedBuilder()
        .setColor(0xFF0000)
        .setTitle('❌ Registration Failed')
        .setDescription(registrationError.message)
        .setFooter({ text: 'Please try again or contact support if the problem persists.' });

      await interaction.editReply({
        embeds: [errorEmbed]
      });
    }

  } catch (error) {
    console.error('Error handling registration confirmation:', error);
    
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xFF0000)
          .setTitle('❌ Registration Error')
          .setDescription('An unexpected error occurred during registration.')
      ],
      components: []
    });
  }
}
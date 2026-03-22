import {
  StringSelectMenuBuilder,
  ActionRowBuilder,
  EmbedBuilder,
  ButtonBuilder,
  ButtonStyle,
  ComponentType
} from 'discord.js';
import { config } from '../config/config.js';
import { logger } from '../utils/Logger.js';
import { MyStatusService } from './MyStatusService.js';
import { getRulesText } from './RulesProvider.js';

/**
 * Handles all button and component interactions originating from the registration message.
 * Routes button clicks based on tournament state and player registration status.
 */
class RegistrationButtonHandler {
  constructor(registrationService, timezoneService, registrationMessageManager) {
    this.registrationService = registrationService;
    this.timezoneService = timezoneService;
    this.registrationMessageManager = registrationMessageManager;
    this.myStatusService = new MyStatusService(registrationService, timezoneService);
    this.logger = logger.child({ service: 'RegistrationButtonHandler' });
  }

  /**
   * Handle "My Room" button clicks from the ongoing registration message.
   * Mirrors /mystatus output and response style.
   *
   * @param {import('discord.js').ButtonInteraction} interaction
   */
  async handleMyRoomButton(interaction) {
    try {
      await interaction.deferReply({ ephemeral: true });
    } catch (deferError) {
      this.logger.error('Failed to defer my-room reply — interaction may have expired', { error: deferError.message });
      return;
    }

    try {
      const payload = await this.myStatusService.buildStatusPayload(interaction.user);
      await interaction.editReply(payload);
    } catch (error) {
      this.logger.error('Error handling my-room button', { error: error.message });
      await interaction.editReply({
        content: '⚠️ Could not load your room status right now. Please try again in a moment.'
      }).catch(() => {});
    }
  }

  /**
   * Refresh the persistent registration message immediately after a mutation
   * so player counts/time slots reflect the latest backend state.
   *
   * @private
   */
  async _refreshRegistrationMessage() {
    if (!this.registrationMessageManager) {
      return;
    }

    try {
      const latestTournamentData = await this.registrationService.getCurrentTournament();
      await this.registrationMessageManager.updateMessage(latestTournamentData);
      this.registrationMessageManager.lastTournamentData = latestTournamentData;
    } catch (error) {
      this.logger.warn('Failed to refresh registration message after mutation', { error: error.message });
    }
  }

  /**
   * Main entry point: route button click based on tournament state and player registration.
   *
   * Flow:
   *  1. Defer reply as ephemeral
   *  2. Fetch current tournament data
   *  3. Derive tournament state
   *  4. If ongoing → handleOngoingTournament
   *  5. If closed → reply with "no active tournament"
   *  6. Fetch player registrations
   *  7. If registered → handleExistingRegistration
   *  8. Else → handleNewRegistration
   *
   * @param {import('discord.js').ButtonInteraction} interaction
   */
  async handleRegisterButton(interaction) {
    try {
      await interaction.deferReply({ ephemeral: true });
    } catch (deferError) {
      // Interaction already expired or was acknowledged — nothing we can do
      this.logger.error('Failed to defer reply — interaction may have expired', { error: deferError.message });
      return;
    }

    try {
      const tournamentData = await this.registrationService.getCurrentTournament();
      const state = this.registrationMessageManager.deriveTournamentState(tournamentData);

      if (state === 'ongoing') {
        return this.handleOngoingTournament(interaction, tournamentData);
      }

      if (state === 'closed') {
        return interaction.editReply({
          content: '❌ There is no active tournament session right now. Check back soon!'
        });
      }

      // State is registration_open — check if player is already registered
      const registrationData = await this.registrationService.getPlayerRegistrations(interaction.user.id);

      const hasActiveRegistration =
        registrationData &&
        Array.isArray(registrationData.registrations) &&
        registrationData.registrations.length > 0;

      if (hasActiveRegistration) {
        return this.handleExistingRegistration(interaction, registrationData, tournamentData);
      }

      return this.handleNewRegistration(interaction, tournamentData);
    } catch (error) {
      this.logger.error('Error handling register button', { error: error.message });
      try {
        return await interaction.editReply({
          content: '⚠️ The tournament service is temporarily unavailable. Please try again in a few minutes.'
        });
      } catch (editError) {
        // editReply failed too — interaction is gone, nothing more we can do
        this.logger.error('Failed to send error message to user', { error: editError.message });
      }
    }
  }

  /**
   * Handle click when tournament is ongoing.
   * Responds with an ephemeral message explaining registration is locked.
   *
   * @param {import('discord.js').ButtonInteraction} interaction
   * @param {object} tournamentData
   */
  async handleOngoingTournament(interaction, tournamentData) {
    const timeSlots = tournamentData.sessions?.available_time_slots || [];
    const slotList = timeSlots
        .map(s => '`' + s.time_slot + ' UTC`' + ' <t:' + s.session_date_epoch + ':t>')
        .join('\n');

    const message = [
      '🔒 **Registration is locked** — the tournament is currently in progress.',
      '',
      slotList ? `**Time Slots:** ${slotList}` : '',
      '',
      'Registration changes are not allowed while the tournament is being played. Please check back after the session ends.',
      '',
      'To enter scores go to ',
      config.bot.tournamentMDurl
    ].filter(Boolean).join('\n');

    return interaction.editReply({ content: message });
  }

  /**
   * Flow for unregistered players: show time slots → confirm → register.
   *
   * 1. Get player timezone
   * 2. Format time slots (UTC + local if timezone available)
   * 3. Show select menu for time slot selection
   * 4. On select: show confirmation embed with details
   * 5. On confirm: register player, show success/error
   * 6. On cancel: show cancellation message
   * 7. On timeout: show timeout message
   *
   * @param {import('discord.js').ButtonInteraction} interaction
   * @param {object} tournamentData
   */
  async handleNewRegistration(interaction, tournamentData) {
    // 1. Get player's timezone
    const timezone = await this.timezoneService.getUserTimezone(
      this.registrationService,
      interaction.user.id
    );

    // 2. Format time slots with timezone info
    const formattedSlots = this.timezoneService.formatTournamentTimeSlots(
      tournamentData.sessions.available_time_slots,
      tournamentData.sessions.session_date,
      timezone
    );

    // 3. Build select menu options
    const isUTC = timezone === 'UTC';
    const options = formattedSlots.map((slot, index) => {
      const label = isUTC
        ? `${slot.utcTime} UTC`
        : `${slot.localTime} ${slot.localTimezone} (${slot.utcTime} UTC)`;
      const description = slot.dateChanged
        ? `${slot.localDate}`
        : `${slot.utcDate}`;

      return {
        label,
        description,
        value: slot.value.time_slot
      };
    });

    const selectMenu = new StringSelectMenuBuilder()
      .setCustomId('reg_timeslot_select')
      .setPlaceholder('Choose a time slot')
      .addOptions(options);

    const selectRow = new ActionRowBuilder().addComponents(selectMenu);

    // Build the prompt content
    const week = tournamentData.sessions.week || 'Current Week';
    let content = `⏰ **Select a time slot for ${week}:**`;
    if (isUTC) {
      content += '\n\n💡 *Tip: Use the `/timezone` command to set your timezone and see local times.*';
    }

    // 4. Edit the deferred reply with the select menu
    const replyMessage = await interaction.editReply({
      content,
      components: [selectRow]
    });

    // 5. Create collector on the reply message
    const collector = replyMessage.createMessageComponentCollector({
      filter: (i) => i.user.id === interaction.user.id,
      time: 300000 // 5 minutes
    });

    collector.on('collect', async (componentInteraction) => {
      try {
        if (componentInteraction.customId === 'reg_timeslot_select') {
          // Time slot selected — show rules then confirmation
          collector.stop('selection_made');
          await this._handleRulesDisplay(
            interaction, componentInteraction, tournamentData, formattedSlots, timezone
          );
        }
      } catch (error) {
        this.logger.error('Error handling time slot selection', { error: error.message });
        try {
          await interaction.editReply({
            content: '❌ An error occurred while processing your selection. Please try again.',
            components: [],
            embeds: []
          });
        } catch (editError) {
          // Interaction may have expired
        }
      }
    });

    collector.on('end', (collected, reason) => {
      if (reason === 'time') {
        interaction.editReply({
          content: '⏰ Time slot selection timed out. Click **Register Now** again to start over.',
          components: [],
          embeds: []
        }).catch(() => {}); // Ignore if interaction expired
      }
    });
  }

  /**
   * Shows tournament rules to the player and waits for acknowledgment before proceeding to confirmation.
   *
   * @param {import('discord.js').ButtonInteraction} interaction - The ORIGINAL deferred interaction
   * @param {import('discord.js').StringSelectMenuInteraction} selectInteraction
   * @param {object} tournamentData
   * @param {Array} formattedSlots
   * @param {string} timezone
   * @private
   */
  async _handleRulesDisplay(interaction, selectInteraction, tournamentData, formattedSlots, timezone) {
    await selectInteraction.deferUpdate();

    let rulesText;
    try {
      rulesText = await getRulesText();
    } catch (error) {
      this.logger.error('Failed to load tournament rules', { error: error.message });
      // Fallback: proceed directly to confirmation without rules
      await this._handleTimeSlotConfirmation(interaction, null, tournamentData, formattedSlots, timezone, selectInteraction.values[0]);
      return;
    }

    // Truncate if exceeding Discord embed description limit (4096 chars)
    const maxLen = 4096;
    let description = rulesText;
    if (description.length > maxLen) {
      description = description.substring(0, maxLen - 50) + '\n\n...Rules truncated. Visit the tournament website for full details.';
    }

    const rulesEmbed = new EmbedBuilder()
      .setColor(0x0099FF)
      .setTitle('📜 Tournament Rules')
      .setDescription(description)
      .setFooter({ text: 'Please read the rules carefully before registering.' });

    const acknowledgeButton = new ButtonBuilder()
      .setCustomId('reg_rules_acknowledge')
      .setLabel('Acknowledge Rules and Register')
      .setStyle(ButtonStyle.Success)
      .setEmoji('✅');

    const cancelButton = new ButtonBuilder()
      .setCustomId('reg_rules_cancel')
      .setLabel('Cancel')
      .setStyle(ButtonStyle.Danger)
      .setEmoji('❌');

    const buttonRow = new ActionRowBuilder().addComponents(acknowledgeButton, cancelButton);

    const rulesMessage = await interaction.editReply({
      content: null,
      embeds: [rulesEmbed],
      components: [buttonRow]
    });

    const buttonCollector = rulesMessage.createMessageComponentCollector({
      filter: (i) => i.user.id === interaction.user.id,
      componentType: ComponentType.Button,
      time: 300000 // 5 minutes
    });

    const selectedTimeSlot = selectInteraction.values[0];

    buttonCollector.on('collect', async (buttonInteraction) => {
      try {
        if (buttonInteraction.customId === 'reg_rules_acknowledge') {
          buttonCollector.stop('acknowledged');
          const selectedSlot = formattedSlots.find(s => s.value.time_slot === selectedTimeSlot);
          await this._processRegistration(
            buttonInteraction, tournamentData, selectedTimeSlot, selectedSlot, timezone
          );
        } else if (buttonInteraction.customId === 'reg_rules_cancel') {
          buttonCollector.stop('cancelled');
          await buttonInteraction.update({
            content: '👌 Registration cancelled.',
            embeds: [],
            components: []
          });
        }
      } catch (error) {
        this.logger.error('Error handling rules button', { error: error.message });
        try {
          await interaction.editReply({
            content: '❌ An error occurred. Please try again.',
            embeds: [],
            components: []
          });
        } catch (editError) {
          // Interaction may have expired
        }
      }
    });

    buttonCollector.on('end', (collected, reason) => {
      if (reason === 'time') {
        interaction.editReply({
          content: '⏰ Rules acknowledgment timed out. Click **Register Now** again to start over.',
          embeds: [],
          components: []
        }).catch(() => {});
      }
    });
  }

  /**
   * Show confirmation embed after time slot selection, then handle confirm/cancel.
   *
   * @param {import('discord.js').ButtonInteraction} interaction - The ORIGINAL deferred interaction
   * @param {import('discord.js').StringSelectMenuInteraction} selectInteraction
   * @param {object} tournamentData
   * @param {Array} formattedSlots
   * @param {string} timezone
   * @private
   */
  async _handleTimeSlotConfirmation(interaction, selectInteraction, tournamentData, formattedSlots, timezone, selectedTimeSlotOverride) {
    if (selectInteraction) {
      await selectInteraction.deferUpdate();
    }

    const selectedTimeSlot = selectedTimeSlotOverride || selectInteraction.values[0];
    const selectedSlot = formattedSlots.find(s => s.value.time_slot === selectedTimeSlot);
    const timeSlot = selectedTimeSlot || 'Unknown';
    const sessionEpoch = selectedSlot.session_date_epoch || 'Unknown';

    const week = tournamentData.sessions.week || 'Current Week';
    const isUTC = timezone === 'UTC';

    // Build time display
    const timeDisplay = isUTC
      ? `${selectedSlot.utcTime} UTC`
      : `${selectedSlot.localTime} ${selectedSlot.localTimezone} (${selectedSlot.utcTime} UTC)`;

    const dateDisplay = selectedSlot.dateChanged
      ? `${selectedSlot.localDate} / UTC: ${selectedSlot.utcDate}`
      : selectedSlot.utcDate;

    // Build confirmation embed
    const confirmEmbed = new EmbedBuilder()
      .setColor(0xFFA500)
      .setTitle('⚠️ Confirm Registration')
      .setDescription(`Please confirm your registration for **${week}**`)
      .addFields(
        { name: '⏰ Time Slot', value: `${timeSlot} UTC <t:${sessionEpoch}:f>`, inline: true }
        
//        { name: '⏰ Time Slot', value: timeDisplay, inline: true },
//        { name: '📅 Date', value: dateDisplay, inline: true }
      );

    if (tournamentData.tournament?.name) {
      confirmEmbed.spliceFields(0, 0, {
        name: '🏆 Tournament',
        value: tournamentData.tournament.name,
        inline: true
      });
    }

    if (Array.isArray(tournamentData.sessions.courses) && tournamentData.sessions.courses.length > 0) {
      const courseList = tournamentData.sessions.courses.map(c => '•' + c.course_name).join('\n');
      confirmEmbed.addFields({ name: '⛳ Courses', value: courseList, inline: false });
    }

    // Build confirm/cancel buttons
    const confirmButton = new ButtonBuilder()
      .setCustomId(`reg_confirm_${tournamentData.sessions.id}_${selectedTimeSlot}`)
      .setLabel('Confirm Registration')
      .setStyle(ButtonStyle.Success)
      .setEmoji('✅');

    const cancelButton = new ButtonBuilder()
      .setCustomId('reg_cancel')
      .setLabel('Cancel')
      .setStyle(ButtonStyle.Danger)
      .setEmoji('❌');

    const buttonRow = new ActionRowBuilder().addComponents(confirmButton, cancelButton);

    const confirmMessage = await interaction.editReply({
      content: null,
      embeds: [confirmEmbed],
      components: [buttonRow]
    });

    // Collect confirm/cancel button clicks
    const buttonCollector = confirmMessage.createMessageComponentCollector({
      filter: (i) => i.user.id === interaction.user.id,
      componentType: ComponentType.Button,
      time: 300000 // 5 minutes
    });

    buttonCollector.on('collect', async (buttonInteraction) => {
      try {
        if (buttonInteraction.customId.startsWith('reg_confirm_')) {
          buttonCollector.stop('confirmed');
          await this._processRegistration(
            buttonInteraction, tournamentData, selectedTimeSlot, selectedSlot, timezone
          );
        } else if (buttonInteraction.customId === 'reg_cancel') {
          buttonCollector.stop('cancelled');
          await buttonInteraction.update({
            content: '👌 Registration cancelled.',
            embeds: [],
            components: []
          });
        }
      } catch (error) {
        this.logger.error('Error handling confirmation button', { error: error.message });
        try {
          await interaction.editReply({
            content: '❌ An error occurred. Please try again.',
            embeds: [],
            components: []
          });
        } catch (editError) {
          // Interaction may have expired
        }
      }
    });

    buttonCollector.on('end', (collected, reason) => {
      if (reason === 'time') {
        interaction.editReply({
          content: '⏰ Confirmation timed out. Click **Register Now** again to start over.',
          embeds: [],
          components: []
        }).catch(() => {});
      }
    });
  }

  /**
   * Call the registration API and show success or error.
   *
   * @param {import('discord.js').ButtonInteraction} buttonInteraction
   * @param {object} tournamentData
   * @param {string} selectedTimeSlot
   * @param {object} selectedSlot - formatted slot object
   * @param {string} timezone
   * @private
   */
  async _processRegistration(buttonInteraction, tournamentData, selectedTimeSlot, selectedSlot, timezone) {
    await buttonInteraction.deferUpdate();

    try {
      const result = await this.registrationService.registerPlayer(
        buttonInteraction.user,
        tournamentData.sessions.id,
        selectedTimeSlot,
        timezone
      );

      const week = tournamentData.sessions.week || 'Current Week';
      const isUTC = timezone === 'UTC';
      const timeDisplay = isUTC
        ? `${selectedSlot.utcTime} UTC`
        : `${selectedSlot.localTime} ${selectedSlot.localTimezone} (${selectedSlot.utcTime} UTC)`;

      const successEmbed = new EmbedBuilder()
        .setColor(0x00FF00)
        .setTitle('✅ Registration Successful!')
        .setDescription(`You have been registered for **${week}**`)
        .addFields(
          // { name: '⏰ Time Slot', value: timeDisplay, inline: true }
          { name: '⏰ Time Slot', value: `<t:${selectedSlot.session_date_epoch}:f>`, inline: true }
        );

      if (Array.isArray(tournamentData.sessions.courses) && tournamentData.sessions.courses.length > 0) {
        const courseList = tournamentData.sessions.courses.map(c => '•' + c.course_name).join('\n');
        successEmbed.addFields({ name: '⛳ Courses', value: courseList, inline: false });
      }
        

      if (result.registration?.room_no) {
        successEmbed.addFields({
          name: '🏠 Room',
          value: `Room ${result.registration.room_no}`,
          inline: true
        });
      }

      successEmbed.setFooter({
        text: 'Use /mystatus to view your registrations or /unregister to cancel.'
      });

      await buttonInteraction.editReply({
        content: null,
        embeds: [successEmbed],
        components: []
      });

      await this._refreshRegistrationMessage();
    } catch (error) {
      this.logger.error('Registration failed', { error: error.message });

      const errorEmbed = new EmbedBuilder()
        .setColor(0xFF0000)
        .setTitle('❌ Registration Failed')
        .setDescription(error.message || 'An unexpected error occurred.')
        .setFooter({ text: 'Please try again or contact an admin if the problem persists.' });

      await buttonInteraction.editReply({
        content: null,
        embeds: [errorEmbed],
        components: []
      });
    }
  }

  /**
   * Flow for registered players: show current reg + Change/Unregister options.
   * Stub — will be implemented in Task 6.1.
   *
   * @param {import('discord.js').ButtonInteraction} interaction
   * @param {object} registrationData
   * @param {object} tournamentData
   */
  /**
     * Flow for registered players: show current registration details with
     * "Change Time Slot" and "Unregister" buttons.
     *
     * @param {import('discord.js').ButtonInteraction} interaction
     * @param {object} registrationData
     * @param {object} tournamentData
     */
    async handleExistingRegistration(interaction, registrationData, tournamentData) {
      const currentRegistration = registrationData.registrations[0];

      // Find the matching time slot from tournament data to get the epoch
      const timeSlots = tournamentData.sessions?.available_time_slots || [];
      const matchedSlot = timeSlots.find(s => s.time_slot === currentRegistration.time_slot);

      // Build time slot display using Discord epoch timestamp (auto-localizes for each user)
/*      
      let timeSlotDisplay;
      if (matchedSlot?.session_date_epoch) {
        timeSlotDisplay = `\`${currentRegistration.time_slot} UTC\` <t:${matchedSlot.session_date_epoch}:t>`;
      } else {
        timeSlotDisplay = `${currentRegistration.time_slot} UTC`;
      }
*/
      // Build session date display using Discord epoch timestamp
      let sessionDateDisplay;
      if (matchedSlot?.session_date_epoch) {
        sessionDateDisplay = `<t:${matchedSlot.session_date_epoch}:f>`;
      } else {
        sessionDateDisplay = currentRegistration.session_date || 'Unknown';
      }

      // Build embed showing current registration details
      const embed = new EmbedBuilder()
        .setColor(0x0099FF)
        .setTitle('📋 Your Current Registration')
        .addFields(
          { name: '🏆 Tournament', value: currentRegistration.tournament_name || tournamentData.tournament?.name || 'Unknown', inline: true },
          { name: '📅 Week', value: currentRegistration.week || tournamentData.sessions?.week || 'Unknown', inline: true },
        //  { name: '⏰ Time Slot', value: timeSlotDisplay, inline: false },
          { name: '📆 Signed up for', value: sessionDateDisplay, inline: false }
        );

      // Build "Change Time Slot" and "Unregister" buttons
      const changeSlotButton = new ButtonBuilder()
        .setCustomId('reg_change_slot')
        .setLabel('Change Time Slot')
        .setStyle(ButtonStyle.Primary)
        .setEmoji('🔄');

      const unregisterButton = new ButtonBuilder()
        .setCustomId('reg_unregister')
        .setLabel('Unregister')
        .setStyle(ButtonStyle.Danger)
        .setEmoji('🗑️');

      const buttonRow = new ActionRowBuilder().addComponents(changeSlotButton, unregisterButton);

      // Edit the deferred reply with embed and buttons
      const replyMessage = await interaction.editReply({
        content: null,
        embeds: [embed],
        components: [buttonRow]
      });

      // Create a component collector with 5-minute timeout
      const collector = replyMessage.createMessageComponentCollector({
        filter: (i) => i.user.id === interaction.user.id,
        componentType: ComponentType.Button,
        time: 300000 // 5 minutes
      });

      collector.on('collect', async (buttonInteraction) => {
        try {
          await buttonInteraction.deferUpdate();
          if (buttonInteraction.customId === 'reg_change_slot') {
            collector.stop('change_slot');
            await this.handleTimeSlotChange(interaction, currentRegistration, tournamentData);
          } else if (buttonInteraction.customId === 'reg_unregister') {
            collector.stop('unregister');
            await this.handleUnregister(interaction, currentRegistration);
          }
        } catch (error) {
          this.logger.error('Error handling existing registration button', { error: error.message });
          try {
            await interaction.editReply({
              content: '❌ An error occurred while processing your request. Please try again.',
              embeds: [],
              components: []
            });
          } catch (editError) {
            // Interaction may have expired
          }
        }
      });

      collector.on('end', (collected, reason) => {
        if (reason === 'time') {
          interaction.editReply({
            content: '⏰ Interaction timed out. Click **Register Now** again to manage your registration.',
            embeds: [],
            components: []
          }).catch(() => {}); // Ignore if interaction expired
        }
      });
    }


  /**
     * Handle time slot change: show slots → register new.
     *
     * Flow:
     *  1. Get player timezone
     *  2. Format available time slots
     *  3. Show select menu with available slots
     *  4. On selection: register for new slot, show success/error
     *  5. On timeout: show timeout message
     *
     * @param {import('discord.js').ButtonInteraction} interaction - The ORIGINAL button interaction (already deferred)
     * @param {object} currentRegistration
     * @param {object} tournamentData
     */
    async handleTimeSlotChange(interaction, currentRegistration, tournamentData) {
      // 1. Get player timezone
      const timezone = await this.timezoneService.getUserTimezone(
        this.registrationService,
        interaction.user.id
      );

      // 2. Format available time slots
      const formattedSlots = this.timezoneService.formatTournamentTimeSlots(
        tournamentData.sessions.available_time_slots,
        tournamentData.sessions.session_date,
        timezone
      );

      // 3. Build select menu
      const isUTC = timezone === 'UTC';
      const options = formattedSlots.map((slot) => {
        const label = isUTC
          ? `${slot.utcTime} UTC`
          : `${slot.localTime} ${slot.localTimezone} (${slot.utcTime} UTC)`;
        const description = slot.dateChanged
          ? `${slot.localDate}`
          : `${slot.utcDate}`;

        return {
          label,
          description,
          value: slot.value.time_slot
        };
      });

      const selectMenu = new StringSelectMenuBuilder()
        .setCustomId('reg_change_timeslot_select')
        .setPlaceholder('Choose a new time slot')
        .addOptions(options);

      const selectRow = new ActionRowBuilder().addComponents(selectMenu);

      const week = tournamentData.sessions.week || 'Current Week';
      let content = `🔄 **Select a new time slot for ${week}:**\n\nYour current slot is **${currentRegistration.time_slot} UTC**. You will keep it unless your new selection is successfully saved.`;
      if (isUTC) {
        content += '\n\n💡 *Tip: Use the `/timezone` command to set your timezone and see local times.*';
      }

      const replyMessage = await interaction.editReply({
        content,
        embeds: [],
        components: [selectRow]
      });

      // 4. Create collector for time slot selection
      const collector = replyMessage.createMessageComponentCollector({
        filter: (i) => i.user.id === interaction.user.id,
        time: 300000 // 5 minutes
      });

      collector.on('collect', async (selectInteraction) => {
        try {
          if (selectInteraction.customId === 'reg_change_timeslot_select') {
            collector.stop('selection_made');
            await selectInteraction.deferUpdate();

            const selectedTimeSlot = selectInteraction.values[0];
            const selectedSlot = formattedSlots.find(s => s.value.time_slot === selectedTimeSlot);

            try {
              const result = await this.registrationService.registerPlayer(
                interaction.user,
                tournamentData.sessions.id,
                selectedTimeSlot,
                timezone
              );

              const timeDisplay = isUTC
                ? `${selectedSlot.utcTime} UTC`
                : `${selectedSlot.localTime} ${selectedSlot.localTimezone} (${selectedSlot.utcTime} UTC)`;

              const successEmbed = new EmbedBuilder()
                .setColor(0x00FF00)
                .setTitle('✅ Time Slot Changed Successfully!')
                .setDescription(`You have been re-registered for **${week}**`)
                .addFields(
                  { name: '⏰ New Time Slot', value: timeDisplay, inline: true }
                );

              if (result.registration?.room_no) {
                successEmbed.addFields({
                  name: '🏠 Room',
                  value: `Room ${result.registration.room_no}`,
                  inline: true
                });
              }

              successEmbed.setFooter({
                text: 'Use /mystatus to view your registrations.'
              });

              await interaction.editReply({
                content: null,
                embeds: [successEmbed],
                components: []
              });

              await this._refreshRegistrationMessage();
            } catch (regError) {
              this.logger.error('Time slot update failed', { error: regError.message });

              const errorEmbed = new EmbedBuilder()
                .setColor(0xFF0000)
                .setTitle('❌ Time Slot Change Failed')
                .setDescription(regError.message || 'An unexpected error occurred.')
                .setFooter({ text: 'Your existing registration is unchanged. Please try again.' });

              await interaction.editReply({
                content: null,
                embeds: [errorEmbed],
                components: []
              });
            }
          }
        } catch (error) {
          this.logger.error('Error handling time slot change selection', { error: error.message });
          try {
            await interaction.editReply({
              content: '❌ An error occurred while processing your selection. Please try again.',
              components: [],
              embeds: []
            });
          } catch (editError) {
            // Interaction may have expired
          }
        }
      });

      collector.on('end', (collected, reason) => {
        if (reason === 'time') {
          interaction.editReply({
            content: '⏰ Time slot selection timed out. Click **Register Now** again to start over.',
            components: [],
            embeds: []
          }).catch(() => {}); // Ignore if interaction expired
        }
      });
    }


  /**
   * Handle unregistration: show confirmation → on confirm call unregisterPlayer → show result.
   *
   * The `interaction` parameter is the ORIGINAL button interaction from handleExistingRegistration
   * (already deferred as ephemeral). All updates go through interaction.editReply().
   *
   * @param {import('discord.js').ButtonInteraction} interaction
   * @param {object} currentRegistration - { session_id, time_slot, session_date, tournament_name, week }
   */
  async handleUnregister(interaction, currentRegistration) {
    const week = currentRegistration.week || 'Current Week';
    const timeSlot = currentRegistration.time_slot || 'Unknown';
    const sessionEpoch = currentRegistration.session_date_epoch || 'Unknown';

    // Build confirmation embed
    const confirmEmbed = new EmbedBuilder()
      .setColor(0xFFA500)
      .setTitle('⚠️ Confirm Unregistration')
      .setDescription(`Are you sure you want to unregister from **${week}**?`)
      .addFields(
        { name: '⏰ Time Slot', value: `${timeSlot} UTC <t:${sessionEpoch}:f>`, inline: true }
      );

    if (currentRegistration.tournament_name) {
      confirmEmbed.spliceFields(0, 0, {
        name: '🏆 Tournament',
        value: currentRegistration.tournament_name,
        inline: true
      });
    }

    // Build confirm/cancel buttons
    const confirmButton = new ButtonBuilder()
      .setCustomId(`reg_confirm_unreg_${currentRegistration.session_id}`)
      .setLabel('Confirm Unregistration')
      .setStyle(ButtonStyle.Danger)
      .setEmoji('🗑️');

    const cancelButton = new ButtonBuilder()
      .setCustomId('reg_cancel')
      .setLabel('Cancel')
      .setStyle(ButtonStyle.Secondary)
      .setEmoji('❌');

    const buttonRow = new ActionRowBuilder().addComponents(confirmButton, cancelButton);

    const confirmMessage = await interaction.editReply({
      content: null,
      embeds: [confirmEmbed],
      components: [buttonRow]
    });

    // Collect confirm/cancel button clicks
    const buttonCollector = confirmMessage.createMessageComponentCollector({
      filter: (i) => i.user.id === interaction.user.id,
      componentType: ComponentType.Button,
      time: 300000 // 5 minutes
    });

    buttonCollector.on('collect', async (buttonInteraction) => {
      try {
        if (buttonInteraction.customId.startsWith('reg_confirm_unreg_')) {
          buttonCollector.stop('confirmed');
          await buttonInteraction.deferUpdate();

          try {
            await this.registrationService.unregisterPlayer(
              interaction.user,
              currentRegistration.session_id
            );

            const successEmbed = new EmbedBuilder()
              .setColor(0x00FF00)
              .setTitle('👋 Unregistration Successful')
              .setDescription(`You have been unregistered from **${week}**.`)
              .setFooter({ text: 'Click "Register Now..." again to sign up for a different time slot.' });

            await interaction.editReply({
              content: null,
              embeds: [successEmbed],
              components: []
            });

            await this._refreshRegistrationMessage();
          } catch (error) {
            this.logger.error('Unregistration failed', { error: error.message });

            const errorEmbed = new EmbedBuilder()
              .setColor(0xFF0000)
              .setTitle('❌ Unregistration Failed')
              .setDescription(error.message || 'An unexpected error occurred.')
              .setFooter({ text: 'Your current registration is unchanged. Please try again.' });

            await interaction.editReply({
              content: null,
              embeds: [errorEmbed],
              components: []
            });
          }
        } else if (buttonInteraction.customId === 'reg_cancel') {
          buttonCollector.stop('cancelled');
          await buttonInteraction.update({
            content: '👌 Your registration is unchanged.',
            embeds: [],
            components: []
          });
        }
      } catch (error) {
        this.logger.error('Error handling unregister confirmation', { error: error.message });
        try {
          await interaction.editReply({
            content: '❌ An error occurred. Please try again.',
            embeds: [],
            components: []
          });
        } catch (editError) {
          // Interaction may have expired
        }
      }
    });

    buttonCollector.on('end', (collected, reason) => {
      if (reason === 'time') {
        interaction.editReply({
          content: '⏰ Confirmation timed out. Click **Register Now** again to manage your registration.',
          embeds: [],
          components: []
        }).catch(() => {}); // Ignore if interaction expired
      }
    });
  }
}

export default RegistrationButtonHandler;

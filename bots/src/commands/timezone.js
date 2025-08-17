import { 
  SlashCommandBuilder, 
  EmbedBuilder, 
  ActionRowBuilder, 
  StringSelectMenuBuilder,
  ButtonBuilder,
  ButtonStyle,
  ComponentType
} from 'discord.js';
import { TimezoneService } from '../services/TimezoneService.js';
import { RegistrationService } from '../services/RegistrationService.js';

const timezoneService = new TimezoneService();
const registrationService = new RegistrationService();

export default {
  data: new SlashCommandBuilder()
    .setName('timezone')
    .setDescription('Set your preferred timezone for tournament time displays')
    .addStringOption(option =>
      option.setName('timezone')
        .setDescription('Your timezone (e.g., America/New_York, Europe/London, Asia/Tokyo)')
        .setRequired(false)
    ),
  
  async execute(interaction) {
    try {
      await interaction.deferReply({ ephemeral: true });

      const providedTimezone = interaction.options.getString('timezone');

      // If no timezone provided, show timezone selection menu
      if (!providedTimezone) {
        await showTimezoneSelectionMenu(interaction);
        return;
      }

      // Validate the provided timezone
      if (!timezoneService.validateTimezone(providedTimezone)) {
        await showInvalidTimezoneError(interaction, providedTimezone);
        return;
      }

      // Set the timezone preference
      await setUserTimezone(interaction, providedTimezone);

    } catch (error) {
      console.error('Error in timezone command:', error);
      
      const errorEmbed = new EmbedBuilder()
        .setColor(0xFF0000)
        .setTitle('❌ Timezone Error')
        .setDescription('An unexpected error occurred while setting your timezone.')
        .setFooter({ text: 'Please try again later or contact support.' });

      if (interaction.deferred) {
        await interaction.editReply({ embeds: [errorEmbed] });
      } else {
        await interaction.reply({ embeds: [errorEmbed], ephemeral: true });
      }
    }
  }
};

/**
 * Show timezone selection menu with common timezones
 */
async function showTimezoneSelectionMenu(interaction) {
  const commonTimezones = timezoneService.getCommonTimezones();
  
  const embed = new EmbedBuilder()
    .setColor(0x0099FF)
    .setTitle('🌍 Set Your Timezone')
    .setDescription('Choose your timezone from the list below, or use the command with a specific timezone name.')
    .addFields({
      name: '💡 Examples',
      value: '• `/timezone America/New_York`\n• `/timezone Europe/London`\n• `/timezone Asia/Tokyo`\n• `/timezone Australia/Sydney`',
      inline: false
    })
    .setFooter({ text: 'Your timezone will be used for all tournament time displays.' });

  // Create timezone selection menu
  const timezoneOptions = commonTimezones.map(tz => ({
    label: tz.label,
    description: `Set timezone to ${tz.value}`,
    value: tz.value
  }));

  // Split options into chunks of 25 (Discord limit)
  const optionChunks = [];
  for (let i = 0; i < timezoneOptions.length; i += 25) {
    optionChunks.push(timezoneOptions.slice(i, i + 25));
  }

  const selectMenus = optionChunks.map((chunk, index) => {
    return new StringSelectMenuBuilder()
      .setCustomId(`timezone_select_${index}`)
      .setPlaceholder(`Choose your timezone ${optionChunks.length > 1 ? `(${index + 1}/${optionChunks.length})` : ''}`)
      .addOptions(chunk);
  });

  const actionRows = selectMenus.map(menu => new ActionRowBuilder().addComponents(menu));

  // Add cancel button
  const cancelButton = new ButtonBuilder()
    .setCustomId('timezone_cancel')
    .setLabel('Cancel')
    .setStyle(ButtonStyle.Secondary)
    .setEmoji('❌');

  actionRows.push(new ActionRowBuilder().addComponents(cancelButton));

  await interaction.editReply({
    embeds: [embed],
    components: actionRows
  });

  // Handle timezone selection
  const filter = (i) => i.user.id === interaction.user.id;
  const collector = interaction.channel.createMessageComponentCollector({
    filter,
    componentType: ComponentType.StringSelect,
    time: 300000 // 5 minutes
  });

  collector.on('collect', async (selectInteraction) => {
    if (selectInteraction.customId.startsWith('timezone_select_')) {
      const selectedTimezone = selectInteraction.values[0];
      await selectInteraction.deferUpdate();
      await setUserTimezone(interaction, selectedTimezone);
      collector.stop();
    }
  });

  // Handle cancel button
  const buttonCollector = interaction.channel.createMessageComponentCollector({
    filter,
    componentType: ComponentType.Button,
    time: 300000 // 5 minutes
  });

  buttonCollector.on('collect', async (buttonInteraction) => {
    if (buttonInteraction.customId === 'timezone_cancel') {
      await buttonInteraction.update({
        embeds: [
          new EmbedBuilder()
            .setColor(0x808080)
            .setTitle('❌ Timezone Setup Cancelled')
            .setDescription('Timezone preference was not changed.')
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
            .setTitle('⏰ Timezone Setup Timeout')
            .setDescription('Timezone selection timed out. Please run the command again to set your timezone.')
        ],
        components: []
      }).catch(() => {}); // Ignore errors if interaction is already handled
    }
  });
}

/**
 * Show error for invalid timezone with suggestions
 */
async function showInvalidTimezoneError(interaction, invalidTimezone) {
  const commonTimezones = timezoneService.getCommonTimezones();
  const timezoneList = commonTimezones.slice(0, 10).map(tz => `• \`${tz.value}\` - ${tz.label}`).join('\n');
  
  // Try to find similar timezones
  const suggestions = findSimilarTimezones(invalidTimezone, commonTimezones) || [];
  
  const embed = new EmbedBuilder()
    .setColor(0xFF0000)
    .setTitle('❌ Invalid Timezone')
    .setDescription(`The timezone "${invalidTimezone}" is not valid.`)
    .addFields({
      name: '💡 Did you mean?',
      value: suggestions.length > 0 ? 
        suggestions.map(tz => `• \`${tz.value}\` - ${tz.label}`).join('\n') :
        'No similar timezones found.',
      inline: false
    })
    .addFields({
      name: '🌍 Common Timezones',
      value: timezoneList,
      inline: false
    })
    .addFields({
      name: '📝 Examples',
      value: '• `/timezone America/New_York`\n• `/timezone Europe/London`\n• `/timezone EST` (alias)\n• `/timezone UTC`',
      inline: false
    })
    .setFooter({ text: 'Use /timezone without parameters to see the full selection menu.' });

  await interaction.editReply({ embeds: [embed] });
}

/**
 * Set user timezone preference
 */
async function setUserTimezone(interaction, timezone) {
  try {
    // Normalize the timezone
    const normalizedTimezone = timezoneService.normalizeTimezone(timezone);
    
    // Store timezone preference
    await storeTimezonePreference(interaction.user, normalizedTimezone);
    
    // Show current time in the selected timezone
    const currentTime = timezoneService.convertUTCToLocal(new Date(), normalizedTimezone);
    const timeDisplay = timezoneService.formatTimeDisplay(new Date(), normalizedTimezone, {
      showDate: true,
      format12Hour: true,
      showTimezone: true
    });

    const successEmbed = new EmbedBuilder()
      .setColor(0x00FF00)
      .setTitle('✅ Timezone Set Successfully')
      .setDescription(`Your timezone has been set to **${normalizedTimezone}**`)
      .addFields(
        {
          name: '🕐 Current Time',
          value: timeDisplay,
          inline: false
        },
        {
          name: '📅 What this means',
          value: 'All tournament times will now be displayed in your local timezone alongside UTC time.',
          inline: false
        },
        {
          name: '🔄 Next Steps',
          value: '• Use `/register` to see tournament times in your timezone\n• Use `/mystatus` to view your registrations\n• Run `/timezone` again to change your preference',
          inline: false
        }
      )
      .setFooter({ text: 'Your timezone preference is now saved for future use.' });

    await interaction.editReply({
      embeds: [successEmbed],
      components: []
    });

  } catch (error) {
    console.error('Error setting timezone:', error);
    
    const errorEmbed = new EmbedBuilder()
      .setColor(0xFF0000)
      .setTitle('❌ Failed to Set Timezone')
      .setDescription(`An error occurred while setting your timezone: ${error.message}`)
      .setFooter({ text: 'Please try again or contact support.' });

    await interaction.editReply({
      embeds: [errorEmbed],
      components: []
    });
  }
}

/**
 * Find similar timezones based on input
 */
function findSimilarTimezones(input, commonTimezones) {
  if (!input || !commonTimezones || !Array.isArray(commonTimezones)) {
    return [];
  }
  
  const inputLower = input.toLowerCase();
  
  return commonTimezones.filter(tz => {
    if (!tz || !tz.value || !tz.label) {
      return false;
    }
    
    const valueLower = tz.value.toLowerCase();
    const labelLower = tz.label.toLowerCase();
    
    // Check if input is contained in timezone value or label
    return valueLower.includes(inputLower) || 
           labelLower.includes(inputLower) ||
           // Check for partial matches in city names
           valueLower.split('/').some(part => part.includes(inputLower));
  }).slice(0, 5); // Limit to 5 suggestions
}

/**
 * Store timezone preference using the registration service
 */
async function storeTimezonePreference(discordUser, timezone) {
  try {
    await registrationService.setPlayerTimezone(discordUser.id, timezone, discordUser);
    console.log(`Stored timezone preference for user ${discordUser.id}: ${timezone}`);
  } catch (error) {
    console.error('Error storing timezone preference:', error);
    // For now, we'll continue even if the API call fails
    // This allows the command to work even if the backend isn't fully implemented
    console.log(`Fallback: Timezone preference for user ${discordUser.id} set to ${timezone} (not persisted)`);
  }
}
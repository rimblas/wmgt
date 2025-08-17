import moment from 'moment-timezone';

/**
 * Timezone service for time conversion functionality
 * Handles UTC to local time conversion, timezone validation, and time display formatting
 */
export class TimezoneService {
  constructor() {
    // Cache of valid timezone names for performance
    this.validTimezones = moment.tz.names();
    
    // Common timezone aliases for user-friendly input
    this.timezoneAliases = {
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'CST': 'America/Chicago',
      'CDT': 'America/Chicago',
      'MST': 'America/Denver',
      'MDT': 'America/Denver',
      'PST': 'America/Los_Angeles',
      'PDT': 'America/Los_Angeles',
      'GMT': 'UTC',
      'BST': 'Europe/London',
      'CET': 'Europe/Paris',
      'CEST': 'Europe/Paris',
      'JST': 'Asia/Tokyo',
      'AEST': 'Australia/Sydney',
      'AEDT': 'Australia/Sydney'
    };
  }

  /**
   * Convert UTC time to local time in specified timezone
   * @param {string|Date|moment} utcTime - UTC time to convert
   * @param {string} timezone - Target timezone (IANA timezone name or alias)
   * @returns {moment} Moment object in the target timezone
   */
  convertUTCToLocal(utcTime, timezone) {
    // Normalize timezone (handles aliases and validation)
    const normalizedTimezone = this.normalizeTimezone(timezone);

    // Handle different input types
    let utcMoment;
    if (moment.isMoment(utcTime)) {
      utcMoment = utcTime.clone().utc();
    } else if (utcTime instanceof Date) {
      utcMoment = moment.utc(utcTime);
    } else if (typeof utcTime === 'string') {
      // Handle time strings like "22:00" by assuming today's date
      if (/^\d{2}:\d{2}$/.test(utcTime)) {
        utcMoment = moment.utc(utcTime, 'HH:mm');
      } else {
        utcMoment = moment.utc(utcTime);
      }
    } else {
      throw new Error('Invalid time format. Expected string, Date, or moment object.');
    }

    return utcMoment.tz(normalizedTimezone);
  }

  /**
   * Validate if a timezone string is valid
   * @param {string} timezone - Timezone to validate
   * @returns {boolean} True if timezone is valid
   */
  validateTimezone(timezone) {
    if (!timezone || typeof timezone !== 'string') {
      return false;
    }

    // Check if it's a direct match
    if (this.validTimezones.includes(timezone)) {
      return true;
    }

    // Check if it's an alias
    if (this.timezoneAliases[timezone.toUpperCase()]) {
      return true;
    }

    return false;
  }

  /**
   * Normalize timezone input by resolving aliases
   * @param {string} timezone - Timezone input (may be alias)
   * @returns {string} Normalized IANA timezone name
   */
  normalizeTimezone(timezone) {
    if (!timezone || typeof timezone !== 'string') {
      throw new Error('Timezone must be a non-empty string');
    }

    // Check if it's an alias first (prioritize our aliases over moment's built-in ones)
    const normalized = this.timezoneAliases[timezone.toUpperCase()];
    if (normalized) {
      return normalized;
    }

    // Check if it's already a valid IANA timezone
    if (this.validTimezones.includes(timezone)) {
      return timezone;
    }

    throw new Error(`Invalid timezone: ${timezone}`);
  }

  /**
   * Format time display showing both UTC and local times
   * @param {string|Date|moment} utcTime - UTC time to display
   * @param {string} timezone - User's timezone
   * @param {Object} options - Formatting options
   * @returns {string} Formatted time string
   */
  formatTimeDisplay(utcTime, timezone, options = {}) {
    const {
      showDate = true,
      showSeconds = false,
      format12Hour = true,
      showTimezone = true
    } = options;

    try {
      const normalizedTimezone = this.normalizeTimezone(timezone);
      const localTime = this.convertUTCToLocal(utcTime, normalizedTimezone);
      const utcMoment = moment.isMoment(utcTime) ? utcTime.clone().utc() : moment.utc(utcTime);

      // Build format strings
      let timeFormat = format12Hour ? 'h:mm' : 'HH:mm';
      if (showSeconds) {
        timeFormat += ':ss';
      }
      if (format12Hour) {
        timeFormat += ' A';
      }

      let dateFormat = showDate ? 'MMM D, YYYY ' : '';
      let fullFormat = dateFormat + timeFormat;

      // Format UTC time
      let utcDisplay = utcMoment.format(fullFormat);
      if (showTimezone) {
        utcDisplay += ' UTC';
      }

      // Format local time
      let localDisplay = localTime.format(fullFormat);
      if (showTimezone) {
        localDisplay += ` ${localTime.format('z')}`;
      }

      // Check if date changes between UTC and local time
      const utcDate = utcMoment.format('YYYY-MM-DD');
      const localDate = localTime.format('YYYY-MM-DD');
      const dateChanged = utcDate !== localDate;

      if (dateChanged && showDate) {
        return `${utcDisplay} (${localDisplay})`;
      } else {
        return `${utcDisplay} (${localDisplay})`;
      }
    } catch (error) {
      throw new Error(`Failed to format time display: ${error.message}`);
    }
  }

  /**
   * Get a list of common timezones for user selection
   * @returns {Array} Array of timezone objects with display names
   */
  getCommonTimezones() {
    return [
      { value: 'UTC', label: 'UTC (Coordinated Universal Time)' },
      { value: 'America/New_York', label: 'Eastern Time (US & Canada)' },
      { value: 'America/Chicago', label: 'Central Time (US & Canada)' },
      { value: 'America/Denver', label: 'Mountain Time (US & Canada)' },
      { value: 'America/Los_Angeles', label: 'Pacific Time (US & Canada)' },
      { value: 'Europe/London', label: 'London (GMT/BST)' },
      { value: 'Europe/Paris', label: 'Central European Time' },
      { value: 'Europe/Berlin', label: 'Berlin (CET/CEST)' },
      { value: 'Asia/Tokyo', label: 'Japan Standard Time' },
      { value: 'Asia/Shanghai', label: 'China Standard Time' },
      { value: 'Australia/Sydney', label: 'Australian Eastern Time' },
      { value: 'Australia/Melbourne', label: 'Australian Eastern Time (Melbourne)' },
      { value: 'Australia/Perth', label: 'Australian Western Time' },
      { value: 'Pacific/Auckland', label: 'New Zealand Standard Time' }
    ];
  }

  /**
   * Format tournament time slots with timezone conversion
   * @param {Array} timeSlots - Array of time slot strings (e.g., ["22:00", "00:00"])
   * @param {string} sessionDate - Session date in ISO format
   * @param {string} userTimezone - User's timezone
   * @returns {Array} Array of formatted time slot objects
   */
  formatTournamentTimeSlots(timeSlots, sessionDate, userTimezone) {
    if (!Array.isArray(timeSlots)) {
      throw new Error('Time slots must be an array');
    }

    const normalizedTimezone = this.normalizeTimezone(userTimezone);
    const sessionMoment = moment.utc(sessionDate);

    return timeSlots.map(timeSlot => {
      // Create UTC moment for this time slot on the session date
      const utcTime = sessionMoment.clone().set({
        hour: parseInt(timeSlot.split(':')[0]),
        minute: parseInt(timeSlot.split(':')[1]),
        second: 0,
        millisecond: 0
      });

      const localTime = utcTime.clone().tz(normalizedTimezone);

      return {
        value: timeSlot,
        utcTime: utcTime.format('HH:mm'),
        utcDate: utcTime.format('MMM D'),
        localTime: localTime.format('h:mm A'),
        localDate: localTime.format('MMM D'),
        localTimezone: localTime.format('z'),
        dateChanged: utcTime.format('YYYY-MM-DD') !== localTime.format('YYYY-MM-DD'),
        display: this.formatTimeDisplay(utcTime, normalizedTimezone, { 
          showDate: true, 
          format12Hour: true, 
          showTimezone: true 
        })
      };
    });
  }

  /**
   * Get user's preferred timezone or fallback to UTC
   * @param {RegistrationService} registrationService - Service to fetch user preferences
   * @param {string} discordId - Discord user ID
   * @param {string} fallbackTimezone - Fallback timezone if none is set (default: UTC)
   * @returns {Promise<string>} User's timezone preference or fallback
   */
  async getUserTimezone(registrationService, discordId, fallbackTimezone = 'UTC') {
    try {
      const userTimezone = await registrationService.getPlayerTimezone(discordId);
      
      if (userTimezone && this.validateTimezone(userTimezone)) {
        return userTimezone;
      }
      
      return fallbackTimezone;
    } catch (error) {
      console.error('Error fetching user timezone:', error);
      return fallbackTimezone;
    }
  }

  /**
   * Suggest timezone based on partial input
   * @param {string} input - Partial timezone input
   * @param {number} maxSuggestions - Maximum number of suggestions (default: 5)
   * @returns {Array} Array of suggested timezone objects
   */
  suggestTimezones(input, maxSuggestions = 5) {
    if (!input || typeof input !== 'string') {
      return this.getCommonTimezones().slice(0, maxSuggestions);
    }

    const inputLower = input.toLowerCase();
    const commonTimezones = this.getCommonTimezones();
    
    // First, check for exact matches in aliases
    const aliasMatch = this.timezoneAliases[input.toUpperCase()];
    if (aliasMatch) {
      const matchingCommon = commonTimezones.find(tz => tz.value === aliasMatch);
      if (matchingCommon) {
        return [matchingCommon];
      }
    }

    // Then find partial matches
    const matches = commonTimezones.filter(tz => {
      const valueLower = tz.value.toLowerCase();
      const labelLower = tz.label.toLowerCase();
      
      return valueLower.includes(inputLower) || 
             labelLower.includes(inputLower) ||
             valueLower.split('/').some(part => part.includes(inputLower));
    });

    return matches.slice(0, maxSuggestions);
  }
}
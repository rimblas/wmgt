import { describe, it, expect, beforeEach } from 'vitest';
import moment from 'moment-timezone';
import { TimezoneService } from '../services/TimezoneService.js';

describe('TimezoneService', () => {
  let timezoneService;

  beforeEach(() => {
    timezoneService = new TimezoneService();
  });

  describe('constructor', () => {
    it('should initialize with valid timezones and aliases', () => {
      expect(timezoneService.validTimezones).toBeDefined();
      expect(timezoneService.validTimezones.length).toBeGreaterThan(0);
      expect(timezoneService.timezoneAliases).toBeDefined();
      expect(timezoneService.timezoneAliases.EST).toBe('America/New_York');
    });
  });

  describe('validateTimezone', () => {
    it('should validate IANA timezone names', () => {
      expect(timezoneService.validateTimezone('America/New_York')).toBe(true);
      expect(timezoneService.validateTimezone('Europe/London')).toBe(true);
      expect(timezoneService.validateTimezone('Asia/Tokyo')).toBe(true);
      expect(timezoneService.validateTimezone('Australia/Sydney')).toBe(true);
    });

    it('should validate timezone aliases', () => {
      expect(timezoneService.validateTimezone('EST')).toBe(true);
      expect(timezoneService.validateTimezone('PST')).toBe(true);
      expect(timezoneService.validateTimezone('GMT')).toBe(true);
      expect(timezoneService.validateTimezone('JST')).toBe(true);
    });

    it('should reject invalid timezones', () => {
      expect(timezoneService.validateTimezone('Invalid/Timezone')).toBe(false);
      expect(timezoneService.validateTimezone('XYZ')).toBe(false);
      expect(timezoneService.validateTimezone('')).toBe(false);
      expect(timezoneService.validateTimezone(null)).toBe(false);
      expect(timezoneService.validateTimezone(undefined)).toBe(false);
    });

    it('should handle case-insensitive aliases', () => {
      expect(timezoneService.validateTimezone('est')).toBe(true);
      expect(timezoneService.validateTimezone('pst')).toBe(true);
      expect(timezoneService.validateTimezone('gmt')).toBe(true);
    });
  });

  describe('normalizeTimezone', () => {
    it('should return IANA timezone names unchanged', () => {
      expect(timezoneService.normalizeTimezone('America/New_York')).toBe('America/New_York');
      expect(timezoneService.normalizeTimezone('Europe/London')).toBe('Europe/London');
    });

    it('should convert aliases to IANA names', () => {
      expect(timezoneService.normalizeTimezone('EST')).toBe('America/New_York');
      expect(timezoneService.normalizeTimezone('PST')).toBe('America/Los_Angeles');
      expect(timezoneService.normalizeTimezone('GMT')).toBe('UTC');
    });

    it('should handle case-insensitive aliases', () => {
      expect(timezoneService.normalizeTimezone('est')).toBe('America/New_York');
      expect(timezoneService.normalizeTimezone('pst')).toBe('America/Los_Angeles');
    });

    it('should throw error for invalid timezones', () => {
      expect(() => timezoneService.normalizeTimezone('Invalid/Timezone')).toThrow();
      expect(() => timezoneService.normalizeTimezone('')).toThrow();
      expect(() => timezoneService.normalizeTimezone(null)).toThrow();
    });
  });

  describe('convertUTCToLocal', () => {
    it('should convert UTC time string to local time', () => {
      const utcTime = '22:00';
      const result = timezoneService.convertUTCToLocal(utcTime, 'America/New_York');
      
      expect(moment.isMoment(result)).toBe(true);
      expect(result.tz()).toBe('America/New_York');
    });

    it('should convert UTC Date object to local time', () => {
      const utcDate = new Date('2024-08-17T22:00:00Z');
      const result = timezoneService.convertUTCToLocal(utcDate, 'Europe/London');
      
      expect(moment.isMoment(result)).toBe(true);
      expect(result.tz()).toBe('Europe/London');
    });

    it('should convert moment object to local time', () => {
      const utcMoment = moment.utc('2024-08-17T22:00:00Z');
      const result = timezoneService.convertUTCToLocal(utcMoment, 'Asia/Tokyo');
      
      expect(moment.isMoment(result)).toBe(true);
      expect(result.tz()).toBe('Asia/Tokyo');
    });

    it('should handle timezone aliases', () => {
      const utcTime = '22:00';
      const result = timezoneService.convertUTCToLocal(utcTime, 'EST');
      
      // The result should be in the normalized timezone
      expect(result.tz()).toBe('America/New_York');
    });

    it('should throw error for invalid timezone', () => {
      expect(() => {
        timezoneService.convertUTCToLocal('22:00', 'Invalid/Timezone');
      }).toThrow('Invalid timezone: Invalid/Timezone');
    });

    it('should throw error for invalid time format', () => {
      expect(() => {
        timezoneService.convertUTCToLocal(123, 'America/New_York');
      }).toThrow('Invalid time format');
    });
  });

  describe('formatTimeDisplay', () => {
    it('should format time with both UTC and local time', () => {
      const utcTime = moment.utc('2024-08-17T22:00:00Z');
      const result = timezoneService.formatTimeDisplay(utcTime, 'America/New_York');
      
      expect(result).toContain('UTC');
      expect(result).toContain('EDT'); // Eastern Daylight Time in August
      expect(result).toContain('Aug 17, 2024');
    });

    it('should handle 12-hour format', () => {
      const utcTime = moment.utc('2024-08-17T14:00:00Z');
      const result = timezoneService.formatTimeDisplay(utcTime, 'America/New_York', { format12Hour: true });
      
      expect(result).toContain('PM');
    });

    it('should handle 24-hour format', () => {
      const utcTime = moment.utc('2024-08-17T14:00:00Z');
      const result = timezoneService.formatTimeDisplay(utcTime, 'America/New_York', { format12Hour: false });
      
      expect(result).not.toContain('PM');
      expect(result).not.toContain('AM');
    });

    it('should show seconds when requested', () => {
      const utcTime = moment.utc('2024-08-17T14:30:45Z');
      const result = timezoneService.formatTimeDisplay(utcTime, 'America/New_York', { showSeconds: true });
      
      expect(result).toContain(':45');
    });

    it('should hide date when requested', () => {
      const utcTime = moment.utc('2024-08-17T14:00:00Z');
      const result = timezoneService.formatTimeDisplay(utcTime, 'America/New_York', { showDate: false });
      
      expect(result).not.toContain('Aug 17, 2024');
    });

    it('should handle date changes across timezones', () => {
      // 2 AM UTC on Aug 18 = 10 PM EDT on Aug 17
      const utcTime = moment.utc('2024-08-18T02:00:00Z');
      const result = timezoneService.formatTimeDisplay(utcTime, 'America/New_York');
      
      expect(result).toContain('Aug 18'); // UTC date
      expect(result).toContain('Aug 17'); // Local date
    });
  });

  describe('getCommonTimezones', () => {
    it('should return array of timezone objects', () => {
      const timezones = timezoneService.getCommonTimezones();
      
      expect(Array.isArray(timezones)).toBe(true);
      expect(timezones.length).toBeGreaterThan(0);
      
      timezones.forEach(tz => {
        expect(tz).toHaveProperty('value');
        expect(tz).toHaveProperty('label');
        expect(typeof tz.value).toBe('string');
        expect(typeof tz.label).toBe('string');
      });
    });

    it('should include major timezones', () => {
      const timezones = timezoneService.getCommonTimezones();
      const values = timezones.map(tz => tz.value);
      
      expect(values).toContain('UTC');
      expect(values).toContain('America/New_York');
      expect(values).toContain('America/Los_Angeles');
      expect(values).toContain('Europe/London');
      expect(values).toContain('Asia/Tokyo');
      expect(values).toContain('Australia/Sydney');
    });
  });

  describe('formatTournamentTimeSlots', () => {
    const sessionDate = '2024-08-17T00:00:00Z';
    const timeSlots = ['22:00', '00:00', '02:00', '16:00'];

    it('should format time slots with timezone conversion', () => {
      const result = timezoneService.formatTournamentTimeSlots(timeSlots, sessionDate, 'America/New_York');
      
      expect(Array.isArray(result)).toBe(true);
      expect(result.length).toBe(timeSlots.length);
      
      result.forEach(slot => {
        expect(slot).toHaveProperty('value');
        expect(slot).toHaveProperty('utcTime');
        expect(slot).toHaveProperty('localTime');
        expect(slot).toHaveProperty('display');
        expect(slot).toHaveProperty('dateChanged');
      });
    });

    it('should detect date changes correctly', () => {
      const result = timezoneService.formatTournamentTimeSlots(['22:00'], sessionDate, 'America/New_York');
      
      // 22:00 UTC on Aug 17 = 18:00 EDT on Aug 17 (no date change)
      expect(result[0].dateChanged).toBe(false);
    });

    it('should detect date changes for early UTC times', () => {
      const result = timezoneService.formatTournamentTimeSlots(['02:00'], sessionDate, 'America/New_York');
      
      // 02:00 UTC on Aug 17 = 22:00 EDT on Aug 16 (date change)
      expect(result[0].dateChanged).toBe(true);
    });

    it('should handle Australian timezone with date changes', () => {
      const result = timezoneService.formatTournamentTimeSlots(['16:00'], sessionDate, 'Australia/Sydney');
      
      // 16:00 UTC on Aug 17 = 02:00 AEST on Aug 18 (date change forward)
      expect(result[0].dateChanged).toBe(true);
    });

    it('should throw error for invalid input', () => {
      expect(() => {
        timezoneService.formatTournamentTimeSlots('not-array', sessionDate, 'UTC');
      }).toThrow('Time slots must be an array');
    });

    it('should handle timezone aliases', () => {
      const result = timezoneService.formatTournamentTimeSlots(timeSlots, sessionDate, 'EST');
      
      expect(result.length).toBe(timeSlots.length);
      result.forEach(slot => {
        expect(slot.localTimezone).toMatch(/EDT|EST/);
      });
    });
  });

  describe('timezone conversion accuracy', () => {
    const testCases = [
      {
        name: 'US Eastern Time (New York)',
        timezone: 'America/New_York',
        utcTime: '2024-08-17T22:00:00Z', // Summer (EDT)
        expectedHour: 18 // UTC-4 in summer
      },
      {
        name: 'US Pacific Time (Los Angeles)',
        timezone: 'America/Los_Angeles',
        utcTime: '2024-08-17T22:00:00Z', // Summer (PDT)
        expectedHour: 15 // UTC-7 in summer
      },
      {
        name: 'UK Time (London)',
        timezone: 'Europe/London',
        utcTime: '2024-08-17T22:00:00Z', // Summer (BST)
        expectedHour: 23 // UTC+1 in summer
      },
      {
        name: 'Japan Time (Tokyo)',
        timezone: 'Asia/Tokyo',
        utcTime: '2024-08-17T22:00:00Z',
        expectedHour: 7 // UTC+9, next day
      },
      {
        name: 'Australian Eastern Time (Sydney)',
        timezone: 'Australia/Sydney',
        utcTime: '2024-08-17T22:00:00Z', // Winter (AEST)
        expectedHour: 8 // UTC+10, next day
      },
      {
        name: 'Central European Time (Paris)',
        timezone: 'Europe/Paris',
        utcTime: '2024-08-17T22:00:00Z', // Summer (CEST)
        expectedHour: 0 // UTC+2 in summer, next day
      }
    ];

    testCases.forEach(({ name, timezone, utcTime, expectedHour }) => {
      it(`should correctly convert ${name}`, () => {
        const result = timezoneService.convertUTCToLocal(utcTime, timezone);
        expect(result.hour()).toBe(expectedHour);
      });
    });
  });

  describe('edge cases and error handling', () => {
    it('should handle leap year dates', () => {
      const leapYearDate = '2024-02-29T12:00:00Z';
      const result = timezoneService.convertUTCToLocal(leapYearDate, 'America/New_York');
      expect(result.isValid()).toBe(true);
    });

    it('should handle daylight saving time transitions', () => {
      // Spring forward: 2024-03-10 02:00 EST becomes 03:00 EDT
      const springForward = '2024-03-10T07:00:00Z'; // 2 AM EST
      const result = timezoneService.convertUTCToLocal(springForward, 'America/New_York');
      expect(result.isValid()).toBe(true);
    });

    it('should handle year boundaries', () => {
      const newYearEve = '2023-12-31T23:59:59Z';
      const result = timezoneService.convertUTCToLocal(newYearEve, 'Pacific/Auckland');
      expect(result.year()).toBe(2024); // Should be New Year's Day in Auckland
    });

    it('should handle invalid moment objects gracefully', () => {
      const invalidMoment = moment('invalid-date');
      expect(() => {
        timezoneService.convertUTCToLocal(invalidMoment, 'UTC');
      }).not.toThrow();
    });
  });
});
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { TimezoneService } from '../services/TimezoneService.js';
import { RegistrationService } from '../services/RegistrationService.js';

describe('Timezone Integration Tests', () => {
  let timezoneService;
  let registrationService;

  beforeEach(() => {
    timezoneService = new TimezoneService();
    registrationService = new RegistrationService();
  });

  describe('Timezone Command Integration', () => {
    it('should validate and normalize common timezones', () => {
      const testTimezones = [
        'UTC',
        'America/New_York',
        'Europe/London',
        'Asia/Tokyo',
        'Australia/Sydney',
        'EST', // alias
        'PST', // alias
        'GMT'  // alias
      ];

      testTimezones.forEach(tz => {
        expect(timezoneService.validateTimezone(tz)).toBe(true);
        expect(() => timezoneService.normalizeTimezone(tz)).not.toThrow();
      });
    });

    it('should reject invalid timezones', () => {
      const invalidTimezones = [
        'Invalid/Timezone',
        'NotReal/City',
        'BadFormat',
        '',
        null,
        undefined
      ];

      invalidTimezones.forEach(tz => {
        expect(timezoneService.validateTimezone(tz)).toBe(false);
      });
    });

    it('should provide timezone suggestions', () => {
      const suggestions = timezoneService.suggestTimezones('new');
      expect(Array.isArray(suggestions)).toBe(true);
      expect(suggestions.length).toBeGreaterThan(0);
      
      // Should find New York
      const newYorkSuggestion = suggestions.find(s => s.value.includes('New_York'));
      expect(newYorkSuggestion).toBeDefined();
    });

    it('should format tournament time slots correctly', () => {
      const timeSlots = ['22:00', '00:00', '02:00'];
      const sessionDate = '2024-08-17T00:00:00Z';
      const userTimezone = 'America/New_York';

      const formatted = timezoneService.formatTournamentTimeSlots(
        timeSlots,
        sessionDate,
        userTimezone
      );

      expect(formatted).toHaveLength(3);
      formatted.forEach(slot => {
        expect(slot).toHaveProperty('value');
        expect(slot).toHaveProperty('utcTime');
        expect(slot).toHaveProperty('localTime');
        expect(slot).toHaveProperty('localTimezone');
        expect(slot).toHaveProperty('dateChanged');
      });
    });

    it('should handle timezone preference retrieval gracefully', async () => {
      // Mock the API call to return null (no preference set)
      vi.spyOn(registrationService, 'getPlayerRegistrations').mockResolvedValue({
        player: null,
        registrations: []
      });

      const userTimezone = await timezoneService.getUserTimezone(
        registrationService,
        'test-user-id',
        'UTC'
      );

      expect(userTimezone).toBe('UTC'); // Should return fallback
    });

    it('should handle timezone preference with stored value', async () => {
      // Mock the API call to return a stored timezone
      vi.spyOn(registrationService, 'getPlayerRegistrations').mockResolvedValue({
        player: {
          id: 123,
          name: 'Test User',
          timezone: 'America/New_York'
        },
        registrations: []
      });

      const userTimezone = await timezoneService.getUserTimezone(
        registrationService,
        'test-user-id',
        'UTC'
      );

      expect(userTimezone).toBe('America/New_York');
    });

    it('should handle API errors gracefully when fetching timezone', async () => {
      // Mock the API call to throw an error
      vi.spyOn(registrationService, 'getPlayerRegistrations').mockRejectedValue(
        new Error('API Error')
      );

      const userTimezone = await timezoneService.getUserTimezone(
        registrationService,
        'test-user-id',
        'UTC'
      );

      expect(userTimezone).toBe('UTC'); // Should return fallback on error
    });
  });

  describe('Time Conversion Accuracy', () => {
    it('should correctly handle tournament time slots across different timezones', () => {
      const timeSlots = ['22:00', '00:00', '02:00', '08:00', '16:00'];
      const sessionDate = '2024-08-17T00:00:00Z';

      // Test multiple timezones
      const timezones = [
        'UTC',
        'America/New_York',
        'America/Los_Angeles',
        'Europe/London',
        'Asia/Tokyo',
        'Australia/Sydney'
      ];

      timezones.forEach(timezone => {
        const formatted = timezoneService.formatTournamentTimeSlots(
          timeSlots,
          sessionDate,
          timezone
        );

        expect(formatted).toHaveLength(timeSlots.length);
        
        // Verify each slot has required properties
        formatted.forEach((slot, index) => {
          expect(slot.value).toBe(timeSlots[index]);
          expect(slot.utcTime).toMatch(/^\d{2}:\d{2}$/);
          expect(slot.localTime).toMatch(/^\d{1,2}:\d{2} (AM|PM)$/);
          expect(typeof slot.dateChanged).toBe('boolean');
        });
      });
    });

    it('should detect date changes correctly for different timezones', () => {
      const timeSlots = ['22:00']; // 10 PM UTC
      const sessionDate = '2024-08-17T00:00:00Z';

      // Test timezone where 22:00 UTC becomes next day
      const sydneyFormatted = timezoneService.formatTournamentTimeSlots(
        timeSlots,
        sessionDate,
        'Australia/Sydney'
      );
      
      // In Sydney (UTC+10), 22:00 UTC on Aug 17 becomes 08:00 on Aug 18
      expect(sydneyFormatted[0].dateChanged).toBe(true);

      // Test timezone where 22:00 UTC stays same day
      const nyFormatted = timezoneService.formatTournamentTimeSlots(
        timeSlots,
        sessionDate,
        'America/New_York'
      );
      
      // In New York (UTC-4), 22:00 UTC on Aug 17 becomes 18:00 on Aug 17
      expect(nyFormatted[0].dateChanged).toBe(false);
    });
  });

  describe('Error Handling', () => {
    it('should handle invalid time slot formats gracefully', () => {
      expect(() => {
        timezoneService.formatTournamentTimeSlots(
          ['invalid-time'],
          '2024-08-17T00:00:00Z',
          'UTC'
        );
      }).not.toThrow();
    });

    it('should handle invalid session dates gracefully', () => {
      // Moment.js handles invalid dates by creating an invalid moment object
      // The function should still work but may produce unexpected results
      expect(() => {
        timezoneService.formatTournamentTimeSlots(
          ['22:00'],
          'invalid-date',
          'UTC'
        );
      }).not.toThrow();
    });

    it('should handle empty time slots array', () => {
      const result = timezoneService.formatTournamentTimeSlots(
        [],
        '2024-08-17T00:00:00Z',
        'UTC'
      );
      
      expect(result).toEqual([]);
    });
  });
});
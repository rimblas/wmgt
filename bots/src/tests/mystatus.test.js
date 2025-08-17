import { describe, it, expect, vi, beforeEach } from 'vitest';
import mystatusCommand from '../commands/mystatus.js';
import { RegistrationService } from '../services/RegistrationService.js';
import { TimezoneService } from '../services/TimezoneService.js';

// Mock the services
vi.mock('../services/RegistrationService.js');
vi.mock('../services/TimezoneService.js');

describe('MyStatus Command', () => {
  let mockInteraction;
  let mockRegistrationService;
  let mockTimezoneService;

  beforeEach(() => {
    // Reset mocks
    vi.clearAllMocks();

    // Mock interaction object
    mockInteraction = {
      user: {
        id: '123456789012345678',
        username: 'testuser',
        displayName: 'Test User',
        displayAvatarURL: vi.fn().mockReturnValue('https://example.com/avatar.png')
      },
      options: {
        getString: vi.fn()
      },
      reply: vi.fn(),
      deferReply: vi.fn().mockImplementation(() => {
        mockInteraction.deferred = true;
        return Promise.resolve();
      }),
      editReply: vi.fn(),
      deferred: false
    };

    // Mock RegistrationService
    mockRegistrationService = {
      getPlayerRegistrations: vi.fn()
    };
    RegistrationService.mockImplementation(() => mockRegistrationService);

    // Mock TimezoneService
    mockTimezoneService = {
      validateTimezone: vi.fn(),
      formatTimeDisplay: vi.fn()
    };
    TimezoneService.mockImplementation(() => mockTimezoneService);
  });

  describe('Command Structure', () => {
    it('should have correct command name and description', () => {
      expect(mystatusCommand.data.name).toBe('mystatus');
      expect(mystatusCommand.data.description).toBe('View your current tournament registrations');
    });

    it('should have optional timezone parameter', () => {
      const options = mystatusCommand.data.options;
      expect(options).toHaveLength(1);
      expect(options[0].name).toBe('timezone');
      expect(options[0].required).toBe(false);
    });
  });

  describe('Timezone Validation', () => {
    it('should reject invalid timezone', async () => {
      mockInteraction.options.getString.mockReturnValue('INVALID_TZ');
      mockTimezoneService.validateTimezone.mockReturnValue(false);

      await mystatusCommand.execute(mockInteraction);

      expect(mockInteraction.reply).toHaveBeenCalledWith({
        content: expect.stringContaining('❌ Invalid timezone: `INVALID_TZ`'),
        ephemeral: true
      });
    });

    it('should accept valid timezone', async () => {
      mockInteraction.options.getString.mockReturnValue('America/New_York');
      mockTimezoneService.validateTimezone.mockReturnValue(true);
      mockInteraction.deferReply.mockResolvedValue();
      mockRegistrationService.getPlayerRegistrations.mockResolvedValue({
        player: null,
        registrations: []
      });

      await mystatusCommand.execute(mockInteraction);

      expect(mockInteraction.deferReply).toHaveBeenCalledWith({ ephemeral: true });
      expect(mockRegistrationService.getPlayerRegistrations).toHaveBeenCalledWith('123456789012345678');
    });

    it('should default to UTC when no timezone provided', async () => {
      mockInteraction.options.getString.mockReturnValue(null);
      mockTimezoneService.validateTimezone.mockReturnValue(true);
      mockInteraction.deferReply.mockResolvedValue();
      mockRegistrationService.getPlayerRegistrations.mockResolvedValue({
        player: null,
        registrations: []
      });

      await mystatusCommand.execute(mockInteraction);

      expect(mockTimezoneService.validateTimezone).toHaveBeenCalledWith('UTC');
    });
  });

  describe('No Registrations', () => {
    it('should display message when user has no registrations', async () => {
      mockInteraction.options.getString.mockReturnValue('UTC');
      mockTimezoneService.validateTimezone.mockReturnValue(true);
      mockInteraction.deferReply.mockResolvedValue();
      mockRegistrationService.getPlayerRegistrations.mockResolvedValue({
        player: null,
        registrations: []
      });

      await mystatusCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            description: '📭 You are not currently registered for any tournaments.'
          })
        })]
      });
    });
  });

  describe('With Registrations', () => {
    it('should display registrations with timezone conversion', async () => {
      const mockRegistrations = {
        player: {
          id: 789,
          name: 'Test Player'
        },
        registrations: [
          {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            session_date: '2024-08-17T00:00:00Z',
            room_no: 5
          }
        ]
      };

      mockInteraction.options.getString.mockReturnValue('America/New_York');
      mockTimezoneService.validateTimezone.mockReturnValue(true);
      mockInteraction.deferReply.mockResolvedValue();
      mockTimezoneService.formatTimeDisplay.mockReturnValue('Aug 16, 2024 6:00 PM EDT (Aug 17, 2024 10:00 PM UTC)');
      mockRegistrationService.getPlayerRegistrations.mockResolvedValue(mockRegistrations);

      await mystatusCommand.execute(mockInteraction);

      expect(mockTimezoneService.formatTimeDisplay).toHaveBeenCalledWith(
        '2024-08-17T22:00:00.000Z',
        'America/New_York',
        { showDate: true, format12Hour: true, showTimezone: true }
      );

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            description: expect.stringContaining('Test Player'),
            fields: expect.arrayContaining([
              expect.objectContaining({
                name: '📅 S14W01',
                value: expect.stringContaining('Aug 16, 2024 6:00 PM EDT')
              })
            ])
          })
        })]
      });
    });

    it('should handle registration without room assignment', async () => {
      const mockRegistrations = {
        player: {
          id: 789,
          name: 'Test Player'
        },
        registrations: [
          {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            session_date: '2024-08-17T00:00:00Z',
            room_no: null
          }
        ]
      };

      mockInteraction.options.getString.mockReturnValue('UTC');
      mockTimezoneService.validateTimezone.mockReturnValue(true);
      mockInteraction.deferReply.mockResolvedValue();
      mockTimezoneService.formatTimeDisplay.mockReturnValue('Aug 17, 2024 10:00 PM UTC');
      mockRegistrationService.getPlayerRegistrations.mockResolvedValue(mockRegistrations);

      await mystatusCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            fields: expect.arrayContaining([
              expect.objectContaining({
                value: expect.stringContaining('*Not assigned yet*')
              })
            ])
          })
        })]
      });
    });
  });

  describe('Error Handling', () => {
    it('should handle timezone formatting error gracefully', async () => {
      const mockRegistrations = {
        player: {
          id: 789,
          name: 'Test Player'
        },
        registrations: [
          {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            session_date: '2024-08-17T00:00:00Z',
            room_no: 5
          }
        ]
      };

      mockInteraction.options.getString.mockReturnValue('UTC');
      mockTimezoneService.validateTimezone.mockReturnValue(true);
      mockInteraction.deferReply.mockResolvedValue();
      mockTimezoneService.formatTimeDisplay.mockImplementation(() => {
        throw new Error('Timezone formatting error');
      });
      mockRegistrationService.getPlayerRegistrations.mockResolvedValue(mockRegistrations);

      await mystatusCommand.execute(mockInteraction);

      // Should still display registration but with fallback format
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [expect.objectContaining({
          data: expect.objectContaining({
            fields: expect.arrayContaining([
              expect.objectContaining({
                name: '📅 S14W01',
                value: expect.stringContaining('22:00 UTC')
              })
            ])
          })
        })]
      });
    });
  });
});
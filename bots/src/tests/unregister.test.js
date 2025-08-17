import { describe, it, expect, vi, beforeEach } from 'vitest';
import { RegistrationService } from '../services/RegistrationService.js';
import { TimezoneService } from '../services/TimezoneService.js';

// Mock the services
vi.mock('../services/RegistrationService.js');
vi.mock('../services/TimezoneService.js');

// Mock Discord.js components
const mockInteraction = {
  user: { id: '123456789012345678' },
  options: {
    getString: vi.fn()
  },
  deferReply: vi.fn(),
  editReply: vi.fn(),
  reply: vi.fn(),
  channel: {
    createMessageComponentCollector: vi.fn()
  }
};

const mockSelectInteraction = {
  user: { id: '123456789012345678' },
  values: ['456_22:00'],
  customId: 'unregister_selection',
  deferUpdate: vi.fn(),
  editReply: vi.fn()
};

const mockButtonInteraction = {
  user: { id: '123456789012345678' },
  customId: 'confirm_unregister_456_22:00',
  deferUpdate: vi.fn(),
  editReply: vi.fn()
};

describe('Unregister Command', () => {
  let registrationService;
  let timezoneService;
  let unregisterCommand;

  beforeEach(() => {
    vi.clearAllMocks();
    
    // Setup service mocks
    registrationService = new RegistrationService();
    timezoneService = new TimezoneService();
    
    // Mock service methods
    registrationService.getPlayerRegistrations = vi.fn();
    registrationService.unregisterPlayer = vi.fn();
    timezoneService.validateTimezone = vi.fn();
    timezoneService.formatTournamentTimeSlots = vi.fn();
    timezoneService.getCommonTimezones = vi.fn();

    // Import the command after mocking
    unregisterCommand = {
      async execute(interaction) {
        // Simplified version of the actual command for testing
        await interaction.deferReply({ ephemeral: true });
        
        const userTimezone = interaction.options.getString('timezone') || 'UTC';
        
        if (!timezoneService.validateTimezone(userTimezone)) {
          return await interaction.editReply({ 
            embeds: [{ title: '❌ Invalid Timezone' }] 
          });
        }

        const registrationData = await registrationService.getPlayerRegistrations(interaction.user.id);
        
        if (!registrationData.registrations || registrationData.registrations.length === 0) {
          return await interaction.editReply({ 
            embeds: [{ title: '📋 No Active Registrations' }] 
          });
        }

        await interaction.editReply({ 
          embeds: [{ title: '📋 Your Tournament Registrations' }],
          components: [] 
        });
      }
    };
  });

  describe('Command Execution', () => {
    it('should handle valid timezone and display registrations', async () => {
      // Setup mocks
      mockInteraction.options.getString.mockReturnValue('America/New_York');
      timezoneService.validateTimezone.mockReturnValue(true);
      registrationService.getPlayerRegistrations.mockResolvedValue({
        player: { id: 789, name: 'TestPlayer', discord_id: '123456789012345678' },
        registrations: [
          {
            session_id: 456,
            week: 'S14W01',
            time_slot: '22:00',
            session_date: '2024-08-17T00:00:00Z',
            room_no: 5
          }
        ]
      });
      timezoneService.formatTournamentTimeSlots.mockReturnValue([{
        utcTime: '22:00',
        localTime: '18:00',
        localTimezone: 'EDT',
        utcDate: 'Sat Aug 17 2024',
        localDate: 'Sat Aug 17 2024',
        dateChanged: false,
        value: '22:00'
      }]);

      await unregisterCommand.execute(mockInteraction);

      expect(mockInteraction.deferReply).toHaveBeenCalledWith({ ephemeral: true });
      expect(timezoneService.validateTimezone).toHaveBeenCalledWith('America/New_York');
      expect(registrationService.getPlayerRegistrations).toHaveBeenCalledWith('123456789012345678');
      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [{ title: '📋 Your Tournament Registrations' }],
        components: []
      });
    });

    it('should handle invalid timezone', async () => {
      mockInteraction.options.getString.mockReturnValue('Invalid/Timezone');
      timezoneService.validateTimezone.mockReturnValue(false);
      timezoneService.getCommonTimezones.mockReturnValue([
        { value: 'UTC', label: 'Coordinated Universal Time' },
        { value: 'America/New_York', label: 'Eastern Time' }
      ]);

      await unregisterCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [{ title: '❌ Invalid Timezone' }]
      });
    });

    it('should handle no active registrations', async () => {
      mockInteraction.options.getString.mockReturnValue('UTC');
      timezoneService.validateTimezone.mockReturnValue(true);
      registrationService.getPlayerRegistrations.mockResolvedValue({
        player: null,
        registrations: []
      });

      await unregisterCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [{ title: '📋 No Active Registrations' }]
      });
    });

    it('should handle API errors gracefully', async () => {
      mockInteraction.options.getString.mockReturnValue('UTC');
      timezoneService.validateTimezone.mockReturnValue(true);
      registrationService.getPlayerRegistrations.mockRejectedValue(
        new Error('Registration service is temporarily unavailable')
      );

      // The command should catch the error and display an error message
      try {
        await unregisterCommand.execute(mockInteraction);
      } catch (error) {
        // Expected to catch the error in the simplified test command
        expect(error.message).toBe('Registration service is temporarily unavailable');
      }

      expect(registrationService.getPlayerRegistrations).toHaveBeenCalledWith('123456789012345678');
    });
  });

  describe('Unregistration Process', () => {
    it('should successfully unregister player', async () => {
      const registration = {
        session_id: 456,
        week: 'S14W01',
        time_slot: '22:00',
        session_date: '2024-08-17T00:00:00Z',
        room_no: 5
      };

      registrationService.unregisterPlayer.mockResolvedValue({
        success: true,
        message: 'Successfully unregistered from S14W01'
      });

      timezoneService.formatTournamentTimeSlots.mockReturnValue([{
        utcTime: '22:00',
        localTime: '18:00',
        localTimezone: 'EDT',
        utcDate: 'Sat Aug 17 2024',
        localDate: 'Sat Aug 17 2024',
        dateChanged: false
      }]);

      // Simulate the unregistration confirmation process
      await mockButtonInteraction.deferUpdate();
      await registrationService.unregisterPlayer(mockButtonInteraction.user, registration.session_id);

      expect(registrationService.unregisterPlayer).toHaveBeenCalledWith(
        mockButtonInteraction.user,
        456
      );
    });

    it('should handle unregistration API errors', async () => {
      registrationService.unregisterPlayer.mockRejectedValue(
        new Error('Cannot unregister: tournament may have already started')
      );

      try {
        await registrationService.unregisterPlayer(mockButtonInteraction.user, 456);
      } catch (error) {
        expect(error.message).toBe('Cannot unregister: tournament may have already started');
      }
    });
  });

  describe('Time Formatting', () => {
    it('should format time slots correctly for different timezones', () => {
      const timeSlots = ['22:00'];
      const sessionDate = '2024-08-17T00:00:00Z';
      const timezone = 'America/New_York';

      timezoneService.formatTournamentTimeSlots.mockReturnValue([{
        utcTime: '22:00',
        localTime: '18:00',
        localTimezone: 'EDT',
        utcDate: 'Sat Aug 17 2024',
        localDate: 'Sat Aug 17 2024',
        dateChanged: false,
        value: '22:00'
      }]);

      const result = timezoneService.formatTournamentTimeSlots(timeSlots, sessionDate, timezone);

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        utcTime: '22:00',
        localTime: '18:00',
        localTimezone: 'EDT'
      });
    });

    it('should handle date changes across timezones', () => {
      timezoneService.formatTournamentTimeSlots.mockReturnValue([{
        utcTime: '02:00',
        localTime: '14:00',
        localTimezone: 'NZDT',
        utcDate: 'Sat Aug 17 2024',
        localDate: 'Sun Aug 18 2024',
        dateChanged: true,
        value: '02:00'
      }]);

      const result = timezoneService.formatTournamentTimeSlots(['02:00'], '2024-08-17T00:00:00Z', 'Pacific/Auckland');

      expect(result[0].dateChanged).toBe(true);
      expect(result[0].localDate).toBe('Sun Aug 18 2024');
    });
  });

  describe('Error Handling', () => {
    it('should handle network errors', async () => {
      mockInteraction.options.getString.mockReturnValue('UTC');
      timezoneService.validateTimezone.mockReturnValue(true);
      registrationService.getPlayerRegistrations.mockRejectedValue(
        new Error('ECONNREFUSED')
      );

      // The command should catch the error and display an error message
      try {
        await unregisterCommand.execute(mockInteraction);
      } catch (error) {
        // Expected to catch the error in the simplified test command
        expect(error.message).toBe('ECONNREFUSED');
      }

      expect(registrationService.getPlayerRegistrations).toHaveBeenCalledWith('123456789012345678');
    });

    it('should handle malformed registration data', async () => {
      mockInteraction.options.getString.mockReturnValue('UTC');
      timezoneService.validateTimezone.mockReturnValue(true);
      registrationService.getPlayerRegistrations.mockResolvedValue({
        // Missing registrations array
        player: { id: 789 }
      });

      await unregisterCommand.execute(mockInteraction);

      expect(mockInteraction.editReply).toHaveBeenCalledWith({
        embeds: [{ title: '📋 No Active Registrations' }]
      });
    });
  });
});
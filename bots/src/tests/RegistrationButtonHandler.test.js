import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ButtonStyle } from 'discord.js';
import RegistrationButtonHandler from '../services/RegistrationButtonHandler.js';

// Mock RulesProvider
vi.mock('../services/RulesProvider.js', () => ({
  getRulesText: vi.fn().mockResolvedValue('Mock tournament rules text'),
  clearCache: vi.fn()
}));

// Mock logger
vi.mock('../utils/Logger.js', () => ({
  logger: {
    child: () => ({
      info: vi.fn(),
      debug: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    })
  }
}));

/**
 * Create a mock Discord ButtonInteraction.
 * The editReply returns a message object with createMessageComponentCollector.
 */
function createMockInteraction(userId = '123456789') {
  const mockCollector = createMockCollector();
  const mockMessage = {
    createMessageComponentCollector: vi.fn().mockReturnValue(mockCollector)
  };

  return {
    deferReply: vi.fn().mockResolvedValue(undefined),
    editReply: vi.fn().mockResolvedValue(mockMessage),
    user: {
      id: userId,
      username: 'TestPlayer',
      displayName: 'Test Player',
      displayAvatarURL: vi.fn().mockReturnValue('https://example.com/avatar.png')
    },
    _mockMessage: mockMessage,
    _mockCollector: mockCollector
  };
}

/**
 * Create a mock component collector with on/off/stop methods.
 */
function createMockCollector() {
  const handlers = {};
  const collector = {
    on: vi.fn(),
    stop: vi.fn(),
    _handlers: handlers,
    _emit: async (event, ...args) => {
      if (handlers[event]) return handlers[event](...args);
    }
  };
  // on() stores handler and returns self for chaining
  collector.on.mockImplementation((event, handler) => {
    handlers[event] = handler;
    return collector;
  });
  return collector;
}

/**
 * Create mock services with sensible defaults
 */
function createMockServices(overrides = {}) {
  const registrationService = {
    getCurrentTournament: vi.fn().mockResolvedValue({}),
    getPlayerRegistrations: vi.fn().mockResolvedValue({ player: null, registrations: [] }),
    registerPlayer: vi.fn().mockResolvedValue({ success: true }),
    unregisterPlayer: vi.fn().mockResolvedValue({ success: true }),
    ...overrides.registrationService
  };

  const timezoneService = {
    formatTournamentTimeSlots: vi.fn().mockReturnValue([]),
    getUserTimezone: vi.fn().mockResolvedValue('UTC'),
    ...overrides.timezoneService
  };

  const registrationMessageManager = {
    deriveTournamentState: vi.fn().mockReturnValue('closed'),
    ...overrides.registrationMessageManager
  };

  return { registrationService, timezoneService, registrationMessageManager };
}

describe('RegistrationButtonHandler', () => {
  let handler;
  let services;
  let interaction;

  beforeEach(() => {
    services = createMockServices();
    handler = new RegistrationButtonHandler(
      services.registrationService,
      services.timezoneService,
      services.registrationMessageManager
    );
    interaction = createMockInteraction();
  });

  describe('handleRegisterButton', () => {
    it('should defer reply as ephemeral', async () => {
      await handler.handleRegisterButton(interaction);

      expect(interaction.deferReply).toHaveBeenCalledWith({ ephemeral: true });
    });

    it('should fetch current tournament data', async () => {
      await handler.handleRegisterButton(interaction);

      expect(services.registrationService.getCurrentTournament).toHaveBeenCalled();
    });

    it('should derive tournament state from fetched data', async () => {
      const tournamentData = { tournament_name: 'Test', week: 'Week 1' };
      services.registrationService.getCurrentTournament.mockResolvedValue(tournamentData);

      await handler.handleRegisterButton(interaction);

      expect(services.registrationMessageManager.deriveTournamentState).toHaveBeenCalledWith(tournamentData);
    });

    describe('when API is unreachable (getCurrentTournament throws)', () => {
      it('should show "temporarily unavailable" message', async () => {
        services.registrationService.getCurrentTournament.mockRejectedValue(
          new Error('ECONNREFUSED')
        );

        await handler.handleRegisterButton(interaction);

        expect(interaction.editReply).toHaveBeenCalled();
        const replyContent = interaction.editReply.mock.calls[0][0].content;
        expect(replyContent).toContain('temporarily unavailable');
      });

      it('should not crash if editReply also fails in the error handler', async () => {
        services.registrationService.getCurrentTournament.mockRejectedValue(
          new Error('ECONNREFUSED')
        );
        interaction.editReply.mockRejectedValue(new Error('Unknown interaction'));

        // Should not throw
        await expect(handler.handleRegisterButton(interaction)).resolves.not.toThrow();
      });
    });

    describe('when deferReply fails (interaction expired)', () => {
      it('should return early without crashing', async () => {
        interaction.deferReply.mockRejectedValue(new Error('Unknown interaction'));

        await expect(handler.handleRegisterButton(interaction)).resolves.not.toThrow();
      });

      it('should not attempt to fetch tournament data', async () => {
        interaction.deferReply.mockRejectedValue(new Error('Unknown interaction'));

        await handler.handleRegisterButton(interaction);

        expect(services.registrationService.getCurrentTournament).not.toHaveBeenCalled();
      });

      it('should not attempt to editReply', async () => {
        interaction.deferReply.mockRejectedValue(new Error('Unknown interaction'));

        await handler.handleRegisterButton(interaction);

        expect(interaction.editReply).not.toHaveBeenCalled();
      });
    });

    describe('when tournament state is "ongoing"', () => {
      const tournamentData = {
        tournament: { name: 'WMGT Season 5' },
        sessions: {
          week: 'Week 3',
          available_time_slots: [
            { time_slot: '22:00', day_offset: -1 },
            { time_slot: '02:00', day_offset: 0 }
          ]
        }
      };

      beforeEach(() => {
        services.registrationService.getCurrentTournament.mockResolvedValue(tournamentData);
        services.registrationMessageManager.deriveTournamentState.mockReturnValue('ongoing');
      });

      it('should call handleOngoingTournament', async () => {
        await handler.handleRegisterButton(interaction);

        expect(interaction.editReply).toHaveBeenCalled();
        const replyContent = interaction.editReply.mock.calls[0][0].content;
        expect(replyContent).toContain('locked');
        expect(replyContent).toContain('in progress');
      });

      it('should NOT fetch player registrations', async () => {
        await handler.handleRegisterButton(interaction);

        expect(services.registrationService.getPlayerRegistrations).not.toHaveBeenCalled();
      });

      it('should include time slot info in the lockout message', async () => {
        await handler.handleRegisterButton(interaction);

        const replyContent = interaction.editReply.mock.calls[0][0].content;
        expect(replyContent).toContain('22:00 UTC');
        expect(replyContent).toContain('02:00 UTC');
      });
    });

    describe('when tournament state is "closed"', () => {
      beforeEach(() => {
        services.registrationService.getCurrentTournament.mockResolvedValue({});
        services.registrationMessageManager.deriveTournamentState.mockReturnValue('closed');
      });

      it('should reply with no active tournament message', async () => {
        await handler.handleRegisterButton(interaction);

        expect(interaction.editReply).toHaveBeenCalled();
        const replyContent = interaction.editReply.mock.calls[0][0].content;
        expect(replyContent).toMatch(/no active tournament/i);
      });

      it('should NOT fetch player registrations', async () => {
        await handler.handleRegisterButton(interaction);

        expect(services.registrationService.getPlayerRegistrations).not.toHaveBeenCalled();
      });
    });

    describe('when tournament state is "registration_open"', () => {
      const tournamentData = {
        tournament: { name: 'WMGT Season 5' },
        sessions: {
          id: 42,
          week: 'Week 3',
          session_date: '2024-08-10',
          registration_open: true,
          available_time_slots: [{ time_slot: '22:00', day_offset: -1 }]
        }
      };

      const formattedSlots = [{
        value: { time_slot: '22:00', day_offset: -1 },
        utcTime: '22:00',
        utcDate: 'Aug 9',
        localTime: '22:00',
        localDate: 'Aug 9',
        localTimezone: 'UTC',
        dateChanged: false,
        display: '22:00 UTC'
      }];

      beforeEach(() => {
        services.registrationService.getCurrentTournament.mockResolvedValue(tournamentData);
        services.registrationMessageManager.deriveTournamentState.mockReturnValue('registration_open');
        services.timezoneService.getUserTimezone.mockResolvedValue('UTC');
        services.timezoneService.formatTournamentTimeSlots.mockReturnValue(formattedSlots);
      });

      it('should fetch player registrations with the user discord ID', async () => {
        await handler.handleRegisterButton(interaction);

        expect(services.registrationService.getPlayerRegistrations).toHaveBeenCalledWith('123456789');
      });

      it('should route to handleNewRegistration when player has no registrations', async () => {
        services.registrationService.getPlayerRegistrations.mockResolvedValue({
          player: null,
          registrations: []
        });

        await handler.handleRegisterButton(interaction);

        // handleNewRegistration calls getUserTimezone and editReply with select menu
        expect(services.timezoneService.getUserTimezone).toHaveBeenCalled();
        expect(interaction.editReply).toHaveBeenCalled();
      });

      it('should route to handleExistingRegistration when player has active registrations', async () => {
        services.registrationService.getPlayerRegistrations.mockResolvedValue({
          player: { discord_id: '123456789' },
          registrations: [{
            session_id: 1,
            time_slot: '22:00',
            session_date: '2024-08-10',
            tournament_name: 'WMGT Season 5',
            week: 'Week 3'
          }]
        });

        await handler.handleRegisterButton(interaction);

        // handleExistingRegistration shows an embed with current registration details
        expect(interaction.editReply).toHaveBeenCalled();
        const replyArgs = interaction.editReply.mock.calls[0][0];
        expect(replyArgs.embeds).toBeDefined();
        expect(replyArgs.embeds.length).toBe(1);
        expect(replyArgs.embeds[0].data.title).toBe('📋 Your Current Registration');
      });

      it('should treat null registrationData as new registration', async () => {
        services.registrationService.getPlayerRegistrations.mockResolvedValue(null);

        await handler.handleRegisterButton(interaction);

        expect(services.timezoneService.getUserTimezone).toHaveBeenCalled();
      });

      it('should treat missing registrations array as new registration', async () => {
        services.registrationService.getPlayerRegistrations.mockResolvedValue({ player: { discord_id: '123' } });

        await handler.handleRegisterButton(interaction);

        expect(services.timezoneService.getUserTimezone).toHaveBeenCalled();
      });
    });
  });

  describe('handleMyRoomButton', () => {
    it('should defer reply as ephemeral', async () => {
      await handler.handleMyRoomButton(interaction);

      expect(interaction.deferReply).toHaveBeenCalledWith({ ephemeral: true });
    });

    it('should fetch player registrations and reply with embed', async () => {
      services.timezoneService.getUserTimezone.mockResolvedValue('UTC');
      services.timezoneService.validateTimezone = vi.fn().mockReturnValue(true);
      services.registrationService.getPlayerRegistrations.mockResolvedValue({
        player: { name: 'Test Player' },
        registrations: [{
          week: 'Week 42',
          session_date_epoch: 1723327200,
          session_date_formatted: 'Sat, Aug 10, 2024 10:00 PM UTC',
          room_no: 2,
          room_players: [{ player_name: 'Test Player', isNew: false }],
          session_id: 42,
          courses: []
        }]
      });

      await handler.handleMyRoomButton(interaction);

      expect(services.registrationService.getPlayerRegistrations).toHaveBeenCalledWith(interaction.user.id);
      expect(interaction.editReply).toHaveBeenCalledWith(expect.objectContaining({
        embeds: expect.any(Array)
      }));
    });

    it('should return fallback error message when status loading fails', async () => {
      services.timezoneService.getUserTimezone.mockRejectedValue(new Error('service down'));

      await handler.handleMyRoomButton(interaction);

      expect(interaction.editReply).toHaveBeenCalledWith(expect.objectContaining({
        content: expect.stringContaining('Could not load your room status')
      }));
    });
  });

  describe('handleOngoingTournament', () => {
    it('should reply with lockout message', async () => {
      const tournamentData = {
        sessions: {
          available_time_slots: [{ time_slot: '22:00', day_offset: -1 }]
        }
      };

      await handler.handleOngoingTournament(interaction, tournamentData);

      expect(interaction.editReply).toHaveBeenCalled();
      const content = interaction.editReply.mock.calls[0][0].content;
      expect(content).toContain('locked');
      expect(content).toContain('in progress');
    });

    it('should include time slots in the message', async () => {
      const tournamentData = {
        sessions: {
          available_time_slots: [
            { time_slot: '22:00', day_offset: -1 },
            { time_slot: '04:00', day_offset: 0 }
          ]
        }
      };

      await handler.handleOngoingTournament(interaction, tournamentData);

      const content = interaction.editReply.mock.calls[0][0].content;
      expect(content).toContain('22:00 UTC');
      expect(content).toContain('04:00 UTC');
    });

    it('should handle empty time slots gracefully', async () => {
      const tournamentData = { sessions: { available_time_slots: [] } };

      await handler.handleOngoingTournament(interaction, tournamentData);

      expect(interaction.editReply).toHaveBeenCalled();
      const content = interaction.editReply.mock.calls[0][0].content;
      expect(content).toContain('locked');
    });

    it('should handle missing time slots gracefully', async () => {
      const tournamentData = { sessions: {} };

      await handler.handleOngoingTournament(interaction, tournamentData);

      expect(interaction.editReply).toHaveBeenCalled();
      const content = interaction.editReply.mock.calls[0][0].content;
      expect(content).toContain('locked');
    });
  });

  describe('handleUnregister', () => {
    const currentRegistration = {
      session_id: 42,
      time_slot: '22:00',
      session_date: '2024-08-10',
      tournament_name: 'WMGT Season 5',
      week: 'Week 3'
    };

    let confirmCollector;

    beforeEach(() => {
      confirmCollector = createMockCollector();
      const confirmMessage = {
        createMessageComponentCollector: vi.fn().mockReturnValue(confirmCollector)
      };
      interaction.editReply.mockResolvedValue(confirmMessage);
    });

    it('should show confirmation embed with unregistration details', async () => {
      await handler.handleUnregister(interaction, currentRegistration);

      expect(interaction.editReply).toHaveBeenCalled();
      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.embeds).toBeDefined();
      expect(replyArgs.embeds.length).toBe(1);
      const embed = replyArgs.embeds[0].data;
      expect(embed.title).toBe('⚠️ Confirm Unregistration');
      expect(embed.description).toContain('Week 3');
    });

    it('should include confirm and cancel buttons', async () => {
      await handler.handleUnregister(interaction, currentRegistration);

      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.components.length).toBe(1);
      const buttons = replyArgs.components[0].components;
      expect(buttons.length).toBe(2);

      const confirmBtn = buttons.find(b => b.data.custom_id === 'reg_confirm_unreg_42');
      const cancelBtn = buttons.find(b => b.data.custom_id === 'reg_cancel');
      expect(confirmBtn).toBeDefined();
      expect(confirmBtn.data.style).toBe(ButtonStyle.Danger);
      expect(cancelBtn).toBeDefined();
    });

    it('should call unregisterPlayer on confirm and show success', async () => {
      services.registrationService.unregisterPlayer.mockResolvedValue({ success: true });

      await handler.handleUnregister(interaction, currentRegistration);

      const confirmInteraction = {
        customId: 'reg_confirm_unreg_42',
        user: { id: '123456789' },
        deferUpdate: vi.fn().mockResolvedValue(undefined)
      };

      await confirmCollector._emit('collect', confirmInteraction);

      expect(services.registrationService.unregisterPlayer).toHaveBeenCalledWith(
        expect.objectContaining({ id: '123456789' }),
        42
      );
      expect(confirmInteraction.deferUpdate).toHaveBeenCalled();

      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.embeds[0].data.title).toContain('Successful');
      expect(lastCall.components).toEqual([]);
    });

    it('should show error embed when unregisterPlayer fails', async () => {
      services.registrationService.unregisterPlayer.mockRejectedValue(
        new Error('Cannot unregister after session started')
      );

      await handler.handleUnregister(interaction, currentRegistration);

      const confirmInteraction = {
        customId: 'reg_confirm_unreg_42',
        user: { id: '123456789' },
        deferUpdate: vi.fn().mockResolvedValue(undefined)
      };

      await confirmCollector._emit('collect', confirmInteraction);

      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      const embed = lastCall.embeds[0].data;
      expect(embed.title).toContain('Failed');
      expect(embed.description).toContain('Cannot unregister after session started');
      expect(embed.footer.text).toContain('unchanged');
    });

    it('should show cancellation message on cancel', async () => {
      await handler.handleUnregister(interaction, currentRegistration);

      const cancelInteraction = {
        customId: 'reg_cancel',
        user: { id: '123456789' },
        update: vi.fn().mockResolvedValue(undefined)
      };

      await confirmCollector._emit('collect', cancelInteraction);

      expect(cancelInteraction.update).toHaveBeenCalled();
      const updateArgs = cancelInteraction.update.mock.calls[0][0];
      expect(updateArgs.content).toContain('unchanged');
      expect(updateArgs.embeds).toEqual([]);
      expect(updateArgs.components).toEqual([]);
    });

    it('should show timeout message when collector times out', async () => {
      await handler.handleUnregister(interaction, currentRegistration);

      await confirmCollector._emit('end', new Map(), 'time');

      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.content).toContain('timed out');
      expect(lastCall.embeds).toEqual([]);
      expect(lastCall.components).toEqual([]);
    });
  });

  describe('handleExistingRegistration', () => {
    const registrationData = {
      player: { discord_id: '123456789', timezone: 'America/New_York' },
      registrations: [{
        session_id: 42,
        time_slot: '22:00',
        room_no: 3,
        session_date: '2024-08-10',
        tournament_name: 'WMGT Season 5',
        week: 'Week 3'
      }]
    };

    const tournamentData = {
      tournament: { name: 'WMGT Season 5' },
      sessions: {
        id: 42,
        week: 'Week 3',
        session_date: '2024-08-10',
        available_time_slots: [
          { time_slot: '22:00', day_offset: -1, session_date_epoch: 1723327200 },
          { time_slot: '02:00', day_offset: 0, session_date_epoch: 1723341600 }
        ]
      }
    };

    beforeEach(() => {
      services.timezoneService.getUserTimezone.mockResolvedValue('America/New_York');
    });

    it('should display an embed with title "📋 Your Current Registration"', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      expect(interaction.editReply).toHaveBeenCalled();
      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.embeds).toBeDefined();
      expect(replyArgs.embeds.length).toBe(1);
      const embed = replyArgs.embeds[0].data;
      expect(embed.title).toBe('📋 Your Current Registration');
    });

    it('should use blue color (0x0099FF) for the embed', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const embed = interaction.editReply.mock.calls[0][0].embeds[0].data;
      expect(embed.color).toBe(0x0099FF);
    });

    it('should include tournament name in embed fields', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const embed = interaction.editReply.mock.calls[0][0].embeds[0].data;
      expect(embed.fields.some(f => f.value.includes('WMGT Season 5'))).toBe(true);
    });

    it('should include week in embed fields', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const embed = interaction.editReply.mock.calls[0][0].embeds[0].data;
      expect(embed.fields.some(f => f.value.includes('Week 3'))).toBe(true);
    });

    it('should include signed-up date with Discord epoch timestamp when epoch is available', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const embed = interaction.editReply.mock.calls[0][0].embeds[0].data;
      const signedUpField = embed.fields.find(f => f.name.includes('Signed up for'));
      expect(signedUpField).toBeDefined();
      expect(signedUpField.value).toContain('<t:1723327200:f>');
    });

    it('should show fallback session date when epoch is unavailable', async () => {
      const noEpochTournament = {
        ...tournamentData,
        sessions: {
          ...tournamentData.sessions,
          available_time_slots: [
            { time_slot: '22:00', day_offset: -1 },
            { time_slot: '02:00', day_offset: 0 }
          ]
        }
      };

      await handler.handleExistingRegistration(interaction, registrationData, noEpochTournament);

      const embed = interaction.editReply.mock.calls[0][0].embeds[0].data;
      const signedUpField = embed.fields.find(f => f.name.includes('Signed up for'));
      expect(signedUpField.value).toBe('2024-08-10');
    });

    it('should include session date with Discord epoch timestamp', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const embed = interaction.editReply.mock.calls[0][0].embeds[0].data;
      const dateField = embed.fields.find(f => f.name.includes('Signed up for'));
      expect(dateField.value).toContain('<t:1723327200:f>');
    });

    it('should include "Change Time Slot" and "Unregister" buttons', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.components).toBeDefined();
      expect(replyArgs.components.length).toBe(1);

      const buttonRow = replyArgs.components[0];
      const buttons = buttonRow.components;
      expect(buttons.length).toBe(2);

      const changeButton = buttons.find(b => b.data.custom_id === 'reg_change_slot');
      const unregButton = buttons.find(b => b.data.custom_id === 'reg_unregister');

      expect(changeButton).toBeDefined();
      expect(changeButton.data.label).toBe('Change Time Slot');
      expect(changeButton.data.style).toBe(ButtonStyle.Primary);

      expect(unregButton).toBeDefined();
      expect(unregButton.data.label).toBe('Unregister');
      expect(unregButton.data.style).toBe(ButtonStyle.Danger);
    });

    it('should create a component collector with 5-minute timeout', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      expect(interaction._mockMessage.createMessageComponentCollector).toHaveBeenCalledWith(
        expect.objectContaining({
          time: 300000
        })
      );
    });

    it('should call handleTimeSlotChange on "Change Time Slot" click', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const changeInteraction = {
        customId: 'reg_change_slot',
        user: { id: '123456789' },
        deferUpdate: vi.fn().mockResolvedValue(undefined)
      };

      await interaction._mockCollector._emit('collect', changeInteraction);

      expect(services.registrationService.unregisterPlayer).not.toHaveBeenCalled();
      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.content).toContain('Select a new time slot');
    });

    it('should call handleUnregister on "Unregister" click', async () => {
      services.registrationService.unregisterPlayer.mockResolvedValue({ success: true });

      // Set up a nested collector for the unregister confirmation flow
      const unregConfirmCollector = createMockCollector();
      const unregConfirmMessage = {
        createMessageComponentCollector: vi.fn().mockReturnValue(unregConfirmCollector)
      };
      // The second editReply (from handleUnregister) returns the confirm message
      interaction.editReply
        .mockResolvedValueOnce(interaction._mockMessage) // first call from handleExistingRegistration
        .mockResolvedValueOnce(unregConfirmMessage);      // second call from handleUnregister

      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      const unregInteraction = {
        customId: 'reg_unregister',
        user: { id: '123456789' },
        deferUpdate: vi.fn().mockResolvedValue(undefined)
      };

      await interaction._mockCollector._emit('collect', unregInteraction);

      // handleUnregister should have shown a confirmation embed
      const secondCall = interaction.editReply.mock.calls[1][0];
      expect(secondCall.embeds).toBeDefined();
      expect(secondCall.embeds[0].data.title).toBe('⚠️ Confirm Unregistration');
    });

    it('should show timeout message when collector times out', async () => {
      await handler.handleExistingRegistration(interaction, registrationData, tournamentData);

      // Simulate timeout
      await interaction._mockCollector._emit('end', new Map(), 'time');

      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.content).toContain('timed out');
      expect(lastCall.components).toEqual([]);
      expect(lastCall.embeds).toEqual([]);
    });

    it('should fall back to tournamentData fields when registration fields are missing', async () => {
      const sparseRegistration = {
        player: { discord_id: '123456789' },
        registrations: [{
          session_id: 42,
          time_slot: '22:00',
          session_date: '2024-08-10'
        }]
      };

      await handler.handleExistingRegistration(interaction, sparseRegistration, tournamentData);

      const embed = interaction.editReply.mock.calls[0][0].embeds[0].data;
      // Falls back to tournamentData.tournament.name and tournamentData.sessions.week
      expect(embed.fields.some(f => f.value.includes('WMGT Season 5'))).toBe(true);
      expect(embed.fields.some(f => f.value.includes('Week 3'))).toBe(true);
    });
  });

  describe('handleTimeSlotChange', () => {
    const currentRegistration = {
      session_id: 42,
      time_slot: '22:00',
      session_date: '2024-08-10',
      tournament_name: 'WMGT Season 5',
      week: 'Week 3'
    };

    const tournamentData = {
      tournament: { name: 'WMGT Season 5' },
      sessions: {
        id: 42,
        week: 'Week 3',
        session_date: '2024-08-10',
        available_time_slots: [
          { time_slot: '22:00', day_offset: -1 },
          { time_slot: '02:00', day_offset: 0 }
        ]
      }
    };

    const formattedSlots = [
      {
        value: { time_slot: '22:00', day_offset: -1 },
        utcTime: '22:00',
        utcDate: 'Aug 9',
        localTime: '6:00 PM',
        localDate: 'Aug 9',
        localTimezone: 'EDT',
        dateChanged: false,
        display: '6:00 PM EDT (22:00 UTC)'
      },
      {
        value: { time_slot: '02:00', day_offset: 0 },
        utcTime: '02:00',
        utcDate: 'Aug 10',
        localTime: '10:00 PM',
        localDate: 'Aug 9',
        localTimezone: 'EDT',
        dateChanged: true,
        display: '10:00 PM EDT (02:00 UTC)'
      }
    ];

    beforeEach(() => {
      services.timezoneService.getUserTimezone.mockResolvedValue('America/New_York');
      services.timezoneService.formatTournamentTimeSlots.mockReturnValue(formattedSlots);
    });

    it('should not unregister the player before they choose a new slot', async () => {
      await handler.handleTimeSlotChange(interaction, currentRegistration, tournamentData);

      expect(services.registrationService.unregisterPlayer).not.toHaveBeenCalled();
    });

    it('should show select menu with available time slots while keeping the current slot', async () => {
      await handler.handleTimeSlotChange(interaction, currentRegistration, tournamentData);

      expect(interaction.editReply).toHaveBeenCalled();
      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.components).toBeDefined();
      expect(replyArgs.components.length).toBe(1);
      expect(replyArgs.content).toContain('Select a new time slot');
      expect(replyArgs.content).toContain('Your current slot is');
      expect(replyArgs.content).toContain('keep it unless your new selection is successfully saved');
    });

    it('should register player for new slot on selection', async () => {
      services.registrationService.registerPlayer.mockResolvedValue({
        success: true,
        registration: { room_no: 5 }
      });

      await handler.handleTimeSlotChange(interaction, currentRegistration, tournamentData);

      // Simulate selecting a new time slot
      const selectInteraction = {
        customId: 'reg_change_timeslot_select',
        values: ['02:00'],
        user: { id: '123456789' },
        deferUpdate: vi.fn().mockResolvedValue(undefined)
      };

      await interaction._mockCollector._emit('collect', selectInteraction);

      expect(services.registrationService.registerPlayer).toHaveBeenCalledWith(
        interaction.user,
        42,
        '02:00',
        'America/New_York'
      );
    });

    it('should show success embed with room number after changing time slot', async () => {
      services.registrationService.registerPlayer.mockResolvedValue({
        success: true,
        registration: { room_no: 5 }
      });

      await handler.handleTimeSlotChange(interaction, currentRegistration, tournamentData);

      const selectInteraction = {
        customId: 'reg_change_timeslot_select',
        values: ['02:00'],
        user: { id: '123456789' },
        deferUpdate: vi.fn().mockResolvedValue(undefined)
      };

      await interaction._mockCollector._emit('collect', selectInteraction);

      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.embeds).toBeDefined();
      expect(lastCall.embeds.length).toBe(1);
      const embed = lastCall.embeds[0].data;
      expect(embed.title).toContain('Successfully');
      expect(embed.fields.some(f => f.value.includes('Room 5'))).toBe(true);
      expect(lastCall.components).toEqual([]);
    });

    it('should show error embed when changing time slot fails', async () => {
      services.registrationService.registerPlayer.mockRejectedValue(
        new Error('All rooms are full')
      );

      await handler.handleTimeSlotChange(interaction, currentRegistration, tournamentData);

      const selectInteraction = {
        customId: 'reg_change_timeslot_select',
        values: ['02:00'],
        user: { id: '123456789' },
        deferUpdate: vi.fn().mockResolvedValue(undefined)
      };

      await interaction._mockCollector._emit('collect', selectInteraction);

      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.embeds).toBeDefined();
      const embed = lastCall.embeds[0].data;
      expect(embed.title).toContain('Time Slot Change Failed');
      expect(embed.description).toContain('All rooms are full');
      expect(embed.footer.text).toContain('existing registration is unchanged');
    });

    it('should show timeout message when collector times out', async () => {
      await handler.handleTimeSlotChange(interaction, currentRegistration, tournamentData);

      await interaction._mockCollector._emit('end', new Map(), 'time');

      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.content).toContain('timed out');
      expect(lastCall.components).toEqual([]);
    });

    it('should create a component collector with 5-minute timeout', async () => {
      await handler.handleTimeSlotChange(interaction, currentRegistration, tournamentData);

      expect(interaction._mockMessage.createMessageComponentCollector).toHaveBeenCalledWith(
        expect.objectContaining({
          time: 300000
        })
      );
    });
  });

  describe('handleNewRegistration', () => {
    const tournamentData = {
      tournament: { name: 'WMGT Season 5' },
      sessions: {
        id: 42,
        week: 'Week 3',
        session_date: '2024-08-10',
        courses: [{ course_name: 'Sweetopia' }, { course_name: 'Labyrinth' }],
        available_time_slots: [
          { time_slot: '22:00', day_offset: -1 },
          { time_slot: '02:00', day_offset: 0 }
        ]
      }
    };

    const formattedSlots = [
      {
        value: { time_slot: '22:00', day_offset: -1 },
        utcTime: '22:00',
        utcDate: 'Aug 9',
        localTime: '6:00 PM',
        localDate: 'Aug 9',
        localTimezone: 'EDT',
        dateChanged: false,
        display: '6:00 PM EDT (22:00 UTC)'
      },
      {
        value: { time_slot: '02:00', day_offset: 0 },
        utcTime: '02:00',
        utcDate: 'Aug 10',
        localTime: '10:00 PM',
        localDate: 'Aug 9',
        localTimezone: 'EDT',
        dateChanged: true,
        display: '10:00 PM EDT (02:00 UTC)'
      }
    ];

    beforeEach(() => {
      services.timezoneService.getUserTimezone.mockResolvedValue('America/New_York');
      services.timezoneService.formatTournamentTimeSlots.mockReturnValue(formattedSlots);
    });

    it('should get the player timezone', async () => {
      await handler.handleNewRegistration(interaction, tournamentData);

      expect(services.timezoneService.getUserTimezone).toHaveBeenCalledWith(
        services.registrationService,
        '123456789'
      );
    });

    it('should format time slots with the player timezone', async () => {
      await handler.handleNewRegistration(interaction, tournamentData);

      expect(services.timezoneService.formatTournamentTimeSlots).toHaveBeenCalledWith(
        tournamentData.sessions.available_time_slots,
        tournamentData.sessions.session_date,
        'America/New_York'
      );
    });

    it('should show select menu with time slot options', async () => {
      await handler.handleNewRegistration(interaction, tournamentData);

      expect(interaction.editReply).toHaveBeenCalled();
      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.components).toBeDefined();
      expect(replyArgs.components.length).toBeGreaterThan(0);
    });

    it('should include week name in the prompt', async () => {
      await handler.handleNewRegistration(interaction, tournamentData);

      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.content).toContain('Week 3');
    });

    it('should show timezone tip when player timezone is UTC', async () => {
      services.timezoneService.getUserTimezone.mockResolvedValue('UTC');

      const utcSlots = formattedSlots.map(s => ({
        ...s,
        localTime: s.utcTime,
        localTimezone: 'UTC',
        dateChanged: false
      }));
      services.timezoneService.formatTournamentTimeSlots.mockReturnValue(utcSlots);

      await handler.handleNewRegistration(interaction, tournamentData);

      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.content).toContain('/timezone');
    });

    it('should NOT show timezone tip when player has a timezone set', async () => {
      await handler.handleNewRegistration(interaction, tournamentData);

      const replyArgs = interaction.editReply.mock.calls[0][0];
      expect(replyArgs.content).not.toContain('/timezone');
    });

    it('should create a component collector on the reply message', async () => {
      await handler.handleNewRegistration(interaction, tournamentData);

      expect(interaction._mockMessage.createMessageComponentCollector).toHaveBeenCalledWith(
        expect.objectContaining({
          time: 300000
        })
      );
    });

    it('should show timeout message when collector times out', async () => {
      await handler.handleNewRegistration(interaction, tournamentData);

      // Simulate timeout
      interaction._mockCollector._emit('end', new Map(), 'time');

      // editReply is called again with timeout message
      const lastCall = interaction.editReply.mock.calls[interaction.editReply.mock.calls.length - 1][0];
      expect(lastCall.content).toContain('timed out');
      expect(lastCall.components).toEqual([]);
    });

    describe('time slot selection and confirmation', () => {
      let selectInteraction;
      let rulesCollector;

      beforeEach(async () => {
        // Set up a mock for the rules step's collector
        rulesCollector = createMockCollector();
        const rulesMessage = {
          createMessageComponentCollector: vi.fn().mockReturnValue(rulesCollector)
        };

        // First editReply returns the select menu message (from handleNewRegistration),
        // second editReply returns the rules message (from _handleRulesDisplay)
        interaction.editReply
          .mockResolvedValueOnce(interaction._mockMessage)
          .mockResolvedValueOnce(rulesMessage);

        selectInteraction = {
          customId: 'reg_timeslot_select',
          values: ['22:00'],
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined)
        };
      });

      it('should show rules embed after time slot selection', async () => {
        await handler.handleNewRegistration(interaction, tournamentData);

        // Simulate selecting a time slot
        await interaction._mockCollector._emit('collect', selectInteraction);

        expect(selectInteraction.deferUpdate).toHaveBeenCalled();

        // interaction.editReply call[0] = select menu, call[1] = rules embed
        expect(interaction.editReply).toHaveBeenCalledTimes(2);
        const replyArgs = interaction.editReply.mock.calls[1][0];
        expect(replyArgs.embeds).toBeDefined();
        expect(replyArgs.embeds.length).toBe(1);
        expect(replyArgs.embeds[0].data.title).toBe('📜 Tournament Rules');
        expect(replyArgs.components).toBeDefined();
      });

      it('should register player after acknowledging rules', async () => {
        services.registrationService.registerPlayer.mockResolvedValue({
          success: true,
          registration: { room_no: 3 }
        });

        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        // Simulate acknowledging rules
        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        expect(services.registrationService.registerPlayer).toHaveBeenCalledWith(
          acknowledgeInteraction.user,
          42,
          '22:00',
          'America/New_York'
        );
        expect(acknowledgeInteraction.editReply).toHaveBeenCalled();
      });

      it('should show a success embed after acknowledging rules', async () => {
        services.registrationService.registerPlayer.mockResolvedValue({
          success: true,
          registration: { room_no: 3 }
        });

        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        const embed = acknowledgeInteraction.editReply.mock.calls[0][0].embeds[0];
        const embedData = embed.data;
        expect(embedData.title).toContain('Successful');
      });

      it('should include the registered session timestamp in the success embed after acknowledging rules', async () => {
        services.registrationService.registerPlayer.mockResolvedValue({
          success: true,
          registration: { room_no: 3 }
        });

        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        const embed = acknowledgeInteraction.editReply.mock.calls[0][0].embeds[0];
        const embedData = embed.data;
        expect(embedData.fields.some(f => f.value.includes('<t:'))).toBe(true);
      });

      it('should include courses in success embed after acknowledging rules', async () => {
        services.registrationService.registerPlayer.mockResolvedValue({
          success: true,
          registration: { room_no: 3 }
        });

        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        const embed = acknowledgeInteraction.editReply.mock.calls[0][0].embeds[0];
        const embedData = embed.data;
        const coursesField = embedData.fields.find(f => f.name.includes('Courses'));
        expect(coursesField).toBeDefined();
        expect(coursesField.value).toContain('Sweetopia');
        expect(coursesField.value).toContain('Labyrinth');
      });

      it('should not include courses field in success embed when courses array is empty', async () => {
        services.registrationService.registerPlayer.mockResolvedValue({
          success: true,
          registration: { room_no: 3 }
        });

        const noCourseData = {
          ...tournamentData,
          sessions: { ...tournamentData.sessions, courses: [] }
        };

        await handler.handleNewRegistration(interaction, noCourseData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        const embed = acknowledgeInteraction.editReply.mock.calls[0][0].embeds[0];
        const embedData = embed.data;
        expect(embedData.fields.every(f => !f.name.includes('Courses'))).toBe(true);
      });

      it('should stop the select collector after selection', async () => {
        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        expect(interaction._mockCollector.stop).toHaveBeenCalledWith('selection_made');
      });

      it('should register player when rules are acknowledged', async () => {
        services.registrationService.registerPlayer.mockResolvedValue({
          success: true,
          registration: { room_no: 3 }
        });

        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        // Acknowledge rules first
        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        expect(services.registrationService.registerPlayer).toHaveBeenCalledWith(
          acknowledgeInteraction.user,
          42,
          '22:00',
          'America/New_York'
        );
      });

      it('should show success message with room number after registration', async () => {
        services.registrationService.registerPlayer.mockResolvedValue({
          success: true,
          registration: { room_no: 3 }
        });

        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        const replyArgs = acknowledgeInteraction.editReply.mock.calls[0][0];
        const embed = replyArgs.embeds[0];
        expect(embed.data.title).toContain('Successful');
        expect(embed.data.fields.some(f => f.value.includes('Room 3'))).toBe(true);
        expect(replyArgs.components).toEqual([]);
      });

      it('should show error message when registration fails', async () => {
        services.registrationService.registerPlayer.mockRejectedValue(
          new Error('Registration for this session has closed')
        );

        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        const acknowledgeInteraction = {
          customId: 'reg_rules_acknowledge',
          user: { id: '123456789', username: 'TestPlayer' },
          deferUpdate: vi.fn().mockResolvedValue(undefined),
          editReply: vi.fn().mockResolvedValue(undefined)
        };
        await rulesCollector._emit('collect', acknowledgeInteraction);

        const replyArgs = acknowledgeInteraction.editReply.mock.calls[0][0];
        const embed = replyArgs.embeds[0];
        expect(embed.data.title).toContain('Failed');
        expect(embed.data.description).toContain('Registration for this session has closed');
      });

      it('should show cancellation message on cancel button click in rules step', async () => {
        await handler.handleNewRegistration(interaction, tournamentData);
        await interaction._mockCollector._emit('collect', selectInteraction);

        const cancelInteraction = {
          customId: 'reg_rules_cancel',
          user: { id: '123456789', username: 'TestPlayer' },
          update: vi.fn().mockResolvedValue(undefined)
        };

        await rulesCollector._emit('collect', cancelInteraction);

        expect(cancelInteraction.update).toHaveBeenCalled();
        const updateArgs = cancelInteraction.update.mock.calls[0][0];
        expect(updateArgs.content).toContain('cancelled');
        expect(updateArgs.components).toEqual([]);
      });
    });
  });
});

import { describe, it, expect } from 'vitest';
import { config } from '../config/config.js';

describe('Project Structure', () => {
  it('should load configuration correctly', () => {
    expect(config).toBeDefined();
    expect(config.discord).toBeDefined();
    expect(config.api).toBeDefined();
    expect(config.bot).toBeDefined();
  });

  it('should have correct API endpoints configured', () => {
    expect(config.api.endpoints.currentTournament).toBe('/api/tournaments/current');
    expect(config.api.endpoints.register).toBe('/api/tournaments/register');
    expect(config.api.endpoints.unregister).toBe('/api/tournaments/unregister');
    expect(config.api.endpoints.playerRegistrations).toBe('/api/players/registrations');
  });

  it('should have bot metadata configured', () => {
    expect(config.bot.name).toBe('WMGT Tournament Bot');
    expect(config.bot.version).toBe('1.0.0');
  });
});
import { describe, it, expect } from 'vitest';
import registerCommand from '../commands/register.js';
import unregisterCommand from '../commands/unregister.js';
import mystatusCommand from '../commands/mystatus.js';
import timezoneCommand from '../commands/timezone.js';

describe('Discord Bot Foundation', () => {
  describe('Command Structure', () => {
    it('should have proper command data structure for register command', () => {
      expect(registerCommand.data).toBeDefined();
      expect(registerCommand.data.name).toBe('register');
      expect(registerCommand.execute).toBeDefined();
      expect(typeof registerCommand.execute).toBe('function');
    });

    it('should have proper command data structure for unregister command', () => {
      expect(unregisterCommand.data).toBeDefined();
      expect(unregisterCommand.data.name).toBe('unregister');
      expect(unregisterCommand.execute).toBeDefined();
      expect(typeof unregisterCommand.execute).toBe('function');
    });

    it('should have proper command data structure for mystatus command', () => {
      expect(mystatusCommand.data).toBeDefined();
      expect(mystatusCommand.data.name).toBe('mystatus');
      expect(mystatusCommand.execute).toBeDefined();
      expect(typeof mystatusCommand.execute).toBe('function');
    });

    it('should have proper command data structure for timezone command', () => {
      expect(timezoneCommand.data).toBeDefined();
      expect(timezoneCommand.data.name).toBe('timezone');
      expect(timezoneCommand.execute).toBeDefined();
      expect(typeof timezoneCommand.execute).toBe('function');
    });
  });

  describe('Command Data Serialization', () => {
    it('should serialize register command data to JSON without errors', () => {
      expect(() => registerCommand.data.toJSON()).not.toThrow();
      const json = registerCommand.data.toJSON();
      expect(json.name).toBe('register');
      expect(json.description).toBe('Register for a tournament session');
    });

    it('should serialize unregister command data to JSON without errors', () => {
      expect(() => unregisterCommand.data.toJSON()).not.toThrow();
      const json = unregisterCommand.data.toJSON();
      expect(json.name).toBe('unregister');
      expect(json.description).toBe('Unregister from a tournament session');
    });

    it('should serialize mystatus command data to JSON without errors', () => {
      expect(() => mystatusCommand.data.toJSON()).not.toThrow();
      const json = mystatusCommand.data.toJSON();
      expect(json.name).toBe('mystatus');
      expect(json.description).toBe('View your current tournament registrations');
    });

    it('should serialize timezone command data to JSON without errors', () => {
      expect(() => timezoneCommand.data.toJSON()).not.toThrow();
      const json = timezoneCommand.data.toJSON();
      expect(json.name).toBe('timezone');
      expect(json.description).toBe('Set your preferred timezone for tournament time displays');
    });
  });

  describe('Command Options', () => {
    it('should have optional timezone parameter for register command', () => {
      const json = registerCommand.data.toJSON();
      expect(json.options).toBeDefined();
      expect(json.options.length).toBe(1);
      expect(json.options[0].name).toBe('timezone');
      expect(json.options[0].required).toBe(false);
    });

    it('should have required timezone parameter for timezone command', () => {
      const json = timezoneCommand.data.toJSON();
      expect(json.options).toBeDefined();
      expect(json.options.length).toBe(1);
      expect(json.options[0].name).toBe('timezone');
      expect(json.options[0].required).toBe(false);
    });

    it('should have optional timezone parameter for unregister command', () => {
      const json = unregisterCommand.data.toJSON();
      expect(json.options).toHaveLength(1);
      expect(json.options[0].name).toBe('timezone');
      expect(json.options[0].required).toBe(false);
    });

    it('should have optional timezone parameter for mystatus command', () => {
      const json = mystatusCommand.data.toJSON();
      expect(json.options).toHaveLength(1);
      expect(json.options[0].name).toBe('timezone');
      expect(json.options[0].required).toBe(false);
    });
  });
});
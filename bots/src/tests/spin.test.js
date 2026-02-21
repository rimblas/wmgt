import { describe, it, expect, beforeEach, vi } from 'vitest';

/**
 * Unit tests for SpinService
 * Requirements: 1.2, 5.1, 5.2
 */

let shouldFailRead = false;

vi.mock('fs/promises', async (importOriginal) => {
  const original = await importOriginal();
  return {
    ...original,
    readFile: vi.fn((...args) => {
      if (shouldFailRead) {
        return Promise.reject(new Error('ENOENT: no such file or directory'));
      }
      return original.readFile(...args);
    }),
  };
});

const { SpinService, clearCache } = await import('../services/SpinService.js');

describe('SpinService - Unit Tests', () => {
  let service;

  beforeEach(() => {
    shouldFailRead = false;
    clearCache();
    service = new SpinService();
  });

  describe('loadCourses', () => {
    it('should load 76 courses from courses.json', async () => {
      const courses = await service.loadCourses();
      expect(courses).toHaveLength(76);
    });

    it('should have 38 Easy and 38 Hard courses', async () => {
      const courses = await service.loadCourses();
      const easy = courses.filter(c => c.difficulty === 'Easy');
      const hard = courses.filter(c => c.difficulty === 'Hard');
      expect(easy).toHaveLength(38);
      expect(hard).toHaveLength(38);
    });

    it('should cache courses on subsequent calls', async () => {
      const first = await service.loadCourses();
      const second = await service.loadCourses();
      expect(first).toBe(second);
    });

    it('should throw when courses.json cannot be loaded', async () => {
      shouldFailRead = true;
      await expect(service.loadCourses()).rejects.toThrow('Failed to load courses');
    });
  });

  describe('filterCourses', () => {
    it('should return empty array when no courses match the filter', () => {
      const courses = [
        { code: 'ALE', name: 'Aliens', difficulty: 'Easy' },
        { code: 'ALH', name: 'Aliens', difficulty: 'Hard' },
      ];
      const result = service.filterCourses(courses, 'Medium');
      expect(result).toEqual([]);
    });

    it('should return all courses when difficulty is null', () => {
      const courses = [
        { code: 'ALE', name: 'Aliens', difficulty: 'Easy' },
        { code: 'ALH', name: 'Aliens', difficulty: 'Hard' },
      ];
      const result = service.filterCourses(courses, null);
      expect(result).toEqual(courses);
    });
  });
});


/**
 * Unit tests for spin command registration
 * Requirements: 4.1, 4.2, 4.3
 */
import spinCommand from '../commands/spin.js';

describe('Spin Command - Registration', () => {
  const json = spinCommand.data.toJSON();

  it('should register with the name "spin"', () => {
    expect(json.name).toBe('spin');
  });

  it('should have a description', () => {
    expect(json.description).toBeDefined();
    expect(json.description.length).toBeGreaterThan(0);
  });

  it('should have an optional difficulty option', () => {
    expect(json.options).toBeDefined();
    const difficultyOption = json.options.find(o => o.name === 'difficulty');
    expect(difficultyOption).toBeDefined();
    expect(difficultyOption.required).toBeFalsy();
  });

  it('should have Easy and Hard choices on the difficulty option', () => {
    const difficultyOption = json.options.find(o => o.name === 'difficulty');
    const choiceValues = difficultyOption.choices.map(c => c.value);
    expect(choiceValues).toContain('Easy');
    expect(choiceValues).toContain('Hard');
    expect(difficultyOption.choices).toHaveLength(2);
  });
});

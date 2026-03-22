import { describe, it, expect } from 'vitest';
import fc from 'fast-check';
import { DIFFICULTY_MAP } from '../services/SpinButtonHandler.js';
import { SpinService } from '../services/SpinService.js';

// --- Arbitraries ---

const VALID_CUSTOM_IDS = ['spin_any', 'spin_easy', 'spin_hard'];
const VALID_DIFFICULTY_VALUES = [null, 'Easy', 'Hard'];

const arbValidCustomId = () => fc.constantFrom(...VALID_CUSTOM_IDS);

// --- Property Tests ---

describe('Feature: spin-command-ui, Property 1: Difficulty mapping is total', () => {
  /**
   * Property 1: For any valid spin button Custom_ID in {spin_any, spin_easy, spin_hard},
   * DIFFICULTY_MAP[customId] produces a defined value (null, "Easy", or "Hard") —
   * no undefined results.
   *
   * **Validates: Requirements 2.1**
   */
  it('should produce a defined difficulty value for any valid Custom_ID', () => {
    fc.assert(
      fc.property(arbValidCustomId(), (customId) => {
        const difficulty = DIFFICULTY_MAP[customId];
        // The mapping must not produce undefined
        expect(difficulty).not.toBeUndefined();
        // The result must be one of the valid difficulty values
        expect(VALID_DIFFICULTY_VALUES).toContain(difficulty);
      }),
      { numRuns: 100 }
    );
  });
});

// --- Arbitraries for Property 2 ---

const arbDifficulty = () => fc.constantFrom('Easy', 'Hard');

const arbCourse = () =>
  fc.record({
    code: fc.string({ minLength: 1, maxLength: 10 }),
    name: fc.string({ minLength: 1, maxLength: 50 }),
    difficulty: arbDifficulty()
  });

const arbDifficultyFilter = () => fc.constantFrom(null, 'Easy', 'Hard');

/**
 * Generates a non-empty course list that is guaranteed to contain at least one
 * course matching the given difficulty filter. When filter is null (any), any
 * non-empty list suffices.
 */
const arbCoursesWithFilter = () =>
  arbDifficultyFilter().chain((filter) => {
    if (filter === null) {
      // Any filter — just need a non-empty list
      return fc.tuple(
        fc.array(arbCourse(), { minLength: 1, maxLength: 20 }),
        fc.constant(filter)
      );
    }
    // Specific filter — ensure at least one course matches
    const arbMatchingCourse = fc.record({
      code: fc.string({ minLength: 1, maxLength: 10 }),
      name: fc.string({ minLength: 1, maxLength: 50 }),
      difficulty: fc.constant(filter)
    });
    return fc.tuple(
      fc
        .tuple(
          arbMatchingCourse,
          fc.array(arbCourse(), { minLength: 0, maxLength: 19 })
        )
        .map(([required, rest]) => [required, ...rest]),
      fc.constant(filter)
    );
  });

// --- Property Test ---

describe('Feature: spin-command-ui, Property 2: Spin always returns a course from the filtered set', () => {
  const spinService = new SpinService();

  /**
   * Property 2: For any non-empty course list and any difficulty filter
   * (null, "Easy", or "Hard"), filtering the list and then selecting a random
   * course always returns a course object that exists in the filtered list and
   * whose difficulty matches the filter (or any difficulty when filter is null).
   *
   * **Validates: Requirements 2.2, 6.2**
   */
  it('should always return a course from the filtered set for any non-empty course list and difficulty filter', () => {
    fc.assert(
      fc.property(arbCoursesWithFilter(), ([courses, filter]) => {
        const filtered = spinService.filterCourses(courses, filter);

        // The filtered list must be non-empty (guaranteed by our generator)
        expect(filtered.length).toBeGreaterThan(0);

        const selected = spinService.selectRandom(filtered);

        // The selected course must exist in the filtered list
        expect(filtered).toContainEqual(selected);

        // The selected course's difficulty must match the filter (or any when null)
        if (filter !== null) {
          expect(selected.difficulty).toBe(filter);
        } else {
          expect(['Easy', 'Hard']).toContain(selected.difficulty);
        }
      }),
      { numRuns: 200 }
    );
  });
});

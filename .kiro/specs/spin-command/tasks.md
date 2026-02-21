# Implementation Plan: Spin Command

## Overview

Implement the `/spin` Discord slash command that randomly selects a Walkabout Mini Golf course. The implementation creates a static JSON data file, a service for course loading/filtering/selection, and the command handler — following existing bot patterns.

## Tasks

- [x] 1. Create course data file
  - [x] 1.1 Create `bots/data/courses.json` with all 74 courses
    - Each entry has `code`, `name`, and `difficulty` fields
    - Data sourced from `docs/courses-list.md`
    - 37 Easy and 37 Hard course entries
    - _Requirements: 1.1, 1.2_

- [x] 2. Implement SpinService
  - [x] 2.1 Create `bots/src/services/SpinService.js`
    - `loadCourses()`: reads and caches `bots/data/courses.json`, returns array of course objects
    - `filterCourses(courses, difficulty)`: filters by difficulty or returns all if null
    - `selectRandom(courses)`: picks a random course from the array
    - `buildEmbed(course)`: builds a Discord EmbedBuilder with course name, code, difficulty, color (green for Easy, blue for Hard), and course image URL
    - Follow caching pattern from `RulesProvider.js`
    - _Requirements: 1.3, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3_

  - [ ]* 2.2 Write property tests for SpinService
    - **Property 1: Course data structure validity**
    - **Validates: Requirements 1.1**
    - **Property 2: Selection membership**
    - **Validates: Requirements 2.1, 2.4**
    - **Property 3: Filter correctness**
    - **Validates: Requirements 2.2, 2.3**
    - **Property 4: Embed correctness**
    - **Validates: Requirements 3.1, 3.2, 3.3**

  - [x] 2.3 Write unit tests for SpinService
    - Test `loadCourses` returns 74 courses with 37 Easy and 37 Hard
    - Test error handling when courses.json is missing
    - Test `filterCourses` with empty result set
    - _Requirements: 1.2, 5.1, 5.2_

- [x] 3. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement spin command
  - [x] 4.1 Create `bots/src/commands/spin.js`
    - Register slash command with name `spin` and optional `difficulty` string option with choices `Easy` and `Hard`
    - `execute`: defer reply, get difficulty option, call SpinService to load/filter/select/build embed, edit reply with embed
    - Error handling: catch load failures and empty filter results, reply with appropriate error embeds using ErrorHandler
    - Follow existing command pattern from `votes.js`
    - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

  - [x] 4.2 Write unit tests for spin command registration
    - Verify command name is `spin`
    - Verify optional difficulty option with correct choices
    - Verify description is present
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 5. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Property tests use `fast-check` with Vitest, minimum 100 iterations each
- All tests go in `bots/src/tests/spin.test.js`
- No database or API dependencies — all data is local JSON

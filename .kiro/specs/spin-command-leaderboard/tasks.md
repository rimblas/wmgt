# Implementation Tasks

## Task 1: Add CourseLeaderboardService to SpinButtonHandler

### Description
Modify `SpinButtonHandler` to instantiate `CourseLeaderboardService` and add the `fetchTop3Leaderboard` method that fetches leaderboard data with a reduced timeout and single retry.

### Files to Modify
- `bots/src/services/SpinButtonHandler.js`

### Steps
- [x] 1.1 Import `CourseLeaderboardService` at the top of `SpinButtonHandler.js`
- [x] 1.2 Add `this.courseLeaderboardService = new CourseLeaderboardService()` to the constructor
- [x] 1.3 Implement `async fetchTop3Leaderboard(courseCode, userId)` method that:
  - Calls `this.courseLeaderboardService.getCourseLeaderboard(courseCode, userId)`
  - Calls `this.courseLeaderboardService.formatLeaderboardData(apiResponse, userId)`
  - Returns the formatted data limited to entries for the top 3 distinct scores
  - Returns `null` on any error (catches all exceptions, logs warning)
- [x] 1.4 Use a reduced timeout approach: wrap the leaderboard fetch in a `Promise.race` with a 5-second timeout, returning `null` if timeout is exceeded

## Task 2: Implement formatLeaderboardField Method

### Description
Add the `formatLeaderboardField` method to `SpinButtonHandler` that formats leaderboard data into a Discord embed field with the specified display rules.

### Files to Modify
- `bots/src/services/SpinButtonHandler.js`

### Steps
- [x] 2.1 Implement `formatLeaderboardField(leaderboardData)` method that:
  - Returns `null` if leaderboardData is null or has no entries
  - Groups entries by distinct score values
  - Formats 1st place: `🥇 \`{score}\` **PlayerA, PlayerB**` (names comma-delimited)
  - Formats 2nd place: `🥈 \`{score}\`` (score only, no names)
  - Formats 3rd place: `🥉 \`{score}\`` (score only, no names)
  - Caps 1st place names at 5, appending "+N more" if exceeded
  - Returns `{ name: '🏆 Best Scores', value: formattedString, inline: false }`
- [x] 2.2 Add score sign formatting: negative scores shown as-is (e.g., `-12`), zero or positive shown with `+` prefix (e.g., `+0`, `+2`)
- [x] 2.3 Ensure the field value does not exceed 1024 characters (truncate names if necessary)

## Task 3: Integrate Leaderboard into handleSpin Flow

### Description
Modify the `handleSpin` method to call `fetchTop3Leaderboard` after building the course embed and add the leaderboard field to the embed before sending.

### Files to Modify
- `bots/src/services/SpinButtonHandler.js`

### Steps
- [x] 3.1 After `const embed = this.spinService.buildEmbed(selected)` and before setting the footer, add:
  - Call `const leaderboardData = await this.fetchTop3Leaderboard(selected.code, interaction.user.id)`
  - Call `const leaderboardField = this.formatLeaderboardField(leaderboardData)`
  - If `leaderboardField` is not null, call `embed.addFields(leaderboardField)`
- [x] 3.2 Ensure the leaderboard fetch does not prevent the spin result from being sent — if `fetchTop3Leaderboard` returns null, the embed is sent without the field
- [x] 3.3 Add debug-level logging for successful leaderboard inclusion (course code, number of distinct scores shown)

## Task 4: Write Unit Tests for formatLeaderboardField

### Description
Add unit tests covering the formatting logic for the leaderboard field, including edge cases for ties, empty data, and character limits.

### Files to Create
- `bots/src/tests/SpinButtonHandler.leaderboard.test.js`

### Steps
- [x] 4.1 Test: returns null when leaderboardData is null
- [x] 4.2 Test: returns null when leaderboardData has empty entries array
- [x] 4.3 Test: formats single distinct score with player name correctly (🥇 only)
- [x] 4.4 Test: formats 2 distinct scores (🥇 with name, 🥈 score only)
- [x] 4.5 Test: formats 3 distinct scores (🥇 with name, 🥈 score only, 🥉 score only)
- [x] 4.6 Test: handles tie at 1st place — multiple player names comma-delimited
- [x] 4.7 Test: caps 1st place names at 5 with "+N more" indicator
- [x] 4.8 Test: score formatting — negative scores without `+`, zero/positive with `+`
- [x] 4.9 Test: field value does not exceed 1024 characters with many tied players

## Task 5: Write Unit Tests for fetchTop3Leaderboard

### Description
Add unit tests for the leaderboard fetch method, verifying graceful degradation on errors and correct data limiting.

### Files to Modify
- `bots/src/tests/SpinButtonHandler.leaderboard.test.js`

### Steps
- [x] 5.1 Test: returns formatted data limited to top 3 distinct scores when API succeeds
- [x] 5.2 Test: returns null when CourseLeaderboardService throws an error
- [x] 5.3 Test: returns null when API returns empty items array
- [x] 5.4 Test: returns null when timeout is exceeded (mock slow response)
- [x] 5.5 Test: logs warning when leaderboard fetch fails

## Task 6: Write Integration Test for handleSpin with Leaderboard

### Description
Add integration tests verifying the full spin flow includes leaderboard data in the embed when available, and omits it gracefully when not.

### Files to Modify
- `bots/src/tests/SpinButtonHandler.leaderboard.test.js`

### Steps
- [x] 6.1 Test: handleSpin includes "🏆 Best Scores" field in embed when leaderboard data is available
- [x] 6.2 Test: handleSpin sends embed without leaderboard field when API fails
- [x] 6.3 Test: handleSpin sends embed without leaderboard field when no scores exist for course
- [x] 6.4 Test: handleSpin completes within reasonable time even when leaderboard API is slow (timeout triggers)

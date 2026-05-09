# Requirements Document

## Introduction

The `/spin` command randomly selects a Walkabout Mini Golf course and displays it as a Discord embed. This enhancement adds the top 3 best leaderboard scores for the selected course to the spin result embed, giving players immediate context about how well others have performed on that course. The leaderboard data is fetched from the existing ORDS REST API using `CourseLeaderboardService`. The display shows the top 3 distinct scores with medal emojis — only 1st place includes player names (comma-delimited if tied), while 2nd and 3rd place show scores only. If the leaderboard is unavailable or empty, the spin result displays normally without scores.

## Glossary

- **Spin_Result_Embed**: The Discord embed displayed after a spin button click, showing the selected course name, code, difficulty, image, and (new) top 3 leaderboard scores
- **Top_3_Scores**: The three best distinct scores recorded for a course, fetched from the leaderboard API
- **Leaderboard_Field**: A Discord embed field added to the Spin_Result_Embed containing the formatted top 3 scores
- **Distinct_Score**: A unique score value in the leaderboard; multiple players may share the same score (tie)
- **CourseLeaderboardService**: The existing authenticated service that fetches leaderboard data from the ORDS REST API
- **Graceful_Degradation**: The behavior where the spin result is displayed without leaderboard data when the API is unavailable or returns no scores

## Requirements

### Requirement 1: Display Top 3 Leaderboard Scores in Spin Result

**User Story:** As a player, I want to see the top 3 best scores for the course I spun, so that I know how well others have performed on that course.

#### Acceptance Criteria

1. WHEN a spin result is displayed, THE SpinButtonHandler SHALL fetch leaderboard data for the selected course using CourseLeaderboardService and add a Leaderboard_Field to the Spin_Result_Embed showing up to 3 distinct best scores
2. WHEN the leaderboard contains scores, THE Leaderboard_Field SHALL display the 1st best score with a 🥇 medal emoji, the score value, and the player name(s) who achieved that score
3. WHEN multiple players are tied at the 1st best score, THE Leaderboard_Field SHALL display all tied player names as a comma-delimited list after the score
4. WHEN the leaderboard contains a 2nd best distinct score, THE Leaderboard_Field SHALL display it with a 🥈 medal emoji and the score value only (no player names)
5. WHEN the leaderboard contains a 3rd best distinct score, THE Leaderboard_Field SHALL display it with a 🥉 medal emoji and the score value only (no player names)
6. THE Leaderboard_Field SHALL be titled "🏆 Best Scores"

### Requirement 2: Graceful Degradation When Leaderboard Unavailable

**User Story:** As a player, I want my spin result to still display correctly even when the leaderboard service is unavailable, so that the spin command remains functional regardless of API status.

#### Acceptance Criteria

1. IF the CourseLeaderboardService fails to fetch leaderboard data (timeout, network error, 500 response), THEN THE SpinButtonHandler SHALL display the Spin_Result_Embed without the Leaderboard_Field and SHALL NOT show any error message to the user
2. IF the leaderboard API returns an empty result (no scores recorded for the course), THEN THE SpinButtonHandler SHALL display the Spin_Result_Embed without the Leaderboard_Field
3. IF the leaderboard API returns a 404 (course not found in leaderboard system), THEN THE SpinButtonHandler SHALL display the Spin_Result_Embed without the Leaderboard_Field
4. WHEN a leaderboard fetch fails, THE SpinButtonHandler SHALL log a warning-level message with the course code and error details for debugging

### Requirement 3: Leaderboard Fetch Performance

**User Story:** As a player, I want the spin result to appear quickly, so that the leaderboard enhancement does not noticeably slow down the spin experience.

#### Acceptance Criteria

1. THE SpinButtonHandler SHALL use a reduced timeout (no more than 5 seconds) for the leaderboard API call to ensure the spin result is delivered within Discord's interaction deadline
2. THE SpinButtonHandler SHALL limit leaderboard fetch retries to at most 1 retry to avoid exceeding the interaction timeout
3. THE leaderboard fetch SHALL NOT block or delay the spin result if it exceeds the timeout — the result SHALL be sent without the leaderboard field

### Requirement 4: Score Formatting

**User Story:** As a player, I want the leaderboard scores to be clearly formatted, so that I can quickly read and understand the best scores for the course.

#### Acceptance Criteria

1. THE score values SHALL be displayed in fixed-width formatting (backtick-wrapped) with a sign indicator (negative for under par, e.g., `-12`)
2. THE player names displayed for 1st place SHALL be bolded using Discord markdown (`**name**`)
3. WHEN the 1st place has more than 5 tied players, THE display SHALL show the first 5 names followed by an indicator of how many more (e.g., "+3 more")
4. THE Leaderboard_Field value SHALL NOT exceed Discord's 1024-character embed field limit

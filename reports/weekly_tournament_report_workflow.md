# Weekly Tournament Recap Workflow

Use this workflow for the `wmgt-weekly-report` hook and for a manual weekly
recap. It produces the Discord-ready tournament report used in
`S20W01_Tournament_Report.md` and `S20W02_Tournament_Report.md`.

## Inputs and output

- Input: a week code such as `S21W01`.
- Output: `reports/S21_reports/S21W01_Tournament_Report.md` (derive both path
  components from the supplied code).
- The report is a generated operational artifact. Do not modify an existing
  prior-week report to create a new one.

## Data rules

1. Confirm the requested week exists in `wmg_tournament_sessions_v` and its
   `completed_ind` is `Y`. Stop rather than produce a final recap for an
   incomplete week.
2. Use `wmg_tournament_session_points_v` with `completed_ind = 'Y'` for all
   leaderboard, rank, country, and score statistics.
3. Always use `wmg_players_v.player_name` for a player-facing name. Never use
   `wmg_players.name`, account names, or Discord mentions in the report.
4. Use the session ID returned by the session query when querying badges,
   courses, rounds, and rank history. Do not infer a session ID from a week
   number.
5. Preserve ties. Use `dense_rank()` to build the *medal and division groups*
   for all podium, division, and course-score winner queries. `dense_rank()`
   only controls which players share the gold/silver/bronze (or division 1st/
   2nd/3rd) group; it does not describe a player's finishing position.
6. A player's finishing **position** uses standard competition ranking (the
   `pos` column, equivalent to `rank()`), where ties share a position and the
   next position skips the tied slots. If three players tie for 1st, the next
   player is in 4th, not 2nd. Report finishing positions (for example, Player
   of the Week placements and country insights) from `pos`; never renumber
   ties into consecutive positions.

## Required report data

Collect and verify the following before drafting.

| Section | Source and definition |
| --- | --- |
| Header | `wmg_tournament_sessions_v`, joined to `wmg_tournament_courses` and `wmg_courses`, ordered by `course_no`. Show the easy course followed by the hard course. |
| Participant line | Count completed point rows, distinct non-null `country_code`, and counts by `rank_code` (`ELITE`, `PRO`, `SEMI`, `AMA`). |
| Podium | Completed point rows in the first three overall `dense_rank()` score groups, ordered by `total_score`. Include every tied player in each group with total, easy, and hard scores. Do not rely on `pos`, because a tied second place can leave no row at position 3. |
| Divisions | Completed point rows. For `AMA`, `SEMI`, and `PRO`, display the first three `dense_rank()` places by `total_score`, then the tied best `easy` and best `hard` scores. Elite is represented by the overall podium. |
| Player of the Week | Calculate average `pos` by rank, exclude the first three overall `dense_rank()` score groups, and calculate `avg_rank_pos - pos`. Qualify players at `>= 15`; recognize every player sharing the greatest qualifying improvement. |
| Insights | Use rank averages, country results, course scores, and leaderboard results. State only facts supported by these results. |
| Rank achievements | Use the `rank_achievements` CTE in `wmg_notification.tournament_recap_template`: keep each player's latest upward change for this session and list `ELITE`, `PRO`, and `SEMI` separately. |
| Diamond players | Use eligible `wmg_rounds_unpivot_mv` results (`score = 1`) and report every player tied for the most HN1s, with that count. |
| Coconuts and badges | Read `wmg_player_badges` for the session, joined to `wmg_players_v`. Coconuts are `COCONUT`; badges are `CACTUS`, `DUCK`, and `BEETLE`. Use the stored `badge_count` only when a count needs to be shown. |
| Unicorn awards | Query `wmg_player_unicorns_v` by `award_week = <requested week>`, not by `score_week`. A Unicorn is the only ace on a hole once its course has reached at least five completed tournament plays. The ace can have occurred in any of the first four plays and be awarded later, when the course becomes eligible. For every award-week match, report the player, course, hole, and score week; use the stored record rather than attempting to recalculate eligibility. |
| Course records | Sum `wmg_rounds_v.under_par` by player and tournament course, then list everyone tied for the best score on each course. |

The badge labels are:

- `CACTUS`: Solo Ace (only player to ace a hole)
- `DUCK`: Rare Ace (small number of players to ace a hole)
- `BEETLE`: Rare non-ace best score

For any empty category, write `**None**`; do not omit its line.

## Report layout

Follow the S20 examples closely. Keep this order:

1. Header, recap line, courses, player/rank-mix line, and one or two concise
   narrative paragraphs.
2. `⛳ **PODIUM PLACEMENTS**`.
3. `🎖️ **AMATEUR DIVISION**`, `🏅 **SEMI-PRO DIVISION**`, and
   `🏅 **PRO DIVISION**`.
4. `**PLAYER OF THE WEEK**` and `Hidden gems`.
5. `📈 **New Rank Achievements**`.
6. Diamond, coconut, badge, Unicorn-award (when one was awarded), and
   top-course-score sections.
7. The standard registration footer and role mention from the examples.

Use the same divider line (`---------------------------------`) and Discord emoji
syntax as the examples. Keep the prose upbeat and specific, but do not add
unsupported superlatives, fabricated context, or a `Commentary by Codex` line.

## Pre-save checklist

- [ ] The requested week is completed and the session ID is correct.
- [ ] Every printed player name exactly matches `wmg_players_v.player_name`.
- [ ] Total players, country count, rank mix, scores, rankings, and tie groups
      match the query output.
- [ ] Finishing positions come from `pos` (standard competition ranking): tied
      players share a position and the next position skips accordingly (three
      tied for 1st means the next player is 4th).
- [ ] Player(s) of the Week are outside positions 1-3 and use the documented
      rank-average calculation.
- [ ] New ranks, diamonds, coconuts, badges, and course leaders use the
      session-specific sources above.
- [ ] Unicorns were checked by `award_week`; every award is called out with its
      player, course, hole, and score week. Omit the Unicorn section only when
      there are no awards for the requested week.
- [ ] The season directory and report filename match the requested week.
- [ ] There are no unresolved placeholders, player `@` tags, or database account
      names. Retain the standard role mention in the registration footer.

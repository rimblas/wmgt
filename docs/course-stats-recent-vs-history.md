# Recent Course Stats vs Full History


## What Changed

The risk & difficulty formulas changed from using the full history of a course to using the last 5 played sessions for each course.

## Course Difficulty Rankings
Across 78 courses:

- 60 courses changed position
- 18 courses stayed in the same spot

Biggest moves up in the recent view:

- `BBE` Bogey's Bonanza: `32 -> 17` (`+15`)
- `AMH` Arizona Modern Hard: `61 -> 50` (`+11`)
- `20H` 20,000 Leagues Hard: `62 -> 55` (`+7`)
- `AME` Arizona Modern: `24 -> 19` (`+5`)
- `CBE` Cherry Blossom: `20 -> 16` (`+4`)

Biggest moves down in the recent view:

- `HWH` Hollywood Hard: `53 -> 57` (`-4`)
- `LLE` Laser Lair: `19 -> 23` (`-4`)
- `TOE` Tokyo: `16 -> 20` (`-4`)
- `ELE` Viva Las Elvis: `21 -> 24` (`-3`)
- `HHE` Holiday Hideaway: `18 -> 21` (`-3`)

Top 10 impact:

- Entered the top 10: `QVE`, `TCE`, `HWE`
- Dropped out of the top 10: `20E`, `VNE`, `MWE`
- New top 5: `OGE`, `TTE`, `QVE`, `SSE`, `MWE`

## Hardest Holes
Comparing the top 15 hardest holes:

- 13 holes stayed in the top 15
- `8BH #16` entered the top 15
- `CBH #17` dropped out

Biggest moves up:

- `CBH #10`: `12 -> 7` (`+5`)
- `EDH #18`: `13 -> 10` (`+3`)
- `JCH #12`: `14 -> 11` (`+3`)
- `ATH #18`: `4 -> 2` (`+2`)

Biggest moves down:

- `TTH #18`: `5 -> 14` (`-9`)
- `SLH #18`: `9 -> 12` (`-3`)
- `BBH #18`: `2 -> 4` (`-2`)

New top 5 hardest holes:

1. `CBH #18`
2. `ATH #18`
3. `FFH #15`
4. `BBH #18`
5. `LBE #18`

## Easiest Holes
Comparing the top 15 easiest holes:

- 13 holes stayed in the top 15
- Entered the top 15: `OGE #5`, `OGE #9`
- Dropped out: `QVE #11`, `CBE #13`

Biggest moves up:

- `TTE #12`: `14 -> 3` (`+11`)
- `TCE #18`: `13 -> 10` (`+3`)
- `QVE #8`: `11 -> 9` (`+2`)
- `AME #2`: `5 -> 4` (`+1`)

Biggest moves down:

- `WGE #1`: `4 -> 11` (`-7`)
- `HWE #8`: `8 -> 12` (`-4`)
- `ILE #5`: `9 -> 13` (`-4`)
- `MGE #3`: `10 -> 14` (`-4`)
- `OGE #14`: `3 -> 6` (`-3`)

Top 5 easiest holes in the recent view:

1. `MWE #9`
2. `ATE #1`
3. `TTE #12`
4. `AME #2`
5. `OGE #5`



## What Changed (Tech Details)
This compares `wmg_course_stats_recent_v` against `wmg_course_stats_v` using the `STDDEV` formula only.

`wmg_course_stats_recent_v` uses the last 5 played sessions for each course, based on `wmg_tournament_courses` joined to `wmg_tournament_sessions.session_date`, then ties those sessions back to round history by `week`.

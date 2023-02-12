# wmgt

Analysis Application for the [Walkabout Mini Golf](https://www.mightycoconut.com/minigolf) VR game weekly tournaments. 
(_However, it would work fairly well for any individual play golf round analysis_).

[Live site on OCI](https://rimblas.com/wmgt)

## Tech Details

### Basic Data Model Structure

```
tournaments
  tournament_sessions
    tournament_courses
    tournament_players

courses
    course_strokes
players
    rounds
```

Helper core views:

  * `wmg_courses_v`: All information about a course; name, par per hole and course par.
  * `wmg_rounds_v`: All information about a player's round; player, course, course par, strokes per hole, under par per hole, and totals for strokes and under par.
  * `wmg_rounds_unpivot_mv`: Materialize view thst unpivots one row per hole
  
### Naming convention

`CS[1-18]` or `H[1-18]`: Par on a course hole (Course strokes per hole).<br>
`S[1-18]`: Strokes per hole<br>
`PAR[1-18]`: Player under par score per hole<br>



### WMG_ROUND & WMG_ROUND_V

The `WMG_ROUND_V` view contains just about everything you might need about a player's round.


| : Column :            | Description                                                     |
| --------------------- | --------------------------------------------------------------- |
| `S[1-18]`             | Strokes taken per hole (1, 2, 3, ...)                           |
| `ROUND_STROKES`       | Sum of `S[1-18]`                                                |
| `PAR[1-18]`           | Under par score per hole                                        |
| `UNDER_PAR`           | Sum of `PAR[1-18]` unless an override is in place               |
| `FINAL_SCORE`         | Under par score entered by player. It may not match `UNDER_PAR` |
| `SCORE_OVERRIDE_FLAG` | Y is an override score is in place                              |


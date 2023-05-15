# WMGT - Walkabout Mini Golf Tournament app

Application for running and analysising the weekly [Walkabout Mini Golf](https://www.mightycoconut.com/minigolf) VR game tournaments. 


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

### WMG_ROUNDS_UNPIVOT_MV

This Materialize View is a little gem that transforms wmg_rounds (where one row is a complete round with holes 1,2,3,4...18 are columns) to hole 1,2,3,5...18 into rows

If I describe it it looks like this:

```

NAME         DATA TYPE           NULL  DEFAULT    COMMENTS
------------ ------------------- ----- ---------- --------------------------------
 WEEK        VARCHAR2(10 BYTE)   Yes
 COURSE_ID   NUMBER              Yes
 PLAYER_ID   NUMBER              Yes
 H           NUMBER              Yes              Hole being playes 1-18
 SCORE       NUMBER              Yes              Strokes taken by the player
 PAR         NUMBER              Yes              The under par value for a hole.
 ```


### Assets

The Application Property `BUCKET` is used to access static files like course previews. There's a `wmgt-asset` bucket setup in the OCI Object Storage that's currently holding several of these assets.

The following blog post was extremly helpful for setting this up:
http://blog.osdev.org/oci/2020/10/15/oci-objectstorage-website.html



create or replace view wmg_tournament_results_v
as
select week
     , rank() over (partition by week order by easy_par + hard_par) pos
     , player_id
     , player_name
     , easy_round_id
     , hard_round_id
     , easy_par
     , hard_par
     , total_score
     , easy_scorecard
     , hard_scorecard
     , total_scorecard
from (
  select week
  , player_id 
  , player_name
  , easy_round_id
  , hard_round_id
  , easy_par
  , hard_par
  , easy_par + hard_par total_score
  , easy_scorecard
  , hard_scorecard
  , easy_scorecard + hard_scorecard total_scorecard
  from (
    select r.week
         , r.player_id
         , r.player_name
         , r.under_par
         , r.scorecard_total
         , c.course_mode
         , r.round_id
      from wmg_rounds_v r, wmg_courses c
    where r.course_id = c.id
    )
   pivot (
    sum(under_par) par, sum(scorecard_total) scorecard, max(round_id) round_id for course_mode in (
      'E' EASY, 'H' HARD
     )
    )
)
/
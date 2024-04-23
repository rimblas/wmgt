create or replace view wmg_tournament_results_v
as
select week
     , rank() over (partition by week order by easy_par + hard_par) pos
     , player_id
     , player_name
     , easy_round_id
     , hard_round_id
     , round_created_on
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
  , greatest(easy_created_on, hard_created_on) round_created_on
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
         , tc.course_no
         , r.round_id
         , r.created_on
      from wmg_rounds_v r
         , wmg_courses c
         , wmg_tournament_courses tc
    where r.course_id = c.id
      and tc.course_id = c.id
      and tc.tournament_session_id = r.tournament_session_id
    )
   pivot (
      sum(under_par) par, sum(scorecard_total) scorecard
    , max(round_id) round_id 
    , max(created_on) created_on 
    for course_mode in (
      1 EASY, 2 HARD
     )
    )
)
/
create or replace view wmg_tournament_session_points_v
as
select r.week, r.player_id, r.player_name, r.country_code, r.easy, r.hard, r.total_score
     , r.pos
     , r.percent_rank
     , wmg_util.score_points(r.pos, r.percent_rank, r.player_count) points
from (
select r.week, r.player_id, r.player_name, r.country_code, r.easy, r.hard, r.total_score, r.pos
 , percent_rank() over (partition by case when r.pos <= 10 then 1 else 2 end order by r.total_score ) percent_rank
 , player_count
from (
    select r.week, r.player_id, r.player_name, r.country_code, r.easy, r.hard, r.total_score
         , rank() over (partition by r.week order by r.total_score) pos
         , count(*) over (partition by r.week) player_count
    from (
      select week, player_id, player_name, country_code, easy, hard, easy + hard total_score
      from (
        select r.week
             , r.player_id, r.player_name, r.country_code
             , r.under_par
             , c.course_mode
          from wmg_rounds_v r
             , wmg_courses c
        where r.course_id = c.id
        )
       pivot (
         sum(under_par) for course_mode in (
          'E' EASY, 'H' HARD
         )
        )
    ) r
  ) r
) r
order by r.week, r.pos, r.player_name
/
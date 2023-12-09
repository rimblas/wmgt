create or replace view wmg_tournament_session_points_v
as
with rounds as (
    select r.week
         , r.player_id
         , r.easy, r.hard, r.total_score
         , r.easy_course_id, r.hard_course_id
         , r.easy_round_id, r.hard_round_id
         , rank() over (partition by r.week order by r.total_score) pos
         , count(*) over (partition by r.week) player_count
    from (
        select week, player_id, easy, hard, nvl(easy + hard, 99) total_score
             , easy_round_id, hard_round_id
             , easy_course_id, hard_course_id
       from (
          select r.week
               , r.player_id
               , r.under_par
               , c.course_mode
               , r.round_id
               , r.course_id
            from wmg_rounds_v r
               , wmg_courses c
          where r.course_id = c.id
          )
         pivot (
             sum(under_par), any_value(round_id) round_id, any_value(course_id) course_id for course_mode in (
              'E' EASY, 'H' HARD
             )
          )
      ) r
)
, results as (
  select p.tournament_session_id
       , p.week
       , r.player_id, p.account
       , p.player_name, p.country_code
       , p.rank_code
       , r.easy_course_id, r.hard_course_id
       , r.easy, r.hard
       , r.easy_round_id, r.hard_round_id
       , r.total_score, r.pos
       , player_count
  from rounds r
     , wmg_tournament_player_v p
  where p.week = r.week
   and p.player_id = r.player_id
   and p.active_ind = 'Y'
)
, rank_split as (
  select r.*
       , 0 percent_rank
    from results r
   where r.pos <= 10
  union all 
  /* We need the percent_rank to only consider the players after the top 10 */
  select r.*
       , percent_rank() over (partition by r.tournament_session_id order by r.total_score nulls first ) percent_rank
    from results r
   where r.pos > 10
)
select ts.id tournament_session_id
     , r.week, r.player_id, r.player_name, r.account, r.country_code
     , r.rank_code
     , r.easy_course_id, r.hard_course_id
     , r.easy, r.hard, r.total_score
     , r.easy_round_id, r.hard_round_id
     , r.pos
     , r.percent_rank
     , decode(r.total_score, 99, 0, wmg_util.score_points(r.pos, r.percent_rank, r.player_count)) points
     -- , wmg_util.score_points(r.pos, r.percent_rank, r.player_count) points
     , ts.completed_ind
 from rank_split r
    , wmg_tournament_sessions ts
where ts.id = r.tournament_session_id
  and ts.week = r.week
order by r.week, r.pos, r.player_name
/
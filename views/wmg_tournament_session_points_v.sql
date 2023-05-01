create or replace view wmg_tournament_session_points_v
as
with rounds as (
    select r.week
         , r.player_id
         , r.easy, r.hard, r.total_score
         , rank() over (partition by r.week order by r.total_score) pos
         , count(*) over (partition by r.week) player_count
    from (
        select week, player_id, easy, hard, nvl(easy + hard, 99) total_score
        from (
          select r.week
               , r.player_id
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
)
, results as (
  select p.tournament_session_id
       , p.week
       , r.player_id
       , p.player_name, p.country_code
       , p.rank_code
       , r.easy, r.hard
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
     , r.week, r.player_id, r.player_name, r.country_code
     , r.rank_code
     , r.easy, r.hard, r.total_score
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
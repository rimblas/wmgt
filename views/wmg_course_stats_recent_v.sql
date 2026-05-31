create or replace view wmg_course_stats_recent_v
as
with recent_course_plays as (
   select course_id
        , week
        , session_date
        , dense_rank() over (
             partition by course_id
             order by session_date desc, week desc
          ) play_rank
     from (
          select distinct
                 tc.course_id
               , ts.week
               , ts.session_date
           from wmg_tournament_courses tc
               , wmg_tournament_sessions ts
           where ts.id = tc.tournament_session_id
             and ts.session_date <= trunc(sysdate) + 1
     )
)
, recent_rounds as (
   select u.course_id
        , u.h
        , u.par
        , u.score
     from wmg_rounds_unpivot_mv u
        , recent_course_plays r
    where u.course_id = r.course_id
      and u.week = r.week
      and u.player_id != 0
      and r.play_rank <= 5
)
, stats as (
   select course_id
        , h
        , round(avg(par), 3) par_avg
        , round(stddev(par), 3) std_dev
        , round(variance(par), 3) std_dev_var
        , round(avg(score), 3) score_avg
        , round(stddev(score), 2) score_std_dev
        , count(*) entries
     from recent_rounds
    group by course_id, h
)
, strokes as (
   select *
     from wmg_course_strokes
   unpivot (
      (par) for h in (
      (h1) as 1,
      (h2) as 2,
      (h3) as 3,
      (h4) as 4,
      (h5) as 5,
      (h6) as 6,
      (h7) as 7,
      (h8) as 8,
      (h9) as 9,
      (h10) as 10,
      (h11) as 11,
      (h12) as 12,
      (h13) as 13,
      (h14) as 14,
      (h15) as 15,
      (h16) as 16,
      (h17) as 17,
      (h18) as 18
      )
    )
)
select c.id course_id
     , c.code course_code
     , st.h
     , st.std_dev
     , st.std_dev_var
     , st.score_avg
     , st.score_std_dev difficulty
     , st.entries
  from stats st
     , strokes s
     , wmg_courses c
 where st.h = s.h
   and st.course_id = s.course_id
   and s.course_id = c.id
/

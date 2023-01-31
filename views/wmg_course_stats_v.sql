create or replace view wmg_course_stats_v
as
with stats as (
   select course_id
        , h
        , round(avg(par),3) par_avg, round(stddev(par),3) std_dev, round(variance(par),3) std_dev_var
        , round(avg(score),3) score_avg, round(stddev(score),2) score_std_dev
        , count(*) entries
   from  wmg_rounds_unpivot_mv
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
from  stats st, strokes s
   , wmg_courses c
where st.h = s.h
  and st.course_id = s.course_id
  and s.course_id = c.id
/

create or replace view wmg_courses_v 
as
with w_course_best as (
select course_id
     -- , sum(s) best_strokes
     , sum(min_par) best_under
  from (
    select course_id
         , h
         -- , min(score)  s
         , min(par) min_par
    from wmg_rounds_unpivot_mv
   where player_id != 0  -- remove the curated system score
   group by course_id,  h
   )
 group by course_id
)
select 
    c.id                                         course_id,
    c.release_order,
    c.code                                       code,
    c.name                                       name,
    c.code || ' - ' || c.name prepared_name,
    c.course_mode                                course_mode,
    cs.id                                  course_stroke_id,
    cs.h1,
    cs.h2,
    cs.h3,
    cs.h4,
    cs.h5,
    cs.h6,
    cs.h7,
    cs.h8,
    cs.h9,
    cs.h10,
    cs.h11,
    cs.h12,
    cs.h13,
    cs.h14,
    cs.h15,
    cs.h16,
    cs.h17,
    cs.h18,
    cs.h1+ cs.h2+ cs.h3+ cs.h4+ cs.h5+ cs.h6+ cs.h7+ cs.h8+ cs.h9+ cs.h10+ cs.h11+ cs.h12+ cs.h13+ cs.h14+ cs.h15+ cs.h16+ cs.h17+ cs.h18 course_par
  , cb.best_under
from wmg_courses c
   , wmg_course_strokes cs
   , w_course_best cb
where cs.course_id(+) = c.id
  and cb.course_id(+) = c.id
/

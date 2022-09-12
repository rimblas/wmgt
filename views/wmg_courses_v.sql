create or replace view wmg_courses_v 
AS 
  select 
    c.id                                         course_id,
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
from 
    courses c,
    course_strokes cs
where
    cs.course_id(+) = c.id
/

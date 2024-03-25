create table course_strokes
as
select c.code course_code
     , cs.course_id
     , cs.h1
     , cs.h2
     , cs.h3
     , cs.h4
     , cs.h5
     , cs.h6
     , cs.h7
     , cs.h8
     , cs.h9
     , cs.h10
     , cs.h11
     , cs.h12
     , cs.h13
     , cs.h14
     , cs.h15
     , cs.h16
     , cs.h17
     , cs.h18
from wmg_courses c
    , wmg_course_strokes cs
where c.id = cs.course_id
/
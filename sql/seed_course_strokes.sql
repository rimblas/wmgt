insert into wmg_course_strokes (
       course_id
     , h1
     , h2
     , h3
     , h4
     , h5
     , h6
     , h7
     , h8
     , h9
     , h10
     , h11
     , h12
     , h13
     , h14
     , h15
     , h16
     , h17
     , h18
)
select c.id
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
    , course_strokes_tmp cs
where c.code = cs.course_code
/
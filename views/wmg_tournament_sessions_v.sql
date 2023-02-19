create or replace view wmg_tournament_sessions_v
as 
with courses as (
    select tc.tournament_session_id
         , c.id course_id
         , c.course_mode
         , c.code
    from wmg_tournament_courses tc
       , wmg_courses c
   where tc.course_id = c.id (+)
)
select t.id                              tournament_id
     , t.code                            code
     , t.name                            name
     , t.prefix_tournament               prefix_tournament
     , t.prefix_session                  prefix_session
     , t.url                             url
     , t.notes                           notes
     , t.active_ind                      active_ind
     , ts.id                             tournament_session_id
     , ts.round_num                      round_num
     , ts.session_date                   session_date
     , ts.week                           week
     , ts.open_registration_on           open_registration_on
     , ts.close_registration_on          close_registration_on
     , ts.registration_closed_flag
     , ts.rooms_open_flag
     , ts.rooms_defined_flag
     , ts.rooms_defined_by
     , ts.rooms_defined_on
     , ts.completed_ind                  completed_ind
     , ts.completed_on                   completed_on
     , e.course_id                       easy_course_id
     , e.code                            easy_course_code
     , h.course_id                       hard_course_id
     , h.code                            hard_course_code
from wmg_tournaments t
   , wmg_tournament_sessions ts
   , courses e
   , courses h
where ts.tournament_id(+) = t.id
--  and tc.tournament_session_id(+) = ts.id
  and ts.id = e.tournament_session_id (+)
  and e.course_mode (+) = 'E'
  and ts.id = h.tournament_session_id (+)
  and h.course_mode (+) = 'H'
/

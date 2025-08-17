create or replace view wmg_course_vote_v
as
select v.id vote_id
     , v.player_id, p.player_name
     , c.id, course_id, c.code course_code, c.name course, c.course_mode
     , v.vote
from wmg_course_vote v
   , wmg_courses c
   , wmg_players_v p
where v.course_id = c.id
  and v.player_id = p.id
/

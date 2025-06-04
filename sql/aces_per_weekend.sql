select c.prepared_name course, a.week, a.aces, a.players
from wmg_courses_v c
   , (
select week, course_id, count(*) aces
, (
select count(distinct p.player_id)
from wmg_tournament_players p
   , wmg_tournament_sessions ts
where p.tournament_session_id = ts.id
and ts.week = u.week
) players
from wmg_rounds_unpivot_mv u
where score = 1
  and week != 'S00W00'
group by week, course_id
) a
where a.course_id = c.course_id
order by a.aces 
/

create or replace view wmg_under50_club_v
as
select s.tournament_id
     , s.week
     , s.session_date
     , p.player_id
     , p.player_name
     , s.easy_course_code, p.easy, p.easy_course_id
     , s.hard_course_code, p.hard, p.hard_course_id
     , p.total_score
from wmg_tournament_sessions_v s
   , wmg_tournament_players tp
   , wmg_tournament_session_points_v p
where s.tournament_session_id = tp.tournament_session_id
  and tp.tournament_session_id = p.tournament_session_id
  and tp.player_id = p.player_id
  and tp.points >= 11
  and p.total_score <= -50
--  and tp.tournament_session_id = 1382
order by p.total_score, s.session_date
/

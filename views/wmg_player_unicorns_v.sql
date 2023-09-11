create or replace view wmg_player_unicorns_v
as
select u.id
     , u.course_id
     , c.release_order course_release_order
     , c.name course_name
     , c.course_mode
     , c.prepared_name course_prepared_name
     , u.player_id
     , p.player_name
     , u.h
     , u.attempt_count
     , u.score_tournament_session_id
     , tss.week         score_week
     , tss.session_date score_session_date
     , u.award_tournament_session_id
     , tsa.week         award_week
     , tsa.session_date award_session_date
     , u.repeat_count
     , u.created_on
     , u.created_by
     , u.updated_on
     , u.updated_by
from wmg_player_unicorns u
 join wmg_courses_v c on c.course_id = u.course_id
 join wmg_players_v p on p.id = u.player_id
 join wmg_tournament_sessions tss on tss.id = u.score_tournament_session_id
 join wmg_tournament_sessions tsa on tsa.id = u.award_tournament_session_id
/


var G_CURRENT_SESSION_ID number;

begin
:G_CURRENT_SESSION_ID := 1622;
wmg_util.assign_rooms(:G_CURRENT_SESSION_ID);
end;
/

var G_CURRENT_SESSION_ID number;

begin
:G_CURRENT_SESSION_ID := 1622;
update wmg_tournament_sessions
   set rooms_open_flag = decode(rooms_open_flag, 'Y', null, 'Y')
     , registration_closed_flag = decode(registration_closed_flag, 'Y', null, 'Y')
where id = :G_CURRENT_SESSION_ID;

commit;  -- Make sure the room open up regardless or other errors

wmg_util.submit_close_scoring_jobs(p_tournament_session_id => :G_CURRENT_SESSION_ID);

end;
/

create or replace package wmg_rest_api
is

--------------------------------------------------------------------------------
--*
--* REST API Response Package for WMGT Discord Bot
--* Centralizes JSON response generation for API endpoints
--*
--------------------------------------------------------------------------------

-- Error codes constants
c_error_player_not_found     constant varchar2(30) := 'PLAYER_NOT_FOUND';
c_error_session_not_found    constant varchar2(30) := 'SESSION_NOT_FOUND';
c_error_registration_closed  constant varchar2(30) := 'REGISTRATION_CLOSED';
c_error_already_registered   constant varchar2(30) := 'ALREADY_REGISTERED';
c_error_invalid_time_slot    constant varchar2(30) := 'INVALID_TIME_SLOT';
c_error_registration_failed  constant varchar2(30) := 'REGISTRATION_FAILED';
c_error_unregistration_failed constant varchar2(30) := 'UNREGISTRATION_FAILED';
c_error_not_registered       constant varchar2(30) := 'NOT_REGISTERED';
c_error_timezone_update_failed constant varchar2(30) := 'TIMEZONE_UPDATE_FAILED';
c_error_no_active_tournament_session constant varchar2(30) := 'NO_ACTIVE_TOURNAMENT_SESSION';
c_error_invalid_tournament_session   constant varchar2(30) := 'INVALID_TOURNAMENT_SESSION';


--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

function format_session_date_utc(
    p_date in date
  , p_time_slot in varchar2 default '00:00'
) return varchar2;

function convert_session_date_utc(
    p_date in date
  , p_time_slot in varchar2 default '00:00'
) return  timestamp with time zone;

function format_session_date_local(
    p_date in date
  , p_time_slot in varchar2
  , p_timezone in varchar2
) return varchar2;

function format_session_date_epoch(
    p_date in date
  , p_time_slot in varchar2
) return number;

function build_room_players_json(
    p_tournament_session_id in wmg_tournament_sessions.id%type
  , p_room_no               in wmg_tournament_players.room_no%type
) return clob;

function build_courses_json(p_session_id in number) return clob;

--------------------------------------------------------------------------------
-- Response generation procedures
--------------------------------------------------------------------------------

procedure current_tournament(
  p_tournament_type_code in wmg_tournament_control.tournament_type_code%type default 'WMGT'
);

procedure success_response(
    p_message in varchar2
  , p_data in clob default null
);

procedure error_response(
    p_error_code in varchar2
  , p_message in varchar2
);

procedure player_registrations(
    p_discord_id in varchar2
);

procedure handle_registration(
    p_body in clob
);


end wmg_rest_api;
/
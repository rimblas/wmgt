
--------------------------------------------------------
--  DDL for Trigger WMG_BADGE_TYPES_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_BADGE_TYPES_BU" 
    before update 
    on wmg_badge_types
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_badge_types_bu;

/
ALTER TRIGGER "WMG_BADGE_TYPES_BU" ENABLE;



--------------------------------------------------------
--  DDL for Trigger WMG_COURSES_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_COURSES_BU" 
    before update 
    on wmg_courses
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_courses_bu;

/
ALTER TRIGGER "WMG_COURSES_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_COURSE_PREVIEWS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_COURSE_PREVIEWS_BU" 
    before update 
    on wmg_course_previews
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_course_previews_bu;

/
ALTER TRIGGER "WMG_COURSE_PREVIEWS_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_ISSUES_U
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_ISSUES_U" 
before update
on wmg_issues
referencing old as old new as new
for each row
begin
  if updating then
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    );
  end if;
end;
/
ALTER TRIGGER "WMG_ISSUES_U" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_MESSAGES_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_MESSAGES_BU" 
before update
on wmg_messages
referencing old as old new as new
for each row
begin
  if updating then
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
  end if;
end wmg_messages_bu;

/
ALTER TRIGGER "WMG_MESSAGES_BU" ENABLE;

--------------------------------------------------------
--  DDL for Trigger WMG_NOTES_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_NOTES_BU" 
    before update 
    on wmg_notes
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_notes_bu;
/
ALTER TRIGGER "WMG_NOTES_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_NOTIFICATION_TYPES_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_NOTIFICATION_TYPES_BU" 
    before update 
    on wmg_notification_types
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_notification_types_bu;
/
ALTER TRIGGER "WMG_NOTIFICATION_TYPES_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_PARAMETERS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_PARAMETERS_BU" 
before update
on wmg_parameters
referencing old as old new as new
for each row
begin
  if updating then

    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(
                           sys_context('APEX$SESSION','app_user')
                         , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                         , sys_context('userenv','session_user')
                       );
  end if;
end;

/
ALTER TRIGGER "WMG_PARAMETERS_BU" ENABLE;



--------------------------------------------------------
--  DDL for Trigger WMG_PLAYERS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_PLAYERS_BU" 
    before update 
    on wmg_players
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_players_bu;

/
ALTER TRIGGER "WMG_PLAYERS_BU" ENABLE;

--------------------------------------------------------
--  DDL for Trigger WMG_PLAYER_BADGES_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_PLAYER_BADGES_BU" 
    before insert or update 
    on wmg_player_badges
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_player_badges_bu;

/
ALTER TRIGGER "WMG_PLAYER_BADGES_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_PLAYER_UNICORNS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_PLAYER_UNICORNS_BU" 
    before insert or update 
    on wmg_player_unicorns
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_player_unicorns_bu;

/
ALTER TRIGGER "WMG_PLAYER_UNICORNS_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_RANKS_U_TRG
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_RANKS_U_TRG" 
before update
on wmg_ranks
referencing old as old new as new
for each row
begin
  :new.updated_on := sysdate;
  :new.updated_by := coalesce(
                         sys_context('APEX$SESSION','app_user')
                       , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                       , sys_context('userenv','session_user')
                     );
end;

/
ALTER TRIGGER "WMG_RANKS_U_TRG" ENABLE;

--------------------------------------------------------
--  DDL for Trigger WMG_ROUNDS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_ROUNDS_BU" 
    before update 
    on wmg_rounds
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_rounds_bu;

/
ALTER TRIGGER "WMG_ROUNDS_BU" ENABLE;

--------------------------------------------------------
--  DDL for Trigger WMG_STREAMS_U
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_STREAMS_U" 
before update
on wmg_streams
referencing old as old new as new
for each row
begin
  if updating then
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    );
  end if;
end;

/
ALTER TRIGGER "WMG_STREAMS_U" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_TOURNAMENTS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_TOURNAMENTS_BU" 
    before update 
    on wmg_tournaments
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournaments_bu;

/
ALTER TRIGGER "WMG_TOURNAMENTS_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_TOURNAMENT_COURSES_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_TOURNAMENT_COURSES_BU" 
    before update 
    on wmg_tournament_courses
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_courses_bu;

/
ALTER TRIGGER "WMG_TOURNAMENT_COURSES_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_TOURNAMENT_PLAYERS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_TOURNAMENT_PLAYERS_BU" 
    before update 
    on wmg_tournament_players
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_players_bu;

/
ALTER TRIGGER "WMG_TOURNAMENT_PLAYERS_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_TOURNAMENT_ROOMS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_TOURNAMENT_ROOMS_BU" 
    before update 
    on wmg_tournament_rooms
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_rooms_bu;

/
ALTER TRIGGER "WMG_TOURNAMENT_ROOMS_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_TOURNAMENT_SESSIONS_BU
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_TOURNAMENT_SESSIONS_BU" 
    before update 
    on wmg_tournament_sessions
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_sessions_bu;

/
ALTER TRIGGER "WMG_TOURNAMENT_SESSIONS_BU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_VERIFICATION_QUEUE_U
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_VERIFICATION_QUEUE_U" 
before update
on wmg_verification_queue
referencing old as old new as new
for each row
begin
  if updating then
    :new.updated_on := sysdate;
    :new.updated_by := coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    );
  end if;
end;

/
ALTER TRIGGER "WMG_VERIFICATION_QUEUE_U" ENABLE;


--------------------------------------------------------
--  DDL for Trigger WMG_WEBHOOKS_U_TRG
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TRIGGER "WMG_WEBHOOKS_U_TRG" 
before update
on wmg_webhooks
referencing old as old new as new
for each row
begin
  :new.updated_on := sysdate;
  :new.updated_by := coalesce(
                         sys_context('APEX$SESSION','app_user')
                       , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                       , sys_context('userenv','session_user')
                     );
end;

/
ALTER TRIGGER "WMG_WEBHOOKS_U_TRG" ENABLE;




--------------------------------------------------------
--  DDL for Package UC_LIST_EXTENSION
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE "UC_LIST_EXTENSION" as  
   /** 
    * Plug-ins Pro List Extension is an Oracle APEX plug-in designed to improve user experience when adding new values to an existing List of Values (LOV). 
    * Users can quickly and easily add a new value to an existing Select List, Popup LOV, Radio Group, Checkbox, or Shuttle and automatically select the newly created value - all without leaving the page they are working on or losing their place in the application!
    * 
    * <pre>
    * Date        Author        Comment
    * ---------------------------------------------------------------------------------------
    * 08.02.2021  A. Grlica     initial creation
    * 30.04.2021  A. Grlica     IG support v 21.2
    * 
    * </pre>
    * 
    * @headcom
    */
  function render (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_render_result;

  function ajax (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_ajax_result;
end UC_LIST_EXTENSION;
/


--------------------------------------------------------
--  DDL for Package UC_NESTED_REPORTS
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE "UC_NESTED_REPORTS" 
as 
 
  function render_row_details ( 
    p_dynamic_action in apex_plugin.t_dynamic_action, 
    p_plugin         in apex_plugin.t_plugin  
  ) return apex_plugin.t_dynamic_action_render_result; 

  function ajax_row_details( 
    p_dynamic_action in apex_plugin.t_dynamic_action, 
    p_plugin         in apex_plugin.t_plugin  
  ) return apex_plugin.t_dynamic_action_ajax_result; 

end; 
/


--------------------------------------------------------
--  DDL for Package WMG_DISCORD
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE "WMG_DISCORD" 
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------


function avatar(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null)
return varchar2;

function avatar_link(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null
  , p_size_class in varchar2 default 'md')
return varchar2;

--------------------------------------------------------------------------------

function render_profile(
    p_player_id  in wmg_players.id%type
  , p_mode       in varchar2             default 'FULL'
  , p_spacing    in varchar2             default 'FULL'
)
return varchar2;

procedure merge_players(
    p_from_player_id  in wmg_players.id%type
  , p_into_player_id  in wmg_players.id%type
  , p_remove_from_player in boolean default true
);

end wmg_discord;
/



--------------------------------------------------------
--  DDL for Package WMG_ERROR_HANDLER
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE "WMG_ERROR_HANDLER" 
AS


/*
 * Use with:
 * wmg_error_handler.error_handler_logging_session
 *
 */

FUNCTION error_handler_logging_session(
    p_error IN apex_error.t_error )
  RETURN apex_error.t_error_result;
    --============================================================================
  -- F O R C E   P L / S Q L   E R R O R   
  --============================================================================
PROCEDURE force_plsql_error;
END wmg_error_handler;
/



--------------------------------------------------------
--  DDL for Package WMG_NOTIFICATION
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE "WMG_NOTIFICATION" 
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------


procedure send_to_discord_webhook(
    p_webhook_code    in wmg_webhooks.code%type
  , p_content         in clob
  , p_embeds          in clob default null
  , p_user_name       in wmg_players.account%type default null
);

--------------------------------------------------------------------------------

procedure new_player(
    p_player_id       in wmg_players.id%type
  , p_registration_id in wmg_tournament_players.id%type default null
);

procedure notify_first_timeslot_finish(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , p_player_id       in wmg_players.id%type
);
procedure notify_channel_about_players(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , p_time_slot              in wmg_tournament_players.time_slot%type
);

procedure notify_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);

procedure notify_new_courses(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);

procedure tournament_recap_template(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , x_out                    out clob
);

procedure tournament_issues_template(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , x_out                    out clob
);

procedure tournament_courses_template(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , x_out                    out clob
);

end wmg_notification;
/


--------------------------------------------------------
--  DDL for Package WMG_UTIL
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE "WMG_UTIL" 
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------

e_not_current_tournament constant number := -20000;
e_not_correct_session    constant number := -20001;

g_must_be_current  boolean := true;


type rec_keyval_type is record(
    key      varchar2(10)
  , val      varchar2(250)
);

type tab_keyval_type is table of rec_keyval_type;


function rooms_set(p_tournament_session_id in wmg_tournament_sessions.id%type )
   return varchar2;

--------------------------------------------------------------------------------
function get_param(
  p_name_key  in wmg_parameters.name_key%TYPE
)
return varchar2;

--------------------------------------------------------------------------------
procedure set_param(
    p_name_key  in wmg_parameters.name_key%TYPE
  , p_value     in wmg_parameters.value%TYPE
);

--------------------------------------------------------------------------------
function extract_hole_from_file(p_filename in varchar2) return number;

--------------------------------------------------------------------------------
procedure assign_rooms(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);

procedure reset_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);


procedure possible_player_match (
    p_discord_account in wmg_players.account%type
  , p_discord_name    in wmg_players.name%type
  , p_discord_id      in wmg_players.discord_id%type
  , x_players_tbl     in out nocopy tab_keyval_type
);

procedure snapshot_badges (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
);

procedure close_tournament_session (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
);

function is_season_over(
   p_tournament_session_id in wmg_tournament_sessions.id%type
)
return boolean;

function score_points(
    p_rank         in number
  , p_percent_rank in number
  , p_player_count in number
)
return number;

--------------------------------------------------------------------------------
procedure score_entry_verification(
   p_week      in wmg_rounds.week%type
 , p_player_id in wmg_players.id%type
 , p_course_id in number default null
 , p_remove    in boolean default false
);

procedure set_verification_issue(
   p_player_id  in wmg_players.id%type
 , p_issue_code in varchar2 default null
 , p_operation  in varchar2 default null  -- (S)et | (C)lear
 , p_from_ajax  in boolean default true
);

procedure verify_players_room(
   p_tournament_player_id  in wmg_tournament_players.id%type
);

--------------------------------------------------------------------------------
procedure close_time_slot_time_entry (
    p_tournament_session_id in wmg_tournament_sessions.id%type
  , p_time_slot             in wmg_tournament_players.time_slot%type
);


procedure submit_close_scoring_jobs(
    p_tournament_session_id in wmg_tournament_sessions.id%type
);

----------------------------------------
procedure add_unicorns(
    p_tournament_session_id in wmg_tournament_sessions.id%type
);


procedure unavailable_application (p_message in varchar2 default null);

end wmg_util;
/




--------------------------------------------------------
--  DDL for Package Body UC_LIST_EXTENSION
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "UC_LIST_EXTENSION" as   
   /** 
    * Plug-ins Pro List Extension is an Oracle APEX plug-in designed to improve user experience when adding new values to an existing List of Values (LOV). 
    * Users can quickly and easily add a new value to an existing Select List, Popup LOV, Radio Group, Checkbox, or Shuttle and automatically select the newly created value - all without leaving the page they are working on or losing their place in the application!
    * 
    * <pre>
    * Date        Author        Comment
    * ---------------------------------------------------------------------------------------
    * 08.02.2021  A. Grlica     initial creation
    * 30.04.2021  A. Grlica     IG support v 21.2
    * 
    * </pre>
    * 
    * @headcom
    */

c_version    constant varchar2(15 char) := '21.2.0.0';
c_log_prefix constant varchar2(30 char) := 'UC LISTEXTENSION >';
l_item     apex_application_page_items%rowtype;
l_column   apex_appl_page_ig_columns%rowtype;
l_lov      apex_application_lovs%rowtype;
procedure set_page_item(p_item_name in apex_application_page_items.item_name%type)
is
begin
    select *
        into l_item
        from apex_application_page_items
        where application_id = v('APP_ID')
        and item_name = upper(p_item_name);
exception
    when no_data_found then
        apex_debug.error('%s Item Parameter "%s" it''s not valid Page item!', c_log_prefix, upper(p_item_name));
        raise_application_error(-20001, c_log_prefix||' Item Parameter "'||upper(p_item_name)||'" it''s not valid Page item!');
end;
procedure set_grid_column(p_static_id   in apex_application_page_regions.static_id%type,
                          p_column_name in apex_appl_page_ig_columns.name%type)
is
begin
    select col.* 
      into l_column
      from apex_appl_page_igs ig
           inner join apex_application_page_regions reg  on (reg.region_id = ig.region_id)
           inner join apex_appl_page_ig_columns col on (col.region_id = ig.region_id)
     where ig.application_id = v('APP_ID')
       and ig.page_id = v('APP_PAGE_ID')
       and reg.static_id = p_static_id
       and col.name = upper(p_column_name);
exception
    when no_data_found then
        apex_debug.error('%s Interactive Grid with static id "%s" and column name "%s" do not exist, please check settings!', c_log_prefix, p_static_id, upper(p_column_name));
        raise_application_error(-20001, c_log_prefix||' Interactive Grid with static id "'||p_static_id||'" and column name "'||upper(p_column_name)||'" do not exist, please check settings!');
end;
procedure set_lov
is
begin
    if l_item.item_id is not null 
    then
        select *
            into l_lov
            from apex_application_lovs
            where application_id = v('APP_ID')
            and list_of_values_name = l_item.lov_named_lov;
    else 
        select *
            into l_lov
            from apex_application_lovs
            where application_id = v('APP_ID')
            and lov_id = l_column.lov_id;
    end if;
exception
    when no_data_found then
        apex_debug.error('%s LOV load "%s" problem!', c_log_prefix, l_item.lov_named_lov);
        raise_application_error(-20002, c_log_prefix||' LOV load "'||l_item.lov_named_lov||'" problem!');
end;
function render (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_render_result
is
    l_result apex_plugin.t_dynamic_action_render_result;
    l_ajax_needed boolean := false;

begin
    if apex_application.g_debug 
    then
        apex_debug.message('%s rendering started : version - %s', c_log_prefix, c_version);
        apex_plugin_util.debug_dynamic_action (
            p_plugin         => p_plugin,
            p_dynamic_action => p_dynamic_action );
    end if;
    if p_dynamic_action.attribute_05 = 'PI'
    then
        set_page_item(p_dynamic_action.attribute_01);
        if l_item.display_as_code not in ('NATIVE_CHECKBOX', 'NATIVE_POPUP_LOV', 'NATIVE_RADIOGROUP', 'NATIVE_SELECT_LIST', 'NATIVE_SHUTTLE')
        then
                apex_debug.error('%s Item error "%s", item must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.', c_log_prefix, upper(p_dynamic_action.attribute_01));
                raise_application_error(-20003, c_log_prefix||' Item error "'||upper(p_dynamic_action.attribute_01)||'", item must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.');       
        end if;
        if l_item.lov_named_lov is null and l_item.display_as_code like 'NATIVE_POPUP_LOV'
        then
                apex_debug.error('%s Item "%s" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").', c_log_prefix, upper(p_dynamic_action.attribute_01));
                raise_application_error(-20004, c_log_prefix||' Item "'||upper(p_dynamic_action.attribute_01)||'" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").');    
        elsif l_item.lov_named_lov is not null
        then
            set_lov;
        end if;
        if l_item.display_as_code  = 'NATIVE_POPUP_LOV'
        then
            l_ajax_needed := true;
        end if;

    else -- Interactive grid
        set_grid_column(p_static_id   => p_dynamic_action.attribute_06,
                        p_column_name => p_dynamic_action.attribute_07);

        if l_column.item_type not in ('NATIVE_CHECKBOX', 'NATIVE_POPUP_LOV', 'NATIVE_RADIOGROUP', 'NATIVE_SELECT_LIST', 'NATIVE_SHUTTLE')
        then
                apex_debug.error('%s Column type error "%s", column must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.', c_log_prefix, upper(p_dynamic_action.attribute_07));
                raise_application_error(-20005, c_log_prefix||' Item error "'||upper(p_dynamic_action.attribute_07)||'", item must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.');       
        end if;       

        if l_column.lov_type_code not like 'SHARED' and l_column.item_type like 'NATIVE_POPUP_LOV'
        then
                apex_debug.error('%s Column "%s" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").', c_log_prefix, upper(p_dynamic_action.attribute_07));
                raise_application_error(-20006, c_log_prefix||' Column "'||upper(p_dynamic_action.attribute_07)||'" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").');    
        elsif l_column.lov_id is not null
        then
            set_lov;
        end if;        
        if l_column.item_type  = 'NATIVE_POPUP_LOV'
        then
            l_ajax_needed := true;
        end if;

    end if;
    if upper(l_lov.lov_type) = 'STATIC'
    then
        apex_debug.error('%s error Shared LOV "%s" must be dynamic type.', c_log_prefix, l_item.lov_named_lov);
        raise_application_error(-20007, c_log_prefix||' error Shared LOV "'||l_item.lov_named_lov||'" must be dynamic type.');  
    end if;

    l_result.javascript_function := 'uc.ListExtension.init';
    if l_ajax_needed
    then
        l_result.ajax_identifier     := apex_plugin.get_ajax_identifier;
    end if;
    l_result.attribute_01        := p_dynamic_action.attribute_01;
    l_result.attribute_02        := p_dynamic_action.attribute_02;
    l_result.attribute_03        := case when p_dynamic_action.attribute_03 = 'append' then 'true' else 'false' end;
    l_result.attribute_04        := case p_dynamic_action.attribute_04 when 'top' then 'flex-start' when 'center' then 'center' when 'bottom' then 'flex-end' when 'popup-inline' then 'popup-inline' end;
    l_result.attribute_05        := p_dynamic_action.attribute_05;
    l_result.attribute_06        := p_dynamic_action.attribute_06;
    l_result.attribute_07        := p_dynamic_action.attribute_07;
    l_result.attribute_08        := case when p_dynamic_action.attribute_05 = 'IG' then coalesce(l_column.static_id, 'C'||l_column.column_id) else null end;


  return l_result;
end;
function ajax (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_ajax_result
is
    l_context apex_exec.t_context; 
    l_filters apex_exec.t_filters;
    l_idx_display    pls_integer;
    l_idx_return     pls_integer;    
    l_result apex_plugin.t_dynamic_action_ajax_result;
begin
    if p_dynamic_action.attribute_05 = 'PI'
    then
        set_page_item(p_dynamic_action.attribute_01);
    else -- Interactive grid
        set_grid_column(p_static_id   => p_dynamic_action.attribute_06,
                        p_column_name => p_dynamic_action.attribute_07);
    end if;

    set_lov;
    apex_exec.add_filter(
        p_filters     => l_filters,
        p_filter_type => apex_exec.c_filter_eq,
        p_column_name => l_lov.return_column_name,
        p_value       => apex_application.g_x01 );
    l_context := apex_exec.open_query_context(
        p_location          => l_lov.location_code,

        p_table_owner            => l_lov.table_owner,
        p_table_name             => l_lov.table_name,
        p_where_clause           => l_lov.where_clause,   
        p_sql_query              => case when l_lov.source_type_code = 'SQL' then l_lov.list_of_values_query end,
        p_plsql_function_body    => case when l_lov.source_type_code = 'FUNC_BODY_RETURNING_SQL' then l_lov.list_of_values_query end,
        p_optimizer_hint         => l_lov.optimizer_hint,
        p_filters               => l_filters
    );


    l_idx_display    := apex_exec.get_column_position( l_context, l_lov.display_column_name); 
    l_idx_return     := apex_exec.get_column_position( l_context, l_lov.return_column_name); 
    while apex_exec.next_row( l_context ) loop
        apex_json.open_object;
        apex_json.write('id',     apex_exec.get_varchar2( l_context, l_idx_return ));        
        apex_json.write('value',  apex_exec.get_varchar2( l_context, l_idx_display ));
        apex_json.close_object;
    end loop;
    --        
    apex_exec.close( l_context );    
    return l_result;
exception
    when others then
        apex_exec.close( l_context );
        raise;      
end;

end UC_LIST_EXTENSION;
/



--------------------------------------------------------
--  DDL for Package Body UC_NESTED_REPORTS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "UC_NESTED_REPORTS" is 
 
  ------------------------ 
  function printAttributes( 
    p_dynamic_action_render_result in apex_plugin.t_dynamic_action_render_result 
  ) return clob is 
     
  begin 

    apex_json.initialize_clob_output; 

    apex_json.open_object; 
    apex_json.write( 'type', 'apex_plugin.t_dynamic_action_render_result' ); 

    apex_json.write( 'javascript_function'  , p_dynamic_action_render_result.javascript_function  ); 
    apex_json.write( 'ajax_identifier'      , p_dynamic_action_render_result.ajax_identifier  ); 
    apex_json.write( 'attribute_01'         , p_dynamic_action_render_result.attribute_01 ); 
    apex_json.write( 'attribute_02'         , p_dynamic_action_render_result.attribute_02 ); 
    apex_json.write( 'attribute_03'         , p_dynamic_action_render_result.attribute_03 ); 
    apex_json.write( 'attribute_04'         , p_dynamic_action_render_result.attribute_04 ); 
    apex_json.write( 'attribute_05'         , p_dynamic_action_render_result.attribute_05 ); 
    apex_json.write( 'attribute_06'         , p_dynamic_action_render_result.attribute_06 ); 
    apex_json.write( 'attribute_07'         , p_dynamic_action_render_result.attribute_07 ); 
    apex_json.write( 'attribute_08'         , p_dynamic_action_render_result.attribute_08 ); 
    apex_json.write( 'attribute_09'         , p_dynamic_action_render_result.attribute_09 ); 
    apex_json.write( 'attribute_10'         , p_dynamic_action_render_result.attribute_10 ); 
    apex_json.write( 'attribute_11'         , p_dynamic_action_render_result.attribute_11 ); 
    apex_json.write( 'attribute_12'         , p_dynamic_action_render_result.attribute_12 ); 
    apex_json.write( 'attribute_13'         , p_dynamic_action_render_result.attribute_13 ); 
    apex_json.write( 'attribute_14'         , p_dynamic_action_render_result.attribute_14 ); 
    apex_json.write( 'attribute_15'         , p_dynamic_action_render_result.attribute_15 ); 

    apex_json.close_object; 

    return apex_json.get_clob_output; 

  end printAttributes; 


  ------------------------ 
  function printAttributes( 
    p_plugin in apex_plugin.t_plugin 
  ) return clob is 

  begin 

    apex_json.initialize_clob_output; 

    apex_json.open_object; 
    apex_json.write( 'type', 'apex_plugin.t_plugin' ); 

    apex_json.write( 'name'        , p_plugin.name         ); 
    apex_json.write( 'file_prefix' , p_plugin.file_prefix  ); 
    apex_json.write( 'attribute_01', p_plugin.attribute_01 ); 
    apex_json.write( 'attribute_02', p_plugin.attribute_02 ); 
    apex_json.write( 'attribute_03', p_plugin.attribute_03 ); 
    apex_json.write( 'attribute_04', p_plugin.attribute_04 ); 
    apex_json.write( 'attribute_05', p_plugin.attribute_05 ); 
    apex_json.write( 'attribute_06', p_plugin.attribute_06 ); 
    apex_json.write( 'attribute_07', p_plugin.attribute_07 ); 
    apex_json.write( 'attribute_08', p_plugin.attribute_08 ); 
    apex_json.write( 'attribute_09', p_plugin.attribute_09 ); 
    apex_json.write( 'attribute_10', p_plugin.attribute_10 ); 
    apex_json.write( 'attribute_11', p_plugin.attribute_11 ); 
    apex_json.write( 'attribute_12', p_plugin.attribute_12 ); 
    apex_json.write( 'attribute_13', p_plugin.attribute_13 ); 
    apex_json.write( 'attribute_14', p_plugin.attribute_14 ); 
    apex_json.write( 'attribute_15', p_plugin.attribute_15 ); 

    apex_json.close_object; 

    return apex_json.get_clob_output; 

  end printAttributes; 

  ------------------------ 
  function printAttributes( 
    p_dynamic_action in apex_plugin.t_dynamic_action 
  ) return clob is 

  begin 

    apex_json.initialize_clob_output; 

    apex_json.open_object; 
    apex_json.write( 'type', 'apex_plugin.t_dynamic_action' ); 

    apex_json.write( 'id'          , p_dynamic_action.id          , false ); 
    apex_json.write( 'action'      , p_dynamic_action.action      , false ); 
    apex_json.write( 'attribute_01', p_dynamic_action.attribute_01, true ); 
    apex_json.write( 'attribute_02', p_dynamic_action.attribute_02, true ); 
    apex_json.write( 'attribute_03', p_dynamic_action.attribute_03, true ); 
    apex_json.write( 'attribute_04', p_dynamic_action.attribute_04, true ); 
    apex_json.write( 'attribute_05', p_dynamic_action.attribute_05, true ); 
    apex_json.write( 'attribute_06', p_dynamic_action.attribute_06, true ); 
    apex_json.write( 'attribute_07', p_dynamic_action.attribute_07, true ); 
    apex_json.write( 'attribute_08', p_dynamic_action.attribute_08, true ); 
    apex_json.write( 'attribute_09', p_dynamic_action.attribute_09, true ); 
    apex_json.write( 'attribute_10', p_dynamic_action.attribute_10, true ); 
    apex_json.write( 'attribute_11', p_dynamic_action.attribute_11, true ); 
    apex_json.write( 'attribute_12', p_dynamic_action.attribute_12, true ); 
    apex_json.write( 'attribute_13', p_dynamic_action.attribute_13, true ); 
    apex_json.write( 'attribute_14', p_dynamic_action.attribute_14, true ); 
    apex_json.write( 'attribute_15', p_dynamic_action.attribute_15, true ); 

    apex_json.close_object; 

    return apex_json.get_clob_output; 

  end printAttributes; 

  -------------------------------- 
  function getColumnNamesFromQuery( 
    p_string in varchar2 
  ) return clob is 
    v_count   number; 
    v_pattern varchar2(50) := '#.+?#'; 

  begin 
    apex_json.initialize_clob_output; 

    v_count := regexp_count(p_string, v_pattern, 1, 'm'); 

    apex_json.open_object; 
    apex_json.open_array('queryColumns'); 

    for i in 1..v_count loop 
      apex_json.write( trim(both '#' from regexp_substr(p_string, v_pattern, 1, i, 'm') ) ); 
    end loop;   

    apex_json.close_array; 
    apex_json.close_object; 

    return apex_json.get_clob_output; 
  end; 

  ------------------------- 
  function getBindVariables( 
    p_string in varchar2 
  ) return clob is 
    l_names DBMS_SQL.VARCHAR2_TABLE; 
  begin 
    l_names := WWV_FLOW_UTILITIES.GET_BINDS( p_string ); 

    apex_json.initialize_clob_output; 

    apex_json.open_object; 
    apex_json.open_array('queryItems'); 

    for i in 1..l_names.count loop 
      apex_json.write( trim(both ':' from  l_names(i) ) ); 
    end loop;   

    apex_json.close_array; 
    apex_json.close_object; 

    return apex_json.get_clob_output; 

  end getBindVariables; 

  ------------------------------- 
  function getPluginAppAttributes( 
    p_plugin in apex_plugin.t_plugin 
  ) return varchar2 is 
    attr_app_expand_time   number  := NVL(p_plugin.attribute_01, 200); 
    attr_app_collapse_time number  := NVL(p_plugin.attribute_02, 400); 
  begin 
    apex_json.initialize_clob_output; 

    apex_json.open_object; 
    apex_json.open_object('plugin'); 
    apex_json.write('animationTime',      attr_app_expand_time   ); 
    apex_json.write('closeOtherDuration', attr_app_collapse_time ); 
    apex_json.close_object; 
    apex_json.close_object; 

    return apex_json.get_clob_output; 

  end getPluginAppAttributes; 

  ---------------------------- 
  function render_row_details ( 
    p_dynamic_action in apex_plugin.t_dynamic_action, 
    p_plugin         in apex_plugin.t_plugin  
  ) return apex_plugin.t_dynamic_action_render_result 
  is 
    l_result apex_plugin.t_dynamic_action_render_result; 

    l_attr_nestedQuery      varchar2(32767) := p_dynamic_action.attribute_01; 
    l_attr_dc_settings      varchar2(100)   := p_dynamic_action.attribute_02; 

    l_attr_mode             varchar2(100)   := p_dynamic_action.attribute_03; 
    l_attr_customTemplate   varchar2(32767) := p_dynamic_action.attribute_04; 
    l_attr_customCallback   varchar2(32767) := p_dynamic_action.attribute_05; 
    l_attr_bgColor          varchar2(20)    := NVL( p_dynamic_action.attribute_06, '#EBEBEB' ); 
    l_attr_setMaxHeight     number          := p_dynamic_action.attribute_07; 
    l_attr_borderColor      varchar2(20)    := NVL( p_dynamic_action.attribute_08, '#c5c5c5' ); 
    l_attr_highlightColor   varchar2(20)    := NVL( p_dynamic_action.attribute_09, '#F2F2F2' ); 
    l_attr_cc_settings      varchar2(100)   := p_dynamic_action.attribute_10; 
    l_attr_noDataFound      varchar2(32767) := p_dynamic_action.attribute_11; 
    l_attr_spinnerOptions   varchar2(100)   := NVL( p_dynamic_action.attribute_12, 'ATR' ); 
    l_attr_defaultTemplate  varchar2(4000)  := NVL(p_dynamic_action.attribute_13,  '#DEFAULT_TEMPLATE#'); 
    l_attr_dt_settings      varchar2(100)   := p_dynamic_action.attribute_14; 
    /* 
    p_dynamic_action.attribute_12; 
    p_dynamic_action.attribute_13; 
    p_dynamic_action.attribute_14; 
    p_dynamic_action.attribute_15;   
    */ 
    attr_app_embedMustache boolean := CASE WHEN p_plugin.attribute_03 = 'Y' then true else false end; 

  begin 
    l_result.ajax_identifier     := wwv_flow_plugin.get_ajax_identifier; 
    l_result.javascript_function := ' 
      function(){ 
        ucNestedReport(this, '||getColumnNamesFromQuery( l_attr_nestedQuery )||', '||getBindVariables( l_attr_nestedQuery )||', true, '||getPluginAppAttributes( p_plugin )||'); 
      } 
    '; 
    --l_result.attribute_01        := p_dynamic_action.attribute_01; --tajne, bo to zapytaie SQL, ktore mogloby byc dostepne przez this.options 
    l_result.attribute_02        := l_attr_dc_settings; 
    l_result.attribute_03        := l_attr_mode; 
    l_result.attribute_04        := l_attr_customTemplate; 
    l_result.attribute_05        := l_attr_customCallback; 
    l_result.attribute_06        := l_attr_bgColor; 
    l_result.attribute_07        := l_attr_setMaxHeight; 
    l_result.attribute_08        := l_attr_borderColor; 
    l_result.attribute_09        := l_attr_highlightColor; 
    l_result.attribute_10        := l_attr_cc_settings; 
    l_result.attribute_11        := l_attr_noDataFound; 
    l_result.attribute_12        := l_attr_spinnerOptions; 
    l_result.attribute_13        := l_attr_defaultTemplate; 
    l_result.attribute_14        := l_attr_dt_settings; 
    --l_result.attribute_15        := p_dynamic_action.attribute_15; 

    --add mustache library 
    if attr_app_embedMustache then 

      apex_javascript.add_library( 
        p_name => 'mustache',  
        p_directory => p_plugin.file_prefix,  
        p_version => null  
      ); 

    end if; 

    if apex_application.G_DEBUG then 

      APEX_PLUGIN_UTIL.DEBUG_DYNAMIC_ACTION ( 
        p_plugin         => p_plugin, 
        p_dynamic_action => p_dynamic_action 
      ); 

      apex_javascript.add_onload_code (' 
        apex.debug.info("p_dynamic_action", '||printAttributes( p_dynamic_action )||'); 
        apex.debug.info("p_plugin",         '||printAttributes( p_plugin )||'); 
        apex.debug.info("l_result",         '||printAttributes( l_result )||'); 
      '); 

    end if; 

    return l_result; 

  end render_row_details; 

  -------------------- 
  function clean_query(  
    p_query in varchar2  
  ) return varchar2 is 
    l_query varchar2(32767) := p_query; 
  begin 
    loop 
      if substr(l_query,-1) in (chr(10),chr(13),';',' ','/') then 
        l_query := substr(l_query,1,length(l_query)-1); 
      else 
        exit; 
      end if; 
    end loop; 

    return l_query; 

  end clean_query; 

  ----------------------- 
  function is_valid_query(  
    p_query in varchar2  
  ) return varchar2 is 
    l_source_query  varchar2(32767) := p_query; 
    l_source_queryv varchar2(32767); 
    l_report_cursor integer; 
  begin 
    if l_source_query is not null then 
      if  
        substr(upper(ltrim(l_source_query)),1,6) != 'SELECT' 
        and substr(upper(ltrim(l_source_query)),1,4) != 'WITH'  
      then 
        return 'Query must begin with SELECT or WITH'; 
      end if; 

      l_source_query := clean_query( l_source_query ); 
      l_source_queryv := sys.dbms_assert.noop( str => l_source_query ); 

      begin 
        l_report_cursor := sys.dbms_sql.open_cursor; 
        sys.dbms_sql.parse( l_report_cursor, l_source_queryv, SYS.DBMS_SQL.NATIVE ); 
        sys.dbms_sql.close_cursor(l_report_cursor); 
      exception  
        when others then 
          if sys.dbms_sql.is_open( l_report_cursor ) then 
            sys.dbms_sql.close_cursor( l_report_cursor ); 
          end if; 
          return sqlerrm;--||': '||chr(10)||chr(10)||l_source_query; 
      end; 
    end if; 

    return null; 
  exception 
    when others then 
      return SQLERRM;--||':'||chr(10)||chr(10)||p_query; 
  end is_valid_query; 

  ---------------------------- 
  function getColumnTypeString( 
    p_col_type in number 
  ) return varchar2 is  
    l_col_type varchar2(50); 
  begin 
    if p_col_type = 1 then 
      l_col_type := 'VARCHAR2'; 

    elsif p_col_type = 2 then 
      l_col_type := 'NUMBER'; 

    elsif p_col_type = 12 then 
      l_col_type := 'DATE'; 

    elsif p_col_type in (180,181,231) then 
      l_col_type := 'TIMESTAMP'; 

      if p_col_type = 231 then 
          l_col_type := 'TIMESTAMP_LTZ'; 
      end if; 

    elsif p_col_type = 112 then 
      l_col_type := 'CLOB'; 

    elsif p_col_type = 113 then 

      l_col_type := 'BLOB'; 

    elsif p_col_type = 96 then 
      l_col_type := 'CHAR'; 

    else 
        l_col_type := 'OTHER'; 
    end if; 

    return l_col_type; 

  end getColumnTypeString; 

  --------------------------------- 
  function ajax_row_details( 
    p_dynamic_action in apex_plugin.t_dynamic_action, 
    p_plugin         in apex_plugin.t_plugin  
  ) return apex_plugin.t_dynamic_action_ajax_result 
  is 
    l_status              number; 
    l_desc_col_no         number          := 0; 

    l_ajax_column_name    varchar2(4000); 
    l_ajax_column_values  varchar2(4000); 

    l_sql                 varchar2(32767); 
    l_delimeter           varchar2(1)     := ':'; 
    l_parseResult         varchar2(4000); 

    l_result              apex_plugin.t_dynamic_action_ajax_result; 

    l_columnNames         apex_application_global.vc_arr2; 
    l_columnValues        apex_application_global.vc_arr2; 

    l_sys_cursor          sys_refcursor; 

    l_cursor              pls_integer; 

    l_desc_col_info       sys.dbms_sql.desc_tab2; 

    l_apex_items_names    DBMS_SQL.VARCHAR2_TABLE; 
  begin 

    l_ajax_column_name    := apex_application.g_x01; 
    l_ajax_column_values  := apex_application.g_x02; 

    l_sql                 := p_dynamic_action.attribute_01; 
    l_apex_items_names    := WWV_FLOW_UTILITIES.GET_BINDS( l_sql ); 

    l_columnNames         := apex_util.string_to_table( l_ajax_column_name  , l_delimeter ); 
    l_columnValues        := apex_util.string_to_table( l_ajax_column_values, l_delimeter ); 

    if l_columnNames.count <> l_columnValues.count then 
      apex_json.open_object; 
      apex_json.write('addInfo', 'The number of column names must be equal to the number of column values.</br>Check whether the query columns exist in parent report.'); 
      apex_json.write('error', 'Column names = "'||l_ajax_column_name||'"'||chr(10)||'Column values = "'||l_ajax_column_values||'"'); 
      apex_json.close_object; 
      return null;       
    end if; 

    --replacing space within column name is required to work with column aliases 
    for i in 1..l_columnNames.count loop 
      l_sql := replace( l_sql, chr(39)||'#'||l_columnNames(i)||'#'||chr(39) , ':' || replace(l_columnNames(i), ' ', '') );   
      l_sql := replace( l_sql, '#'||l_columnNames(i)||'#'                   , ':' || replace(l_columnNames(i), ' ', '') );   
    end loop; 

    l_parseResult := is_valid_query( l_sql ); 

    if l_parseResult is not null then 
      apex_json.open_object; 
      apex_json.write('addInfo', 'Nested report SQL query is not valid'); 
      apex_json.write('error', l_parseResult); 
      --apex_json.write('query', l_sql); 
      apex_json.close_object; 
      return null; 
    end if; 

    -- open l_cursor; 
    l_cursor := dbms_sql.open_cursor; 
    dbms_sql.parse (l_cursor, l_sql, dbms_sql.native); 

    -- bind items 
    begin 

      for i in 1..l_apex_items_names.count loop 
        dbms_sql.bind_variable (l_cursor, l_apex_items_names(i), v( trim(both ':' from l_apex_items_names(i)) ) ); 
      end loop; 

    exception 
      when others then 
        apex_json.open_object; 
        apex_json.write('addInfo', 'While binding APEX items error occured'); 
        apex_json.write('error', SQLERRM); 
        apex_json.close_object; 
        return null;       
    end; 

    --bind all the values 
    --replacing space within column name is required to work with column aliases 
    begin 
      for i in 1 .. l_columnNames.count loop 
        dbms_sql.bind_variable (l_cursor, replace(l_columnNames(i), ' ', ''), l_columnValues(i)); 
      end loop; 
    exception 
      when others then 
        apex_json.open_object; 
        apex_json.write('addInfo', 'While binding query variables error occured'); 
        apex_json.write('error', SQLERRM); 
        apex_json.close_object; 
        return null;       
    end; 

    -- describe columns 
    sys.dbms_sql.describe_columns2( l_cursor, l_desc_col_no , l_desc_col_info); 

    begin 
      l_status := dbms_sql.execute(l_cursor); 
    exception 
      when others then 
        apex_json.open_object; 
        apex_json.write('addInfo', 'While executing query error occured '); 
        apex_json.write('error', SQLERRM); 
        apex_json.close_object; 
        return null;       
    end; 

    l_sys_cursor := dbms_sql.to_refcursor(l_cursor);   

    --apex_json.initialize_clob_output; 

    apex_json.open_object; 
    apex_json.write( 'data', l_sys_cursor ); 
    apex_json.open_array('headers'); 

    for i in 1..l_desc_col_no loop 
      apex_json.open_object; 
      apex_json.write('COLUMN_NAME', l_desc_col_info(i).col_name); 
      apex_json.write('COLUMN_TYPE', getColumnTypeString( l_desc_col_info(i).col_type ) ); 
      apex_json.close_object; 
    end loop; 

    apex_json.close_array; 

    apex_json.write( 'x01', l_ajax_column_name, true ); 
    apex_json.write( 'x02', l_ajax_column_values, true ); 

    apex_json.close_object; 

    --htp.p( apex_json.get_clob_output ); 

    return l_result; 
  exception 
    when others then 
      apex_json.open_object; 
      apex_json.write('addInfo', 'Unknown ajax error'); 
      apex_json.write('error', SQLERRM); 
      apex_json.close_object; 
      htp.p( apex_json.get_clob_output ); 
      return l_result; 
  end ajax_row_details; 

end "UC_NESTED_REPORTS"; 
/

Package Body UC_NESTED_REPORTS compiled


--------------------------------------------------------
--  DDL for Package Body WMG_DISCORD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WMG_DISCORD" 
is


--------------------------------------------------------------------------------
-- TYPES
/**
 * @type
 */

-- CONSTANTS
/**
 * @constant gc_scope_prefix Standard logger package name
 */
gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';
subtype scope_t is varchar2(128);


/**
 * Log either via logger or apex.debug
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_msg
 * @param p_ctx
 * @return
 */
procedure log(
    p_msg  in varchar2
  , p_ctx  in varchar2 default null
)
is
begin
  $IF $$NO_LOGGER $THEN
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
  $ELSE
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $END

end log;



/**
 * Return the URL to a discord avatar
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_discord_id
 * @param p_avatar_uri
 * @return
 */
function avatar(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null)
return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'avatar';

  l_avatar wmg_players.discord_avatar%type;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  $IF $$VERBOSE_OUTPUT $THEN
  log('START', l_scope);
  $END


  if p_avatar_uri is null then
     select discord_avatar
       into l_avatar
       from wmg_players
      where discord_id = p_discord_id
        and discord_avatar is not null;
  else
    l_avatar := p_avatar_uri;
  end if;

  return 'https://cdn.discordapp.com/avatars/' || p_discord_id|| '/' || l_avatar || '.png';



exception
    when no_data_found then
      return V('APP_IMAGES') || 'img/discord_mask.png';

    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end avatar;





/**
 * Return the URL to a discord avatar
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_discord_id
 * @param p_avatar_uri
 * @return
 */
function avatar_link(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null
  , p_size_class in varchar2 default 'md')
return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'avatar_link';

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  $IF $$VERBOSE_OUTPUT $THEN
  log('START', l_scope);
  $END

   if p_discord_id is null then
     return '<img class="avatar ' || p_size_class || '" src="' || V('APP_IMAGES') || 'img/discord_mask.png' || '">';
   else
     -- return '<a class="-wm-discord-link" href="discord://discordapp.com/users/' || p_discord_id || '/">'
     return '<a class="-wm-discord-link" href="https://discordapp.com/users/' || p_discord_id || '/" target="discord">'
          || '<img class="avatar ' || p_size_class || '" src="' || avatar(p_discord_id => p_discord_id, p_avatar_uri => p_avatar_uri) || '">'
          || '</a>';
   end if;

exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end avatar_link;





/**
 * Return the HTML to render a player profile
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 13, 2023
 * @param p_player_id
 * @param p_avatar_uri
 * @return
 */
function render_profile(
    p_player_id  in wmg_players.id%type
  , p_mode       in varchar2             default 'FULL'
  , p_spacing    in varchar2             default 'FULL'
)
return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'render_profile';

  l_cols  varchar2(10);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  $IF $$VERBOSE_OUTPUT $THEN
  log('BEGIN', l_scope);
  $END


  if p_player_id is null then
    -- we don't have a player yet
    return '<img class="avatar md" src="' || wmg_discord.avatar(nv('G_DISCORD_ID')) || '"</> Player not setup.';
  end if;


  if p_spacing = 'FULL' then 
    l_cols := 'col-12';
  else
    l_cols := 'col-3';
  end if;

  for p in (
  select p.player_name
       , case when discord_id is not null then
          '<a href="discord://discordapp.com/users/' || p.discord_id || '/">'
          || '<img class="avatar ' || case when  p_mode in ('MINI', 'STREAM') then 'md' else 'lg' end || '" src="' || wmg_discord.avatar(p_discord_id => p.discord_id, p_avatar_uri => p.discord_avatar) || '">'
          || '</a>' 
         else '' end discord_profile
       , '<i class="' || case when  p_mode = 'MINI' then 'margin-top-sm' end || ' flag em-svg em-flag-' || p.country_code || '" aria-role="presentation" aria-label="' || p.COUNTRY_CODE || ' Flag"></i>' flag
       , p.rank_name
       , p.rank_profile_class
       , p.country
       , p.prefered_tz
    from wmg_players_v p
   where p.id = p_player_id
  )
  loop
    if p_mode = 'MINI' then
      return '<div class="row col-6 col-md-8 u-justify-content-space-around">' || p.discord_profile 
          $IF env.wmgt $THEN
          || ' &nbsp; <span class="' || p.rank_profile_class || '">' || p.rank_name || '</span>'
          $END
          || p.flag
      || '</div>';
    elsif p_mode = 'STREAM' then
      return '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         ||   p.discord_profile
         || '<h3>' || p.player_name || '</h3>'
         || '<hr>'
         $IF env.wmgt $THEN
         || '<div class="' || p.rank_profile_class || '">' || p.rank_name || '</div>'
         $END
         || '</div></div>'
         || '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         || p.flag || '<br>' || p.country
         || '</div></div>';
    else
      return '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         ||   p.discord_profile
         || '<h3>' || p.player_name || '</h3>'
         $IF env.wmgt $THEN
         || '<div class="' || p.rank_profile_class || '">' || p.rank_name || '</div>'
         $END
         || '</div></div>'
         || '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         || p.flag || '<br>' || p.country || '<br><hr>' || p.prefered_tz
         || '</div></div>';
     end if;
  end loop;

  $IF $$VERBOSE_OUTPUT $THEN
  log('END', l_scope);
  $END

exception
    when no_data_found then
      return V('APP_IMAGES') || 'img/discord_mask.png';

    when OTHERS then
      log('Unhandled Exception', l_scope);
      return 
      '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         || '<img class="avatar" src="' || v('APP_IMAGES') || 'img/discord_mask.png' || '">'
         || ' Something went wrong retriving your profile. Plese let a Tournament Director know.'
         || '</div>'
     || '</div>';
end render_profile;



procedure merge_players(
    p_from_player_id  in wmg_players.id%type
  , p_into_player_id  in wmg_players.id%type
  , p_remove_from_player in boolean default true
)
is
  l_scope  scope_t := gc_scope_prefix || 'merge_players';

  l_player_rec wmg_players%rowtype;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);
  log('.. p_from_player_id:' || p_from_player_id, l_scope);
  log('.. p_into_player_id:' || p_into_player_id, l_scope);

  if p_from_player_id is null or p_into_player_id is null then
    raise_application_error(-20000, 'Select two players');
  end if;

  if p_from_player_id = p_into_player_id then
    raise_application_error(-20001, 'Cannot merge the same player');
  end if;

  select *
    into l_player_rec
    from wmg_players
   where id = p_from_player_id;


  log('.. clear previous values from source player', l_scope);
  -- need to clear because some of these values are unique
  update wmg_players
     set account = 'Merged into ' || p_into_player_id
       , name = null
       , account_login = null
       , prefered_tz = null
       , discord_id = null
       , discord_avatar = null
       , discord_discriminator = null
   where id = p_from_player_id;

  log('.. Link to correct player', l_scope);
  update wmg_players
     set account = l_player_rec.account
       , name = l_player_rec.name
       , account_login = l_player_rec.account_login
       , prefered_tz = l_player_rec.prefered_tz
       , country_code = l_player_rec.country_code
       , discord_id = l_player_rec.discord_id
       , discord_avatar = l_player_rec.discord_avatar
       , discord_discriminator = l_player_rec.discord_discriminator
   where id = p_into_player_id
     and discord_id is null;

  log('.. Move tournament registration', l_scope);
  update wmg_tournament_players
     set player_id = p_into_player_id
   where player_id = p_from_player_id;

  log('.. Move tournament rounds', l_scope);
  update wmg_rounds
     set players_id = p_into_player_id
   where players_id = p_from_player_id;

  log('.. Move player badges', l_scope);
  update wmg_player_badges
     set player_id = p_into_player_id
   where player_id = p_from_player_id;

  log('.. Move player unicorns', l_scope);
  update wmg_player_unicorns
     set player_id = p_into_player_id
   where player_id = p_from_player_id;


  if p_remove_from_player then
    $IF env.fhit $THEN
    log('.. Delete player_invites', l_scope);
    delete
      from fhit_player_invites
     where player_id = p_from_player_id;    
    $END
    log('.. Delete old player', l_scope);
    delete
      from wmg_players
     where id = p_from_player_id;
  end if;


  log('END', l_scope);
end merge_players;


end wmg_discord;
/

Package Body WMG_DISCORD compiled


--------------------------------------------------------
--  DDL for Package Body WMG_ERROR_HANDLER
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WMG_ERROR_HANDLER" 
AS

--============================================================================
-- E R R O R   H A N D L E R  -  L O G G I N G  &  S E S S I O N   S T A T E
--============================================================================
FUNCTION error_handler_logging_session(
    p_error IN apex_error.t_error )
  RETURN apex_error.t_error_result
AS
  l_result apex_error.t_error_result;
  l_constraint_name varchar2(255);
  l_logger_message varchar2(4000);
  l_logger_scope   varchar2(1000);
BEGIN
  -- The first thing we need to do is initialize the result variable.
  l_result := apex_error.init_error_result ( p_error => p_error );
  -- Look at the error that was encountered. Is it an "internal" error?
  IF p_error.is_internal_error then
     -- If it is, then it may contain information that could give away clues to the 
     -- database structure.
     -- 
     -- However the errors for Authorization Checks should be fine... So if it's 
     -- anything BUT an authorization check, we need to re-write the error 
     -- Oh and if the session expired, don't report it as an error.
     IF p_error.apex_error_code = 'APEX.SESSION.EXPIRED' then -- added for APEX5
        -- Keep the error, but add more to it. And capture with logger below (for now).
        -- Redirect to Home Page after 1.5 second.
        l_result.message := p_error.message
            || '<script>setTimeout(function(){window.top.location="f?p=' || v('APP_ID') || '";},1500);</script>';
        -- leave the additional_info alone.
        -- l_result.additional_info := '';
     ELSIF p_error.apex_error_code <> 'APEX.AUTHORIZATION.ACCESS_DENIED' then


        -- We'll try to construct an error that has good information 
        -- but doesn't give away any info into the DB Structure
        --
        l_result.message := 'We''re Sorry. An unexpected error has occurred. '||
                            'Please note the following information and contact the help desk:<p/>'||
                            '<PRE/>'||
                            '<BR/> Application ID: '||v('APP_ID')||
                            '<BR/>        Page ID: '||v('APP_PAGE_ID')||
                            '<BR/>APEX ERROR CODE: '||p_error.apex_error_code||
                            '<BR/>    ora_sqlcode: '||p_error.ora_sqlcode||
                            '<BR/>    ora_sqlerrm: '||p_error.ora_sqlerrm||
                            '</PRE>';
     END IF;
  ELSE 
    -- It's NOT an internal error, so we need to handle it.
    --
    -- First lets reset the place where it's going to display
    -- If at all possible we want to get away from the ugly error page scenario.
    -- 
    l_result.display_location :=
      CASE 
         -- If the error is supposed to be displayed on an error page
         WHEN l_result.display_location = apex_error.c_on_error_page 
           -- Then let's put it back inline
           THEN apex_error.c_inline_in_notification
         -- Otherwise keep it as defined.
         ELSE l_result.display_location
      END;

      -- If it is an ORA error that was raised lets do our best to figure it out
      -- and present the error text of to the end user in a nicer format.
      -- 
      -- To do this we'll get the "First Error Text" using the APEX_ERROR API
      IF p_error.ora_sqlcode IS NOT NULL then

            -- If it's a constraint violation then we'll try to get a matching "friendly" message from our 
            -- Lookup table. Below is a reference of common constraint violations you may want to handle.
            --
            --   -) ORA-00001: unique constraint violated
            --   -) ORA-02091: transaction rolled back (-> can hide a deferred constraint)
            --   -) ORA-02290: check constraint violated
            --   -) ORA-02291: integrity constraint violated - parent key not found
            --   -) ORA-02292: integrity constraint violated - child record found
            --
            IF p_error.ora_sqlcode in (-1, -2091, -2290, -2291, -2292) then
              -- Get the contraint name 
              l_constraint_name := apex_error.extract_constraint_name ( p_error => p_error );
              -- Use that constraint name to see if we have a translation for it in our table.
              begin
                select message
                  into l_result.message
                  from wmg_constraint_lookup
                 where constraint_name = l_constraint_name;
              exception 
                 when no_data_found 
                 then null;
              end;
            ELSE
               -- Lets check some common error codes here... 
             l_result.message :=
              case 
                  when p_error.message is not null then
                    p_error.message
                  when p_error.ora_sqlcode = -1407 THEN
                   'Trying to insert a null value into a not null column.'
                  --WHEN p_error.ora_sqlcode =  -12899
                  --THEN 'The value you entered was to large for the field. Please try again.'
               else 
                  apex_error.get_first_ora_error_text (
                                    p_error => p_error )
               end;
            end if;

      ELSE
            --l_result.message := apex_error.get_first_ora_error_text (p_error => p_error );
            null;
      END IF;

      -- We can also use the APEX_ERROR API to automatically find the 
      -- item the error was associated with, IF they're not already set.
      if l_result.page_item_name is null and l_result.column_alias is null then
            apex_error.auto_set_associated_item (
                p_error        => p_error,
                p_error_result => l_result );
        end if;


   END IF;   

  -- LAST thing we do before returning is log the error     
  --
  -- LOG THE UNKNOWN ERROR IN THE LOGGER TABLES
  --
  -- First build the log message
  l_logger_message  := 'Here''s the full error details:<p/>'||
              '<PRE>'||
              '<BR/><B>          MESSAGE:</B> '||p_error.message||
              '<BR/><B>  Additional Info:</B> '||p_error.additional_info||
              '<BR/><B> Display Location:</B> '||p_error.display_location||
              '<BR/><B> Association_Type:</B> '||p_error.Association_type||
              '<BR/><B>   Page Item Name:</B> '||p_error.page_item_name||
              '<BR/><B>        Region ID:</B> '||p_error.region_id||
              '<BR/><B>     Column Alias:</B> '||p_error.column_alias||
              '<BR/><B>          Row Num:</B> '||p_error.row_num||
              '<BR/><B>Is Internal Error:</B> '||case when p_error.is_internal_error = TRUE 
                                          THEN 'True'
                                          ELSE 'False'
                                     end||
              '<BR/><B>  APEX ERROR CODE:</B> '||p_error.apex_error_code||
              '<BR/><B>      ora_sqlcode:</B> '||p_error.ora_sqlcode||
              '<BR/><B>      ora_sqlerrm:</B> '||p_error.ora_sqlerrm||
              '<BR/><B>  Error Backtrace:</B><BR/>'||p_error.error_backtrace||
              '<BR/><B>   Component.type:</B> '||p_error.component.type||
              '<BR/><B>     Component.id:</B> '||p_error.component.id||
              '<BR/><B>   Component.name:</B> '||p_error.component.name||
              '<BR/><B> First Error Text:</B> '||apex_error.get_first_ora_error_text ( p_error => p_error )||
              '<BR/><B>   Application ID:</B> '||v('APP_ID')||
              '<BR/><B>          Page ID:</B> '||v('APP_PAGE_ID')||'<P/><pre/>' ;
  -- Generate a SCOPE string for logger so we can get a handle back on it
  -- Format   YYYY-MM-DD HH24.MI.SS:USER:APP:PAGE:SESSION
  --
  l_logger_scope := to_char(sysdate,'YYYY-MM-DD HH24.MI.SS')||':'||v('APP_USER')||':'||v('APP_ID')||':'||v('APP_PAGE_ID')||':'||v('APP_SESSION');
  -- Now create the log entry as an error so it captures the error stack.
  -- but remove the HTML
  l_logger_message := replace(l_logger_message, '<BR/>', chr(10));
  l_logger_message := replace(replace(l_logger_message, '<B>', '*'), '</B>', '*');
  -- logger.log_apex_items(p_text => l_logger_message, p_scope => l_logger_scope);
  $IF $$LOGGER $THEN
  logger.log(p_text => l_logger_message, p_scope => l_logger_scope);
  $ELSE
  apex_debug.message('[%s] %s', l_logger_scope, l_logger_message);
  $END

  -- Now return the result record to the caller.

  RETURN l_result;
END error_handler_logging_session;


--============================================================================
-- F O R C E   P L / S Q L   E R R O R   
--============================================================================
PROCEDURE force_plsql_error
AS
    l_NUMBER number;
BEGIN
  l_number := 1/0;
END force_plsql_error;


end wmg_error_handler;
/


--------------------------------------------------------
--  DDL for Package Body WMG_NOTIFICATION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WMG_NOTIFICATION" 
is


--------------------------------------------------------------------------------
-- TYPES
/**
 * @type
 */

-- CONSTANTS
 c_embed_color_green     number := 5832556;
 c_embed_color_lightblue number := 5814783;
 c_embed_color_brightred number := 15605278;
 c_crlf varchar2(2) := chr(13)||chr(10);
 c_amp varchar2(2) := chr(38);

/**
 * @constant gc_scope_prefix Standard logger package name
 */
gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';
subtype scope_t is varchar2(128);

c_issue_noshow     constant wmg_tournament_players.issue_code%type := 'NOSHOW';


/**
 * Log either via logger or apex.debug
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_msg
 * @param p_ctx
 * @return
 */
procedure log(
    p_msg  in varchar2
  , p_ctx  in varchar2 default null
)
is
begin
  $IF $$NO_LOGGER $THEN
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
  $ELSE
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $END

end log;



/**
 * Send messages to Discord via Webhooks
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 24, 2023
 * @param p_webhook_code Code of a webhook to use from `wmg_webhooks`
 * @param p_content message content
 * @param p_embeds [Optional] JSON of embeds to go along with the message
 * @param p_user_name Optional user_name that owns the webhook
 * @return
 */
procedure send_to_discord_webhook(
    p_webhook_code    in wmg_webhooks.code%type
  , p_content         in clob
  , p_embeds          in clob default null
  , p_user_name       in wmg_players.account%type default null
)
is
  l_scope  scope_t := gc_scope_prefix || 'send_to_discord_webhook';
  -- l_params logger.tab_param;

  l_url           varchar2(4000);
  l_json_body     clob;
  l_response      clob;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  if p_embeds is null then
    l_json_body := json_object('content' value p_content);
  else
        -- Construct the full JSON body
    l_json_body := json_object(
        'content' value p_content,
        -- 'embeds' value json_array(p_embeds) format json -- Use FORMAT JSON for nested structures
        'embeds' value p_embeds format json -- Use FORMAT JSON for nested structures
    );
  end if;

  log(l_json_body, l_scope);

   apex_web_service.set_request_headers(
        p_name_01        => 'Content-Type',
        p_value_01       => 'application/json'
  );
  for webhook in (
    select h.*
      from wmg_webhooks h
     where h.code = p_webhook_code
       and h.active_ind = 'Y'
       and (p_user_name is null or owner_username = p_user_name)
  )
  loop
    log('Found webhook:' || webhook.name, l_scope);  
    l_response := apex_web_service.make_rest_request(
        p_url           => webhook.webhook_url
      , p_http_method   => 'POST'
      , p_body          => l_json_body
    );

    log('l_response', l_scope);
    log(l_response, l_scope);
  end loop;

  log('END', l_scope);

exception
  when OTHERS then
    log('Unhandled Exception', l_scope);
    log(l_response, l_scope);
    raise;
end send_to_discord_webhook;







/**
 * Send a notification that a "New Player" just registered
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 15, 2023
 * @param p_player_id
 * @return
 */
procedure new_player(
    p_player_id       in wmg_players.id%type
  , p_registration_id in wmg_tournament_players.id%type default null
)
is
  l_scope  scope_t := gc_scope_prefix || 'new_player';

  l_time_slot      wmg_tournament_players.time_slot%type;
  l_registration_attempts number;

  l_email_override varchar2(1000);
  l_body clob;
  l_content varchar2(1000);
  l_embeds  varchar2(1000);
  l_avatar_image  varchar2(1000);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  l_email_override :=  nvl(wmg_util.get_param('EMAIL_OVERRIDE'), wmg_util.get_param('NEW_PLAYER_NOTIFICATION_EMAILS'));
  log('emails will be sent to: ' || l_email_override, l_scope);

  if p_registration_id is not null then
    begin
      select time_slot
        into l_time_slot
        from wmg_tournament_players
       where id = p_registration_id;


      -- Count all registrations from this player, but exclude the current one
      select sum(decode(id, p_registration_id, 0, decode(active_ind, 'Y', 1, 0))) registrations
           , max(decode(id, p_registration_id, time_slot, '')) time_slot
        into l_registration_attempts
           , l_time_slot
         from wmg_tournament_players
        where player_id = p_player_id;

     exception
      when no_data_found then
       l_registration_attempts := 0;
       l_time_slot := 'N/A';
    end;
    log('registration_attempts:' || l_registration_attempts, l_scope);
    log('time_slot:' || l_time_slot, l_scope);
  end if;

  for p in (
    select p.* from wmg_players_v p where id = p_player_id
  )
  loop
    -- People with a default discord avatar use an internal image lacking the protocol
    -- if there's not protocol, add it
    l_avatar_image := case 
                      when instr(p.avatar_image, 'http') = 0 then
                         apex_util.host_url('SCRIPT')
                      end || p.avatar_image;
    l_body := '{' ||
        '    "ENV":'                 || apex_json.stringify( wmg_util.get_param('ENV') ) ||
        '   ,"PLAYER_NAME":'         || apex_json.stringify( p.player_name ) ||
        '   ,"DISCORD_AVATAR":'      || apex_json.stringify( l_avatar_image ) ||
        '   ,"TIME_SLOT":'           || apex_json.stringify( l_time_slot ) ||
        '   ,"REGISTRATION_ATTEMPTS":'|| apex_json.stringify( l_registration_attempts ) ||
        '   ,"ACCOUNT":'             || apex_json.stringify( p.account ) ||
        '   ,"NAME":'                || apex_json.stringify( p.name ) ||
        '   ,"DISCORD_ID":'          || apex_json.stringify( p.discord_id ) ||
        '   ,"PREFERED_TZ":'         || apex_json.stringify( p.prefered_tz ) ||
        $IF env.wmgt $THEN
        '   ,"MY_APPLICATION_LINK":' || '"' || apex_mail.get_instance_url || 'r/wmgt/wmgt/home' || '"' ||
        $ELSE
        '   ,"MY_APPLICATION_LINK":' || '"' || apex_mail.get_instance_url || 'r/fhit/fhit/home' || '"' ||
        $END
        '}' ;

    log(l_body, l_scope);
    apex_mail.send (
        p_to                 => l_email_override,
        p_from               => wmg_util.get_param('FROM_EMAIL'),
        p_template_static_id => 'NEW_PLAYER_REGISTRATION',
        p_placeholders       => l_body);

     -- Construct the embeds JSON for the webhook
     l_content := 'New Player: __' || p.player_name || '__ just registered for __' || l_time_slot || '__'
       || case
          when l_registration_attempts > 0 then 
           c_crlf || '__Previous Registrations to WMG__: **' || l_registration_attempts || '**' || c_crlf
          end;
     l_embeds := json_array (
               json_object(
                 'title' value 'Player: ' || p.player_name,
                 'description' value '[' || wmg_util.get_param('ENV') || ']',
                 'color' value c_embed_color_green,
                 'image' value json_object('url' value l_avatar_image),
                 'fields' value json_array(
                     json_object(
                         'name' value 'Display Name', 'value' value p.player_name, 'inline' value true
                     ),
                     json_object(
                         'name' value 'Display Account', 'value' value p.account, 'inline' value true
                     ),
                     json_object(
                         'name' value 'Discord ID', 'value' value p.discord_id
                     ),
                     json_object(
                         'name' value 'Country', 'value' value p.country, 'inline' value true
                     ),
                     json_object(
                         'name' value 'Timezone', 'value' value p.prefered_tz, 'inline' value true
                     )
                 )
             )
           );

    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'EL_JORGE'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );

    $IF env.fhit $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'FHIT1'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END

    $IF env.wmgt $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'STAFFWMGT'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


  end loop;

  apex_mail.push_queue;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end new_player;






/**
 * Send a webhook notification after the first player for any 
 * timeslot submits their scores
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created May 12, 2024
 * @param p_player_id
 * @param p_tournament_session_id
 * @return
 */
procedure notify_first_timeslot_finish(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , p_player_id              in wmg_players.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'notify_first_timeslot_finish';



  l_content varchar2(1000);
  l_embeds  varchar2(1000);
  l_time_slot      wmg_tournament_players.time_slot%type;
  -- l_body clob;
  -- l_avatar_image  varchar2(1000);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  for p in (

    select tp.time_slot, count(*) n
    from wmg_tournament_players tp
    where tp.tournament_session_id = p_tournament_session_id
     and tp.time_slot in (
        -- find the player's time slot
        select p.time_slot
          from wmg_tournament_players p
         where p.tournament_session_id = p_tournament_session_id
           and p.player_id = p_player_id
    )
    and exists (
        -- player must have entered rounds
        select 1
        from wmg_rounds r
        where r.tournament_session_id = tp.tournament_session_id
          and r.players_id = tp.player_id
    )
    group by tp.time_slot
    having count(*) = 1  -- is this the first one for their time slot
  )
  loop

    -- Construct the embeds JSON for the webhook
    l_content := '## The first player from __' || p.time_slot || '__ just entered their scores!';
    l_embeds := '{}';

    $IF env.wmgt $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'WMGT'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


    -- Add to the webhook for the staff channels
    l_content := l_content
          || c_crlf || 'time to verify some scorecards.';

    $IF env.fhit $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'FHIT1'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


    $IF env.wmgt $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'STAFFWMGT'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


  end loop;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end notify_first_timeslot_finish;





/**
 * Send a webhook notification after the first time slot closes
 * with all the players that did not show up

   The way to prevent being on the list is:
     * scores need to be present (they don't need to be validated)
     * an INFRACTION issue is specified
        For example, they couldn't finish, and we specify an INFRACTION (rule violation) issue 
     * They are unregistered by an Admin

 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created May 17, 2024
 * @param p_tournament_session_id
 * @param p_time_slot
 * @return
 */
procedure notify_channel_about_players(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , p_time_slot              in wmg_tournament_players.time_slot%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'notify_channel_about_players';


  l_content varchar2(1000);
  l_embeds  varchar2(1000);

  l_env     wmg_parameters.value%type;
  -- l_body clob;
  -- l_avatar_image  varchar2(1000);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  l_env := wmg_util.get_param('ENV');

  for p in (
    select tp.time_slot, listagg('<@' || tp.discord_id || '> (' || tp.player_name || ')', c_crlf) players
      from wmg_tournament_results_v r
         , wmg_tournament_player_v tp
     where tp.week = r.week (+)
       and tp.player_id = r.player_id (+)
       and tp.tournament_session_id = p_tournament_session_id
       and tp.time_slot = p_time_slot
       and tp.active_ind = 'Y'
       and r.total_scorecard is null      -- Anyone with no scores entered will be included.
     group by tp.time_slot
  )
  loop

    -- Construct the embeds JSON for the webhook
    l_content := '## The __' || p.time_slot || ' UTC __ time-slot is now closed!';

    l_embeds := json_array (
              json_object(
                'title' value 'The following players either did' || c_crlf 
                || 'not show up :ghost:' 
                || c_crlf || ' or ' || c_crlf 
                || 'did not enter their scores :red_square::' || c_crlf,
                'description' value p.players,
                'color' value c_embed_color_brightred,
                'fields' value json_array(
                    json_object(
                        'name' value 'ENV', 'value' value l_env
                    )
                )
            )
          );


    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'EL_JORGE'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );

    $IF env.fhit $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'FHIT1'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


    $IF env.wmgt $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'WMGT'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


  end loop;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end notify_channel_about_players;






/**
 * Send a webhook notification after the weekend tournament closes
 * Include a brief recap of winners.
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created May 19, 2024
 * @param p_tournament_session_id
 * @return
 */
procedure notify_channel_tournament_close(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'notify_channel_tournament_close';


  l_content varchar2(1000);
  l_embeds  varchar2(1000);

  l_env     wmg_parameters.value%type;
  -- l_body clob;
  -- l_avatar_image  varchar2(1000);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  l_env := wmg_util.get_param('ENV');

  for p in (
    select s.prefix_tournament, s.round_num, s.week, to_char(s.session_date, 'YYYY-MM-DD') session_date_prepared
         , (
        select listagg(p.pos || ': ' || '<@' || p.discord_id || '> (' || p.player_name || ')' || '     **' || p.total_score || '**', chr(13)||chr(10))
               within group (order by p.pos, decode(rank_code, 'NEW', 1, 'AMA', 2, 'RISING', 3, 'SEMI', 4)) players
          from wmg_tournament_session_points_v p
         where p.tournament_session_id = s.tournament_session_id
           and p.pos <= 3
          ) podium_players
      from wmg_tournament_sessions_v s
     where s.tournament_session_id = p_tournament_session_id

  )
  loop

    -- Construct the embeds JSON for the webhook
    l_content := '## The Weekly Tournament is now closed!';

    l_embeds := json_array (
              json_object(
                'title' value 'Congratulations!',
                'description' value p.podium_players || c_crlf|| c_crlf || '__final recap coming later__' ,
                'color' value c_embed_color_green,
                -- 'image' value json_object('url' value l_avatar_image),
                'fields' value json_array(
                    json_object(
                        'name' value 'Season', 'value' value p.prefix_tournament, 'inline' value true
                    ),
                    json_object(
                        'name' value 'Week', 'value' value p.round_num, 'inline' value true
                    ),
                    json_object(
                        'name' value 'Date', 'value' value p.session_date_prepared
                    )
                )
            )
          );

    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'EL_JORGE'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );

    $IF env.fhit $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'FHIT1'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


    $IF env.wmgt $THEN
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'WMGT'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );
    $END


  end loop;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end notify_channel_tournament_close;






/**
 * Given a tournament session, send push notifications when the rooms have been assigned
 * to all the players that registered for this session AND opted in for push notifications.
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created September 24, 2023
 * @param p_tournament_session_id
 * @return
 */
procedure notify_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'notify_room_assignments';
  -- l_params logger.tab_param;

  l_room  varchar2(100);
  l_when  varchar2(100);
  l_who   varchar2(4000);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. Loops through room assignments', l_scope);

  for push_player in (
    select distinct p.user_name, tp.player_id
      from apex_appl_push_subscriptions p
         , wmg_tournament_player_v tp
     where p.user_name = tp.account_login
       and tp.tournament_session_id = p_tournament_session_id
       and tp.active_ind = 'Y'
       and tp.rooms_open_flag = 'Y'
       -- and p.user_name like 'rimblas%' -- for testing purposes
  )
  loop
      log('.. Get room assignment for ' || push_player.user_name, l_scope);

      with my_room as (
        select p.tournament_session_id, p.time_slot, p.room_no
             , nvl(p.prefered_tz, sessiontimezone) tz
        from wmg_tournament_player_v p
        where p.active_ind = 'Y'
          and p.tournament_session_id = p_tournament_session_id
          and p.player_id = push_player.player_id
      )
      , format_room as (
        select room_no
             , player
             , to_char(local_tz, 'fmDy, fmMonth fmDD') 
              || ' ' 
              || case when tz like 'US/%' or tz like 'America%' then
                   ltrim(to_char(local_tz, 'HH:MI PM'), '0')
                 else 
                   to_char(local_tz, 'HH24:MI')
                 end
              || ' ' || tz at_local_time
        from (
          select p.tournament_player_id
               , case when s.rooms_open_flag = 'Y' then nvl2(p.room_no, t.prefix_room_name, '') || p.room_no else '' end room_no
               , case when s.rooms_open_flag = 'Y' then '' else row_number() over (order by p.tournament_player_id) || ': ' end
              || apex_escape.html(p.player_name) player
               , to_utc_timestamp_tz(to_char(s.session_date, 'yyyy-mm-dd') || 'T' || p.time_slot) at time zone r.tz local_tz
               , r.tz
          from wmg_tournament_player_v p
             , wmg_tournament_sessions s
             , wmg_tournaments t
             , my_room r
          where t.id = s.tournament_id
            and s.id =  p.tournament_session_id
            and p.active_ind = 'Y'
            and p.tournament_session_id = r.tournament_session_id
            and p.time_slot = r.time_slot
            and p.room_no = r.room_no
            and s.rooms_open_flag = 'Y'
        )
        order by tournament_player_id
      )
      select room_no
           , at_local_time
           , listagg(player, ', ') players
        into l_room
           , l_when
           , l_who
        from format_room
       group by room_no, at_local_time;


      apex_pwa.send_push_notification (
        p_user_name      => push_player.user_name
      , p_title          => 'Your room is ' || l_room
      , p_body           => l_who || c_crlf
                         || 'When: ' || l_when || c_crlf
                         || 'Room: ' || l_room || c_crlf

      );
  end loop;

  log('.. push_queue!', l_scope);
  apex_pwa.push_queue;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end notify_room_assignments;







/**
 * Given a tournament session, send push notifications when the rooms have been assigned
 * to all the players that registered for this session AND opted in for push notifications.
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created September 24, 2023
 * @param p_tournament_session_id
 * @return
 */
procedure notify_new_courses(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'notify_new_courses';
  -- l_params logger.tab_param;

  c_amp varchar2(2) := chr(38);

  l_title varchar2(4000);
  l_what  varchar2(4000);
  l_who   varchar2(4000);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. Gather the new session info. id=' || p_tournament_session_id, l_scope);

  for new_session in (
    select round_num, week, session_date
         , nvl(easy_course_name, 'TBD') easy_course_name
         , hard_course_name
         , nvl(easy_course_code, 'TBD') easy_course_code
         , nvl(hard_course_code, 'TBD') hard_course_code
      from wmg_tournament_sessions_v
     where tournament_session_id = p_tournament_session_id
  )
  loop

    l_title := 'New Courses: ' || new_session.easy_course_code || ' ' || c_amp || ' ' || new_session.hard_course_code;
    l_what :=  'What:' || c_crlf
            || 'Registrations open for Round ' || new_session.round_num || ' ' || new_session.week
            || 'Courses:' || c_crlf
            || new_session.easy_course_name || c_crlf
            || new_session.hard_course_name || c_crlf
            || 'When:' || c_crlf
            || to_char(new_session.session_date);

    log('title:' || l_title, l_scope);
    log(l_what, l_scope);
    for push_player in (
      select distinct user_name
        from apex_appl_push_subscriptions
    )
    loop
       apex_pwa.send_push_notification (
          p_user_name      => push_player.user_name
        , p_title          => l_title
        , p_body           => l_what
        );
    end loop;

  end loop;

  log('.. push_queue!', l_scope);
  apex_pwa.push_queue;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end notify_new_courses;





/**
 * Given a tournament session, generate a template with the Tournament Recap template
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 26, 2023
 * @param p_tournament_session_id
 * @param x_out CLOB with template output
 * @return
 */
procedure tournament_recap_template(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , x_out                    out clob
)
is
  l_scope  scope_t := gc_scope_prefix || 'tournament_recap_template';
  -- l_params logger.tab_param;

  l_subject varchar2( 4000 );
  l_placeholders varchar2( 4000 );
  l_html    clob;
  l_text    clob;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. Gather the new session info. id=' || p_tournament_session_id, l_scope);

  for new_session in (
    with session_stats as (
      select count(*) total_registered, sum(decode(pp.player_id, null, 0, 1)) total_played
        from wmg_tournament_players p
        left join wmg_tournament_session_points_v pp 
          on pp.tournament_session_id = p.tournament_session_id
          and pp.player_id = p.player_id
       where p.tournament_session_id = p_tournament_session_id
         and p.active_ind = 'Y'
    )
    select prefix_tournament, round_num, week, session_date
         , easy_course_name
         , hard_course_name
         , easy_course_code
         , hard_course_code
         , '' "NULL"
         , (select listagg('@'||p.account || '     **' || p.total_score || '**', chr(13)||chr(10))
                   within group (order by decode(rank_code, 'NEW', 1, 'AMA', 2, 'RISING', 3, 'SEMI', 4), pos) players
              from wmg_tournament_session_points_v p
             where p.tournament_session_id = s.tournament_session_id
               and p.pos = 1
           ) first_place
         , (select listagg('@'||p.account || '     **' || p.total_score || '**', chr(13)||chr(10))
                   within group (order by decode(rank_code, 'NEW', 1, 'AMA', 2, 'RISING', 3, 'SEMI', 4), pos) players
              from wmg_tournament_session_points_v p
             where p.tournament_session_id = s.tournament_session_id
               and p.pos = 2
           ) second_place
         , (select listagg('@'||p.account || '     **' || p.total_score || '**', chr(13)||chr(10))
                   within group (order by decode(rank_code, 'NEW', 1, 'AMA', 2, 'RISING', 3, 'SEMI', 4), pos) players
              from wmg_tournament_session_points_v p
             where p.tournament_session_id = s.tournament_session_id
               and p.pos = 3
           ) third_place
         , (select listagg(who, ', ') || ': ' || total
              from (
                  select who, total, rank() over (order by total desc) rn
                  from (
                  select '@'||r.account who
                       , sum(decode(s1, 1, 1, 0)
                           + decode(s2, 1, 1, 0)
                           + decode(s3, 1, 1, 0)
                           + decode(s4, 1, 1, 0)
                           + decode(s5, 1, 1, 0)
                           + decode(s6, 1, 1, 0)
                           + decode(s7, 1, 1, 0)
                           + decode(s8, 1, 1, 0)
                           + decode(s9, 1, 1, 0)
                           + decode(s10, 1, 1, 0)
                           + decode(s11, 1, 1, 0)
                           + decode(s12, 1, 1, 0)
                           + decode(s13, 1, 1, 0)
                           + decode(s14, 1, 1, 0)
                           + decode(s15, 1, 1, 0)
                           + decode(s16, 1, 1, 0)
                           + decode(s17, 1, 1, 0)
                           + decode(s18, 1, 1, 0)
                        ) total
                    from wmg_rounds_v r
                       , wmg_tournament_players tp
                   where r.week = s.week
                     and r.tournament_session_id = tp.tournament_session_id
                     and tp.player_id = r.player_id
                     and tp.issue_code is null  -- only players with no issues are eligible
                  group by r.account
                  ) aces
                  order by aces.who
              )
              where rn = 1
              group by total
           ) diamond_players
         , (select c.total_coconuts || ' out of ' || st.total_played || ' players'
                 || case 
                    when nvl(st.total_played,0) = 0 then ''
                    else
                     ' (' || 100  * round(c.total_coconuts / st.total_played,2) || '%)'
                    end total   -- total  (total %)
              from session_stats st
                 , (select count(*) total_coconuts
                    from (
                        select u.week
                          from wmg_rounds_unpivot_mv u
                             , wmg_tournament_sessions ts
                             , wmg_tournament_players tp
                         where ts.week = u.week
                           and ts.id = tp.tournament_session_id
                           and tp.player_id = u.player_id
                           and tp.issue_code is null  -- only players with no issues are eligible
                           and u.week = s.week
                         having sum(case when par <= 0 then 1 else 0 end) = 36
                         group by u.week, u.player_id
                    )
                   ) c
          ) coconut_players
         , (select listagg('@'||account, ', ') || '  **' || total || '**' top_easy
              from (
                    select r.*, rank() over (partition by course_mode order by r.total) rn
                    from (
                    select course_mode, player_id, player_name, account, sum(under_par) total
                      from wmg_rounds_v r
                         , wmg_tournament_courses tc
                      where r.week = s.week
                        and r.tournament_session_id = tc.tournament_session_id
                        and r.course_id = tc.course_id
                        and tc.course_no = 1
                     group by course_mode, player_id, player_name, account
                    ) r
                    order by course_mode, rn, r.player_name
              )
              where rn = 1
              group by  course_mode, total
            ) easy_top_players
         , (select listagg('@'||account, ', ') || '  **' || total || '**' top_hard
              from (
                    select r.*, rank() over (partition by course_mode order by r.total) rn
                    from (
                    select course_mode, player_id, player_name, account, sum(under_par) total
                      from wmg_rounds_v r
                         , wmg_tournament_courses tc
                      where r.week = s.week
                        and r.tournament_session_id = tc.tournament_session_id
                        and r.course_id = tc.course_id
                        and tc.course_no = 2
                     group by course_mode, player_id, player_name, account
                    ) r
                    order by course_mode, rn, r.player_name
              )
              where rn = 1
              group by  course_mode, total
            ) hard_top_players
      from wmg_tournament_sessions_v s
     where s.tournament_session_id = p_tournament_session_id
  )
  loop

    log('.. SEASON:' || new_session.prefix_tournament, l_scope);
    log('.. WEEK_NUM:' || new_session.round_num, l_scope);
    log('.. FIRST_PLACE:' || new_session.first_place, l_scope);

    l_placeholders := '{' ||
        '    "SEASON":'           || apex_json.stringify( new_session.prefix_tournament ) ||
        '   ,"WEEK_NUM":'         || apex_json.stringify( new_session.round_num ) ||
        '   ,"FIRST_PLACE":'      || apex_json.stringify( new_session.first_place ) ||
        '   ,"SECOND_PLACE":'     || apex_json.stringify( new_session.second_place ) ||
        '   ,"THIRD_PLACE":'      || apex_json.stringify( new_session.third_place ) ||
        '   ,"PRO_PLAYERS":'      || apex_json.stringify( new_session."NULL" ) ||
        '   ,"SEMI_PLAYERS":'     || apex_json.stringify( new_session."NULL" ) ||
        '   ,"RISING_PLAYERS":'   || apex_json.stringify( new_session."NULL" ) ||
        '   ,"AMATEUR_PLAYERS":'  || apex_json.stringify( new_session."NULL" ) ||
        '   ,"DIAMOND_PLAYERS":'  || apex_json.stringify( new_session.diamond_players  ) ||
        '   ,"COCONUT_PLAYERS":'  || apex_json.stringify( new_session.coconut_players  ) ||
        '   ,"EASY_CODE":'        || apex_json.stringify( new_session.easy_course_code ) ||
        '   ,"EASY_TOP_PLAYERS":' || apex_json.stringify( new_session.easy_top_players ) ||
        '   ,"HARD_CODE":'        || apex_json.stringify( new_session.hard_course_code ) ||
        '   ,"HARD_TOP_PLAYERS":' || apex_json.stringify( new_session.hard_top_players ) ||
        '}';

    log(l_placeholders, l_scope);

    apex_mail.prepare_template (
        p_static_id    => 'TOURNAMENT_RECAP'
      , p_placeholders => l_placeholders
      , p_subject      => l_subject
      , p_html         => l_html
      , p_text         => l_text
    );

  end loop;

  log('.. recap template', l_scope);
  log(l_subject, l_scope);
  log(l_text, l_scope);
  -- log(l_html, l_scope);

  x_out := l_text;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end tournament_recap_template;






/**
 * Given a tournament session, generate a template with the Tournament Issues (Not Cool List) template
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created December 3, 2023
 * @param p_tournament_session_id
 * @param x_out CLOB with template output
 * @return
 */
procedure tournament_issues_template(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , x_out                    out clob
)
is
  l_scope  scope_t := gc_scope_prefix || 'tournament_issues_template';
  -- l_params logger.tab_param;

  l_subject varchar2( 4000 );
  l_placeholders varchar2( 4000 );

  l_html    clob;
  l_text    clob;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. Gather the new session info. id=' || p_tournament_session_id, l_scope);

  for new_session in (
    with issues as (
      select p.issue_code
           -- , listagg(p.player_name, chr(13)||chr(10) ) issue_list
           , listagg('@'||p.account, chr(13)||chr(10) ) issue_list
      from wmg_tournament_player_v p
         , wmg_issues i
      where p.issue_code = i.code
        and p.tournament_session_id = p_tournament_session_id
      group by p.issue_code
    )
    select prefix_tournament, round_num, week, session_date
         , '' "NULL"
         , (select issue_list from issues where issue_code = 'NOSHOW') no_show_list
         , (select issue_list from issues where issue_code = 'NOSCORE') no_score_list
      from wmg_tournament_sessions_v s
     where s.tournament_session_id = p_tournament_session_id
  )
  loop

    log('.. SEASON:' || new_session.prefix_tournament, l_scope);
    log('.. WEEK_NUM:' || new_session.round_num, l_scope);

    l_placeholders := '{' ||
        '    "SEASON":'         || apex_json.stringify( new_session.prefix_tournament ) ||
        '   ,"WEEK_NUM":'       || apex_json.stringify( new_session.round_num ) ||
        '   ,"NO_SCORES_LIST":' || apex_json.stringify( new_session.no_score_list ) ||
        '   ,"NO_SHOWS_LIST":'  || apex_json.stringify( new_session.no_show_list ) ||
        '}';

    log(l_placeholders, l_scope);

    apex_mail.prepare_template (
        p_static_id    => 'TOURNAMENT_RECAP_ISSUES'
      , p_placeholders => l_placeholders
      , p_subject      => l_subject
      , p_html         => l_html
      , p_text         => l_text
    );

  end loop;

  log('.. recap template', l_scope);
  log(l_subject, l_scope);
  log(l_text, l_scope);
  -- log(l_html, l_scope);

  x_out := l_text;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end tournament_issues_template;





/**
 * Given a tournament session, generate a template with the Tournament Course template
 * and provided stats about records, easy and hard holes, unicorns, etc..
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 11, 2024
 * @param p_tournament_session_id
 * @param x_out CLOB with template output
 * @return
 */
procedure tournament_courses_template(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , x_out                    out clob
)
is
  l_scope  scope_t := gc_scope_prefix || 'tournament_courses_template';
  -- l_params logger.tab_param;

  l_subject varchar2( 4000 );
  l_placeholders varchar2( 4000 );
  l_easy_record varchar2( 400 );
  l_hard_record varchar2( 400 );
  l_easy_top_scores varchar2( 4000 );
  l_hard_top_scores varchar2( 4000 );

  l_unicorns_easy_ok varchar2(1);
  l_unicorns_easy    varchar2(4000);
  l_unicorns_hard_ok varchar2(1);
  l_unicorns_hard    varchar2(4000);

  l_html    clob;
  l_text    clob;

  function course_rank(p_course_id in wmg_courses.id%type) return varchar2
  as
     l_course_rank_info varchar2(250);
     l_course_last_played_info varchar2(250);
  begin
    for rank_info in (
      with std_scale as (
        select max(std_dev) max_std_dev
          from wmg_course_stats_v
      )
      select r.*
           , case
               when r.easiest_rank = 1 then r.easiest_rank || 'st'
               when r.easiest_rank = 2 then r.easiest_rank || 'nd'
               when r.easiest_rank = 3 then r.easiest_rank || 'rd'
               else r.easiest_rank || 'th'
             end as easiest_rank_ordinal
           , case
               when r.hardest_rank = 1 then r.hardest_rank || 'st'
               when r.hardest_rank = 2 then r.hardest_rank || 'nd'
               when r.hardest_rank = 3 then r.hardest_rank || 'rd'
               else r.hardest_rank || 'th'
             end as hardest_rank_ordinal
      from (
        select course_id
             , course_code, course_name
             , round(difficulty) difficulty
             , rank() over (partition by course_mode order by difficulty desc nulls last) mode_rank
             , rank() over (order by difficulty) easiest_rank
             , rank() over (order by difficulty desc nulls last) hardest_rank
             , count(*) over () total_courses
         from (
              select c.id course_id
                   , c.code course_code
                   , c.name course_name
                   , c.course_mode
               , sum(
                  case 
                    when s.std_dev = 0 then 0
                    else round(s.std_dev / std_scale.max_std_dev * 10,1)
                  end
                ) difficulty
              from  wmg_courses c
                  , wmg_course_stats_v s
                  , std_scale
              where c.id = s.course_id (+)
              group by c.id, c.code, c.name, c.course_mode
          )
        ) r
       where r.course_id = p_course_id
    )
    loop
      log('.. course:' || rank_info.course_code, l_scope);
      log('.. difficulty:' || rank_info.difficulty, l_scope);
      log('.. easiest_rank:' || rank_info.easiest_rank, l_scope);
      log('.. hardest_rank:' || rank_info.hardest_rank, l_scope);


      if rank_info.difficulty is null then
        l_course_rank_info := rank_info.course_code || ' has never been played in the tournament';
      elsif rank_info.easiest_rank <= 10 then
        l_course_rank_info := rank_info.course_code || ' is the' 
                          || case 
                              when rank_info.easiest_rank = 1 then '' 
                              else ' ' || rank_info.easiest_rank_ordinal
                             end
                          || ' easiest course, with a difficulty of ' || rank_info.difficulty || ' out of 100';
      elsif rank_info.hardest_rank <= 10 then
        l_course_rank_info := rank_info.course_code || ' is the' 
                          || case 
                              when rank_info.hardest_rank = 1 then '' 
                              else ' ' || rank_info.hardest_rank_ordinal
                             end
                          || ' hardest course, with a difficulty of ' || rank_info.difficulty || ' out of 100';
      else 
        l_course_rank_info := rank_info.course_code 
           || ' is ' || rank_info.hardest_rank || ' in difficulty out of ' || rank_info.total_courses || ' courses with a rank '
           || rank_info.difficulty || ' out of 100';
        if rank_info.mode_rank = 1 then
          l_course_rank_info := l_course_rank_info || c_crlf
                           || 'But more important, ' || rank_info.course_code || ' is the hardest of all the easy courses!';
        end if;
      end if;

    end loop;

    begin
      select 'It was last played on ' || ts.week || ' on ' || to_char(ts.session_date, 'Month DD, YYYY')
      || ' (' || apex_util.get_since(ts.session_date) || ')'
        into l_course_last_played_info
      from wmg_tournament_sessions ts
         , wmg_tournament_courses tc
         , wmg_courses c
      where tc.tournament_session_id = ts.id
        and tc.tournament_session_id != p_tournament_session_id
        and tc.course_id = c.id
        and tc.course_id = p_course_id
        order by ts.session_date desc
       fetch first 1 rows only;

    exception
      when no_data_found then
        -- never played before
        l_course_last_played_info := '';

    end;

    return l_course_rank_info || chr(13)||chr(10) || l_course_last_played_info;

  end course_rank;


  -- Get the easiest and hardest holes for a course
  function course_holes(p_course_id in wmg_courses.id%type, p_type in varchar2) return varchar2
  as
     l_course_holes_info varchar2(200);
  begin
    with std_scale as (
       select max(std_dev) max_std_dev
         from wmg_course_stats_v
    )
    , holes as (
      select s.course_id, s.course_code, s.h
           , case 
                when s.std_dev = 0 then 0
                else round(s.std_dev / std_scale.max_std_dev * 10,1)
              end value
      from  wmg_course_stats_v s
          , std_scale
      where s.course_id = p_course_id
    )
    select listagg('Hole ' || h || ' with a rating of ' || round(value,2) || ' out of 10', chr(13)||chr(10) )
      into l_course_holes_info
    from (
      select h
           , value
           , row_number() over (order by value) easiest
           , row_number() over (order by value desc) hardest
      from holes
    )
    where (p_type = 'E' and easiest =1)
       or (p_type = 'H' and hardest =1);
    return l_course_holes_info;

  end course_holes;


  /**
  * unicorns_ok
  *  N = Not eligible for Unicorns
  *  Y = Eligible for Unicorns
  * 
  */
  function unicorns_ok(p_course_id in wmg_courses.id%type)
  return varchar2
  is
    l_unicorns_ok varchar2(1);
  begin
    with course_play_count as (
      select count(*) play_count
      from wmg_tournament_courses c
         , wmg_tournament_sessions s
      where s.id = c.tournament_session_id
        and s.session_date <= (select ts.session_date from wmg_tournament_sessions ts where ts.id = p_tournament_session_id)
        and c.course_id = p_course_id
      group by c.course_id
    )
    select case when play_count >= 5 then 'Y' else 'N' end
      into l_unicorns_ok
      from course_play_count;

    return l_unicorns_ok;

  end unicorns_ok;

  /**
  * unicorns_info
  *  Return available and pending unicorns for a course
  * 
  */
  function unicorns_info(p_course_id in wmg_courses.id%type)
  return varchar2
  is
    l_unicorns_info varchar2(4000);
  begin
    log('.. unicorns_info', l_scope);
    l_unicorns_info := null;

    for u in (
        with course_play_count as (
            select c.course_id
                 , count(*) play_count
                 , sum(decode(s.completed_ind, 'Y', 1, 0)) real_play_count
                 , max(s.week) week, max(s.session_date) session_date
            from wmg_tournament_courses c
               , wmg_tournament_sessions s
            where s.id = c.tournament_session_id
              and s.session_date <= (select ts.session_date from wmg_tournament_sessions ts where ts.id = p_tournament_session_id)
              and c.course_id = p_course_id
            group by c.course_id
        )
        , courses_played as (
          select c.course_id, c.code course_code, c.name course_name, cc.play_count, cc.real_play_count, cc.week, cc.session_date
          from wmg_courses_v  c
             , course_play_count cc
          where c.course_id = cc.course_id
            and cc.play_count >= 1
        )
        , missing_ace as (
            select level h
            from dual
            connect by level <= 18
            minus
            select distinct h
            from wmg_rounds_unpivot_mv
            where course_id = p_course_id
            and score = 1
        )
        select 'For ' || cp.course_code || ', played ' || cp.real_play_count || ' times before, these holes have never been aced:' || chr(13)||chr(10)
               || listagg('* Hole ' || m.h, chr(13)||chr(10)) within group (order by h) unicorn_info
             , 'P' unicorn_status
        from missing_ace m
           , courses_played cp
        group by cp.course_code, cp.real_play_count 
        union all
        select 'For ' || course_code || ', played ' || real_play_count || ' times before, these are the unicorns:' || chr(13)||chr(10)
               || listagg('* Hole ' || h || ' (' || week || ') by ' || ace_by , chr(13)||chr(10)) within group (order by h) unicorn_info
               , unicorn_status
          from (
          select uni.course_code
               , 'U' unicorn_status
               , uni.play_count
               , uni.real_play_count
               , uni.h
               , uni.week
                -- for debuging
               , (select listagg(p.player_name, ',') player_name
                    from wmg_rounds_unpivot_mv u
                       , wmg_players_v p
                   where u.player_id = p.id
                     and u.course_id = uni.course_id
                     and u.h = uni.h
                     and u.week <= uni.week
                     and u.score = 1) ace_by
          from (
              select u.course_id, cp.course_code, cp.play_count, cp.real_play_count, u.h
                   , max(u.week) week
                from wmg_rounds_unpivot_mv u
                   , courses_played cp
                where u.score = 1
                  and u.course_id = cp.course_id
                  and cp.play_count >= 5
                  and u.week in (select ts.week from wmg_tournament_sessions ts where ts.session_date <= cp.session_date)
                  and (u.course_id, u.h) not in (select course_id, h from wmg_player_unicorns) -- eliminate previous unicorns
                group by u.course_id, cp.course_code, cp.play_count, cp.real_play_count, u.h
               having count(*) = 1
          ) uni
        )
        group by course_code, real_play_count, unicorn_status
        order by unicorn_status
      )
   loop
    log('.... unicorns_info:' || u.unicorn_info, l_scope);
     l_unicorns_info := l_unicorns_info || u.unicorn_info || c_crlf;
   end loop;

    return l_unicorns_info;

  end unicorns_info;



begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. Gather the tournament courses info. id=' || p_tournament_session_id, l_scope);

  for new_session in (
    select tournament_id, prefix_tournament
         , round_num, week, session_date
         , easy_course_id
         , nvl(easy_course_name, 'TBD') easy_course_name
         , easy_course_emoji
         , hard_course_id
         , nvl(hard_course_name, 'TBD') hard_course_name
         , hard_course_emoji
         , nvl(easy_course_code, 'TBD') easy_course_code
         , nvl(hard_course_code, 'TBD') hard_course_code
         , '' "NULL"
      from wmg_tournament_sessions_v
     where tournament_session_id = p_tournament_session_id
       and easy_course_id is not null
       and hard_course_id is not null
  )
  loop

    log('.. SEASON:' || new_session.prefix_tournament, l_scope);
    log('.. WEEK_NUM:' || new_session.round_num, l_scope);
    log('.. SEASON:' || new_session.prefix_tournament, l_scope);
    log('.. EASY_CODE:' || new_session.easy_course_code, l_scope);
    log('.. HARD_CODE:' || new_session.hard_course_code, l_scope);

    -- Easy Course Record
   -- select listagg(player_name || ' (' || week || ')', ', ') within group (order by week, player_name)  || ': ' || min(under_par) course_record
    select '**(' || min(under_par) || ')**' || chr(13)||chr(10) || listagg(player_name || ' (' || week || ')', ', ') within group (order by week, player_name) course_record
      into l_easy_record
      from (
       select max(week) week, player_name, under_par
        from wmg_rounds_v
       where course_id = new_session.easy_course_id
         and (under_par) in (
          select min(under_par)
            from wmg_rounds_v
           where course_id = new_session.easy_course_id
         )
       group by player_name, under_par
      );

    -- Hard Course Record
   -- select listagg(player_name || ' (' || week || ')', ', ') within group (order by week, player_name)  || ': ' || min(under_par) course_record
    select '**(' || min(under_par) || ')**' || chr(13)||chr(10) || listagg(player_name || ' (' || week || ')', ', ') within group (order by week, player_name) course_record
      into l_hard_record
      from (
       select max(week) week, player_name, under_par
        from wmg_rounds_v
       where course_id = new_session.hard_course_id
         and (under_par) in (
          select min(under_par)
            from wmg_rounds_v
           where course_id = new_session.hard_course_id
         )
       group by player_name, under_par
      );


    log('.. easy_top_scores', l_scope);
    with best_round as (
      select course_id, sum(score) best_strokes
      from (
        select course_id, h, score, row_number()  over (partition by course_id, h order by people desc) rn
        from (
            select u.course_id, u.h, u.score, count(*) people
              from wmg_rounds_unpivot_mv u
             where u.course_id = new_session.easy_course_id
               and u.player_id != 0  -- remove the curated system score
             group by u.course_id, u.h, u.score
        )
      )
     where rn = 1
     group by course_id
    )
    select '```' || c_crlf || listagg(score_type || ' ' || under_par, c_crlf ) || c_crlf || '```'
      into l_easy_top_scores
    from (
        select '- Leaderboard: ' score_type, r.scorecard_total under_par
        from wmg_rounds_v r
        where r.course_id = new_session.easy_course_id
          and r.player_id = 0
          and r.week = 'S00W00' 
        union all
        select '- Realistic:   ' score_type, r.best_strokes - c.course_par under_par
        from wmg_courses_v c
           ,  best_round r
        where r.course_id = c.course_id
          and c.course_id = new_session.easy_course_id
        union all
        select '- Utopian:     ' score_type, best_under under_par
        from wmg_courses_v
        where course_id = new_session.easy_course_id
          and best_under is not null
     )
     order by under_par asc, score_type;


    log('.. hard_top_scores', l_scope);
    with best_round as (
      select course_id, sum(score) best_strokes
      from (
        select course_id, h, score, row_number()  over (partition by course_id, h order by people desc) rn
        from (
            select u.course_id, u.h, u.score, count(*) people
              from wmg_rounds_unpivot_mv u
             where u.course_id = new_session.hard_course_id
               and u.player_id != 0  -- remove the curated system score
             group by u.course_id, u.h, u.score
        )
      )
     where rn = 1
     group by course_id
    )
    select '```' || c_crlf || listagg(score_type || ' ' || under_par, c_crlf ) || c_crlf || '```'
      into l_hard_top_scores
    from (
        select '- Leaderboard: ' score_type, r.scorecard_total under_par
        from wmg_rounds_v r
        where r.course_id = new_session.hard_course_id
          and r.player_id = 0
          and r.week = 'S00W00' 
        union all
        select '- Realistic:   ' score_type, r.best_strokes - c.course_par under_par
        from wmg_courses_v c
           ,  best_round r
        where r.course_id = c.course_id
          and c.course_id = new_session.hard_course_id
        union all
        select '- Utopian:     ' score_type, best_under under_par
        from wmg_courses_v
        where course_id = new_session.hard_course_id
          and best_under is not null
     )
     order by under_par asc, score_type;


    l_unicorns_easy_ok := unicorns_ok(new_session.easy_course_id);
    log('.. unicorns_easy_ok: '|| l_unicorns_easy_ok, l_scope);
    l_unicorns_easy := unicorns_info(new_session.easy_course_id);

    l_unicorns_hard_ok := unicorns_ok(new_session.hard_course_id);
    log('.. unicorns_hard_ok: '|| l_unicorns_hard_ok, l_scope);
    l_unicorns_hard := unicorns_info(new_session.hard_course_id);


    log('.. course_ranks', l_scope);


    l_placeholders := '{' ||
      '    "SEASON":'         || apex_json.stringify( new_session.prefix_tournament ) ||
      '   ,"WEEK_NUM":'       || apex_json.stringify( new_session.round_num ) ||
      '   ,"EASY_COURSE":'           || apex_json.stringify( ':' || new_session.easy_course_emoji || ': ' || new_session.easy_course_name ) ||
      '   ,"EASY_CODE":'             || apex_json.stringify( new_session.easy_course_code ) ||
      '   ,"EASY_RECORD":'           || apex_json.stringify( l_easy_record ) ||
      '   ,"EASY_TOP_SCORES":'       || apex_json.stringify( l_easy_top_scores ) ||
      '   ,"EASY_RANKING":'          || apex_json.stringify( course_rank(new_session.easy_course_id ) ) ||
      '   ,"EASY_HARD_HOLES":'       || apex_json.stringify( course_holes(new_session.easy_course_id, 'H' ) ) ||
      '   ,"EASY_EASY_HOLES":'       || apex_json.stringify( course_holes(new_session.easy_course_id, 'E' ) ) ||
      '   ,"UNICORNS_EASY_OK":'      || apex_json.stringify( l_unicorns_easy_ok ) || 
      '   ,"EASY_UNICORNS":'         || apex_json.stringify( l_unicorns_easy ) || 
      '   ,"HARD_COURSE":'           || apex_json.stringify( ':' || new_session.hard_course_emoji || ': ' || new_session.hard_course_name ) ||
      '   ,"HARD_CODE":'             || apex_json.stringify( new_session.hard_course_code ) ||
      '   ,"HARD_RECORD":'           || apex_json.stringify( l_hard_record ) ||
      '   ,"HARD_TOP_SCORES":'       || apex_json.stringify( l_hard_top_scores ) ||
      '   ,"HARD_RANKING":'          || apex_json.stringify( course_rank(new_session.hard_course_id ) ) ||
      '   ,"HARD_HARD_HOLES":'       || apex_json.stringify( course_holes(new_session.hard_course_id, 'H' ) ) ||
      '   ,"HARD_EASY_HOLES":'       || apex_json.stringify( course_holes(new_session.hard_course_id, 'E' ) ) ||
      '   ,"UNICORNS_HARD_OK":'      || apex_json.stringify( l_unicorns_hard_ok ) ||  
      '   ,"HARD_UNICORNS":'         || apex_json.stringify( l_unicorns_hard ) ||  
      '}';

    log(l_placeholders, l_scope);

    apex_mail.prepare_template (
        p_static_id    => 'TOURNAMENT_COURSES'
      , p_placeholders => l_placeholders
      , p_subject      => l_subject
      , p_html         => l_html
      , p_text         => l_text
    );

  end loop;

  log('.. recap template', l_scope);
  log(l_subject, l_scope);
  log(l_text, l_scope);
  -- log(l_html, l_scope);

  x_out := l_text;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end tournament_courses_template;


end wmg_notification;
/



--------------------------------------------------------
--  DDL for Package Body WMG_UTIL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WMG_UTIL" 
is


--------------------------------------------------------------------------------
-- TYPES
/**
 * @type
 */

-- CONSTANTS
/**
 * @constant gc_scope_prefix Standard logger package name
 */
gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';
subtype scope_t is varchar2(128);

c_issue_noshow     constant wmg_tournament_players.issue_code%type := 'NOSHOW';
c_issue_noscore    constant wmg_tournament_players.issue_code%type := 'NOSCORE';
c_issue_infraction constant wmg_tournament_players.issue_code%type := 'INFRACTION';


g_rooms_set_ind wmg_tournament_sessions.rooms_defined_flag%type;


/**
 * Log either via logger or apex.debug
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_msg
 * @param p_ctx
 * @return
 */
procedure log(
    p_msg  in varchar2
  , p_ctx  in varchar2 default null
)
is
begin
  -- $IF logger_logs.g_logger_version is not null $THEN
  $IF $$LOGGER $THEN
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $ELSE
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
  $END

end log;


function rooms(p_player_count in number) return number
is
   l_players integer;
   l_rooms number;
begin
  l_players := nvl(p_player_count, 0);
  l_rooms := trunc(l_players / 4);

  return 
      case 
        when l_rooms  =  (l_players / 4) then l_rooms  -- evenly divisible by 4
        else
          l_rooms + 1
      end;

/*
when p_player_count = 5 then 1 --  Rooms 3 + 2
when p_player_count = 6 then 1 --  Rooms 3 + 3
when p_player_count = 7 then 1 --  Rooms 3 + 3
when p_player_count = 8 then 1 --  Rooms 4 + 4
when p_player_count = 9 then 1 --  Rooms 3 + 3 + 3
*/

end rooms;


/**
 * Given a Tournament Session return Y when the Rooms are set and defined
 * N when they are not
 *
 *
 * @example
 *   :G_CURRENT_SESSION_ID is not null and (:G_REGISTRATION_ID is not null) and wmg_util.rooms_set(:G_CURRENT_SESSION_ID) = 'N'
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created 
 * @param tournament_session_id 
 * @return Y/N
 */
function rooms_set(p_tournament_session_id in wmg_tournament_sessions.id%type )
   return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'rooms_set';
  l_rooms_defined_flag wmg_tournament_sessions.rooms_defined_flag%type;
begin
  $IF $$VERBOSE_OUTPUT $THEN
  log('START', l_scope);
  log('g_rooms_set_ind:' || g_rooms_set_ind, l_scope);
  $END

  if g_rooms_set_ind is null then
    $IF $$VERBOSE_OUTPUT $THEN
    log('fetch new rooms_defined_flag:', l_scope);
    $END
    select nvl(rooms_defined_flag, 'N')
      into l_rooms_defined_flag
      from wmg_tournament_sessions 
     where id = p_tournament_session_id;

    g_rooms_set_ind := l_rooms_defined_flag;
  end if;

  return g_rooms_set_ind;

  exception
    when no_data_found then
      g_rooms_set_ind := 'N';
      return g_rooms_set_ind;
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end rooms_set;



------------------------------------------------------------------------------
/**
 * Get parameter values
 *
 *
 * @example
 * wmg_util.get_param('EMAIL_OVERRIDE')
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 8, 2016
 * @param
 * @return
 */
function get_param(
  p_name_key  in wmg_parameters.name_key%TYPE
)
return varchar2
is
  l_value wmg_parameters.value%TYPE;
begin

  select value
    into l_value
    from wmg_parameters
   where name_key = p_name_key;

  return l_value;

exception
  when NO_DATA_FOUND then
    return null;

end get_param;





/**
 * Set a parameter value
 *
 *
 * @example
 * wmg_util.set_param('EMAIL_OVERRIDE', 'developers_list@insum.ca')
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 8, 2016
 * @param
 * @return
 */
procedure set_param(
    p_name_key      in wmg_parameters.name_key%TYPE
  , p_value         in wmg_parameters.value%TYPE
)
is
begin

  update wmg_parameters
     set value = p_value
   where name_key = p_name_key;

  if sql%rowcount = 0 then
    raise_application_error(
        -20001
      , 'Parameter ' || p_name_key || ' does not exist.'
    );
  end if;

end set_param;



------------------------------------------------------------------------------
function extract_hole_from_file(p_filename in varchar2) 
  return number
is
  l_scope  scope_t := gc_scope_prefix || 'extract_hole_from_file';
  f apex_t_varchar2;
begin
  -- log('START', l_scope);
  f :=  apex_string.split(p_filename, '.');
  return to_number(apex_string.split(f(1), '_')(2) default null on conversion error);
exception 
when others then 
  return p_filename;
end extract_hole_from_file;




------------------------------------------------------------------------------
/**
 * Given a tournament session create random room assignments
 * We ideally want rooms of 4, never have a room of 1 and avoid rooms of 2
 * Scenarios:
 *   1 players: Room  1
 *   2 players: Room  2
 *   3 players: Room  3
 *   4 players: Room  4
 *   5 players: Rooms 3 + 2
 *   6 players: Rooms 3 + 3
 *   7 players: Rooms 4 + 3
 *   8 players: Rooms 4 + 4
 *   9 players: Rooms 3 + 3 + 3
 *  10 players: Rooms 4 + 3 + 3
 *  11 players: Rooms 4 + 4 + 3 = Rule 8 + 3
 *  12 players: Rooms 4 + 4 + 4 = Rule 8 + 4
 *  
 *  Logic:
 *   if P / 4 = trunc(P/4) then even number...
 *   else
 *       Rooms = P / 3 
 *       
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_tournament_session_id
 * @return
 */
procedure assign_rooms(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'assign_rooms';

  type room_rec_type is record (
      player_id  wmg_tournament_players.id%TYPE
    , room_no    number
  );

  type room_tbl_type is table of room_rec_type;
  l_room_id_tbl room_tbl_type := room_tbl_type();

  l_seed varchar2(100);
  l_rooms number;
  l_room  number;
  l_room_no  number;       -- sequence for the room that does not reset.
  l_last_room_no  number;  -- last room in the current slot that matches the l_room_no

  l_players  number;
  l_next_player  number;


  -- Search in l_room_id_tbl for a plaer without a room assignment
  function get_next_player return number
  is
    l_next_player number;
    l_player number;
    i number := 0;
    l_max number := l_room_id_tbl.count;
  begin

    l_player := trunc(dbms_random.value(1,l_room_id_tbl.count));
    loop
      i := i + 1;
      -- exit if the player's room has not been assigned and we're below the max number of player
      exit when l_room_id_tbl(l_player).room_no is null and i <= l_max;
      l_player := l_player + 1;
      if l_player > l_max then
        l_player := 1;
      end if;  
    end loop;

    $IF $$VERBOSE_OUTPUT $THEN
    log('.. tries ' || i || ', player ' || l_player, 'get_next_player()');
    $END    

    return l_player;
  end get_next_player;



  function players_on_room(p_room_no in number) return number
  is
    c number := 0;
  begin
    for i in 1 .. l_room_id_tbl.count
    loop
      if l_room_id_tbl(i).room_no = p_room_no then
        c:=c+1;
      end if;
    end loop;
    return c;
  end players_on_room;

begin
  log('BEGIN', l_scope);

  log('.. Stamp room assignments', l_scope);
  update wmg_tournament_sessions
     set rooms_defined_flag = 'Y' -- this will block new registrations
       , rooms_defined_by   = coalesce(sys_context('APEX$SESSION','APP_USER'),user) 
       , rooms_defined_on   = current_timestamp
    where id = p_tournament_session_id;

  commit; -- make sure no new registrations are accepted.

  -- Seed the random number generator
  l_seed := to_char(systimestamp,'YYYYDDMMHH24MISSFFFF');
  dbms_random.seed (val => l_seed);

  l_room_no := 1;       -- start with room 1


  for time_slots in (
    with slots_n as (
        select level n
         from dual
         connect by level <= 6
        )
    , slots as (
        select slot || ':00' d, slot t
        from (
            select lpad( (n-1)*4,2,0) slot
            from slots_n
            union all
            select '02' from dual
            union all
            select '18' from dual
        )
    )
    select d time_slot, t
    from slots
    order by t
  )
  loop

    select id, to_number(null) room_no
      bulk collect into l_room_id_tbl
      from wmg_tournament_players
     where tournament_session_id = p_tournament_session_id
       and time_slot = time_slots.time_slot
       and active_ind = 'Y';

    log('.. Assigning Rooms for ' || time_slots.time_slot || ' players ' || l_room_id_tbl.count, l_scope);

    l_players := l_room_id_tbl.count;
    l_rooms := rooms(p_player_count => l_players);
    l_room := 1;
    l_last_room_no := l_room_no;  -- Keep this in sync with room_no to indicate where the time slot starts

    log('.. Will need ' || l_rooms || ' Rooms', l_scope);

    <<room_distribution>>
    while l_players > 0
    loop


      if l_rooms = 1 then
        -- hey we only have one room, just assign the available players
        l_next_player := l_players;
      else
        l_next_player := get_next_player();
      end if;
      -- l_room_id_tbl(l_next_player).room_no := l_room;
      l_room_id_tbl(l_next_player).room_no := l_room_no;

      log('.. Room ' || l_room || ' = ' || players_on_room(l_room_no) || ' player(s)', l_scope);

      l_room := l_room + 1;  -- next room
      l_room_no := l_room_no + 1;  -- next room

      if l_room > l_rooms then
        l_room := 1;
        l_room_no := l_last_room_no; -- reset the room
      end if;

      l_players := l_players -1;

    end loop room_distribution;


    log('.. Saving room assignments', l_scope);
    forall idx in 1 .. l_room_id_tbl.count
      update wmg_tournament_players
        set room_no = l_room_id_tbl(idx).room_no
       where tournament_session_id = p_tournament_session_id
         and time_slot = time_slots.time_slot
         and id = l_room_id_tbl(idx).player_id;

    -- Make absolutely sure the next room_no in the sequence is brand new
    select max(room_no) + 1
      into l_room_no
      from wmg_tournament_players
     where tournament_session_id = p_tournament_session_id
       and time_slot = time_slots.time_slot;

  end loop; 

  log('.. Add room', l_scope);
  insert into wmg_tournament_rooms (
      tournament_session_id
    , time_slot
    , room_no
  )
  select distinct tournament_session_id
       , time_slot
       , room_no
    from wmg_tournament_players
   where tournament_session_id = p_tournament_session_id
     and active_ind = 'Y';


  log('.. Stamp room assignments date', l_scope);
  update wmg_tournament_sessions
     set rooms_defined_on   = current_timestamp
    where id = p_tournament_session_id;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end assign_rooms;





/**
 * Given a tournament session reset the room assignments and re-open registrations
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 8, 2023
 * @param p_tournament_session_id
 * @return
 */
procedure reset_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'assign_rooms';
  -- l_params logger.tab_param;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. removing room assignments', l_scope);
  update wmg_tournament_players
     set room_no = null
       , verified_score_flag = null
       , verified_by = null
       , verified_on = null
   where tournament_session_id = p_tournament_session_id;


  log('.. removing rooms', l_scope);
  delete from wmg_tournament_rooms where tournament_session_id = p_tournament_session_id;

  log('.. Undo room set flags and reset', l_scope);
  update wmg_tournament_sessions
  set rooms_open_flag = null
    , rooms_defined_flag = null
    , rooms_defined_by = null
    , rooms_defined_on = null
    , registration_closed_flag = null
    , completed_ind = 'N'
  where id = p_tournament_session_id;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end reset_room_assignments;






/**
 * Given a Discord ID see if this player's name matches one of the existing
 * players.
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created 
 * @param p_discord_id
 * @return
 */
procedure possible_player_match (
    p_discord_account in wmg_players.account%type
  , p_discord_name    in wmg_players.name%type
  , p_discord_id      in wmg_players.discord_id%type
  , x_players_tbl     in out nocopy tab_keyval_type
)
is
  l_scope  scope_t := gc_scope_prefix || 'possible_player_match';

  l_players_arr  varchar2(32767);
  l_players_tbl  tab_keyval_type := tab_keyval_type();
  l_found number := 0;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);


  if p_discord_id is null then
    null;  -- player is already match to a discord id
  else

    begin
      select 1 into l_found from wmg_players where discord_id = p_discord_id;
    exception
      when no_data_found then
        l_players_arr := null;
    end;

    if l_found = 0 then

      select id, player_name
       bulk collect into l_players_tbl
      from (
          select p.id, p.player_name
               , greatest(
                   utl_match.jaro_winkler_similarity(upper(p_discord_account), upper(p.player_name))
                 , utl_match.jaro_winkler_similarity(upper(p_discord_name), upper(p.player_name))
                 ) similarity
            from wmg_players_v p
           where discord_id is null
      )
      where similarity >= 74
      order by similarity desc
      fetch first 5 rows only;

    end if;

  end if;

  x_players_tbl := l_players_tbl;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end possible_player_match;





------------------------------------------------------------------------------
------------------------------------------------------------------------------
/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID make sure we're closing the
 * the correct week
 *  1. Must be current tournament
 *  2. Must be the current session
 *  3. Rooms must have been defined and open
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure validate_tournament_state (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'validate_tournament_state';

  l_id wmg_tournaments.id%type;
begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  if g_must_be_current then -- make sure it's the current tournament. Only false for historical loads
    begin
       -- is the tournament really the current tournament?
       select id
         into l_id
         from wmg_tournaments
        where id = p_tournament_id
          and current_flag = 'Y';
    exception
      when no_data_found then
        raise_application_error(e_not_current_tournament, 'Tournament (id ' || p_tournament_id || ') is not the current tournament');
    end;
  end if;

  begin
     -- is the tournament session correct and part of the current tournament
     select id
       into l_id
       from wmg_tournament_sessions
      where tournament_id = p_tournament_id
        and id = p_tournament_session_id;
  exception
    when no_data_found then
      raise_application_error(e_not_correct_session, 'That tournament session is not correct (id ' || p_tournament_session_id || '). Not the current session or not the correct tournament');
  end;

  log('END', l_scope);

end validate_tournament_state;






/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Snapshot the points for each player
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure snapshot_points (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'snapshot_points';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  merge into wmg_tournament_players tp
  using (
    select p.tournament_session_id
         , p.player_id
         , p.points
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
  ) p
  on (
        p.tournament_session_id = tp.tournament_session_id
    and p.player_id = tp.player_id
  )
  when matched then
    update
       set tp.points = nvl(tp.points_override, p.points);  -- if there's a points override, keep it.

  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('END', l_scope);

end snapshot_points;






/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Snapshot the System calculated badges for each player
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 16, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure snapshot_badges (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'snapshot_badges';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. Top 10 and 25 player badges');
  insert into wmg_player_badges (
      tournament_session_id
    , player_id
    , badge_type_code
    , badge_count
  )
  select p.tournament_session_id
       , p.player_id
       , case 
           when p.pos = 1 then 'FIRST'
           when p.pos = 2 then 'SECOND'
           when p.pos = 3 then 'THIRD'
           when p.pos >= 4 and  p.pos <= 10 then 'TOP10'
           when p.pos > 10 and  p.pos <= 25 then 'TOP25'
         end
       , 1
    from wmg_tournament_session_points_v p
   where p.tournament_session_id = p_tournament_session_id
     and p.pos <=25;


  insert into wmg_player_badges (
      tournament_session_id
    , player_id
    , badge_type_code
    , badge_count
  )
  with coconut as (
    select u.week
         , u.player_id, sum(case when par <= 0 then 1 else 0 end) under_par
         , sum(case when score = 1 then 1 else 0 end) hn1_count
      from wmg_rounds_unpivot_mv u
         , wmg_tournament_sessions ts
         , wmg_tournament_players tp
     where ts.week = u.week
       and ts.id = tp.tournament_session_id
       and tp.player_id = u.player_id
       and tp.issue_code is null  -- only players with no issues are eligible
       and ts.id = p_tournament_session_id
     having sum(case when par <= 0 and score is not null then 1 else 0 end) = 36
     group by u.week, u.player_id
  )
  , cactus as (
     select player_id, count(*) n
      from (
      select u.course_id || ':' || u.h h, u.score, any_value(u.player_id) player_id
        from wmg_rounds_unpivot_mv u
           , wmg_tournament_sessions ts
           , wmg_tournament_players tp
       where ts.id = tp.tournament_session_id
         and ts.week = u.week
         and tp.player_id = u.player_id
         and tp.issue_code is null  -- only players with no issues are eligible
         and ts.id = p_tournament_session_id
         and u.score = 1
      having count(*) = 1
       group by u.course_id || ':' || u.h, u.score
     )
     group by player_id
  )
  , duck as (
       select player_id, count(*) n
        from (
            select u.course_id || ':' || u.h h, u.score, u.player_id player_id
              from wmg_rounds_unpivot_mv u
                 , wmg_tournament_players tp
                 , wmg_tournament_sessions ts
             where ts.week = u.week
               and ts.id = tp.tournament_session_id
               and tp.player_id = u.player_id
               and tp.issue_code is null  -- only players with no issues are eligible
               and ts.id = p_tournament_session_id
               and u.score = 1
               and (u.course_id, u.h) in (
                     select u2.course_id, u2.h
                        -- , count(*) possible_ducks
                       from wmg_rounds_unpivot_mv u2
                          , wmg_tournament_sessions ts2
                          , wmg_tournament_players tp2
                      where ts2.week = u2.week
                        and ts2.id = tp2.tournament_session_id
                        and u2.player_id = tp2.player_id
                        and tp2.issue_code is null  -- only players with no issues are eligible
                        and ts2.id = p_tournament_session_id
                        and u2.score = 1 -- ace score
                        having count(*) between 2 and 2 
                        group by u2.course_id, u2.h
               )
       )
       group by player_id
  )
  , beetle as (
     select u.player_id, count(*) n
       from wmg_rounds_unpivot_mv u
          , wmg_tournament_players tp
          , wmg_tournament_sessions ts
      where ts.week = u.week
        and ts.id = tp.tournament_session_id
        and tp.player_id = u.player_id
        and tp.issue_code is null  -- only players with no issues are eligible
        and ts.id = p_tournament_session_id
        and (u.course_id, u.h, u.score) in (
          select u2.course_id, u2.h, u2.score
            from wmg_rounds_unpivot_mv u2
               , wmg_tournament_sessions ts2
           where ts2.week = u2.week
             and ts2.id = p_tournament_session_id
             and (u2.course_id, u2.h, u2.score) in (
                 select u3.course_id, u3.h, min(u3.score) possible_beetles
                   from wmg_rounds_unpivot_mv u3
                      , wmg_tournament_sessions ts3
                  where ts3.week = u3.week
                    and ts3.id = p_tournament_session_id
                    and u3.score > 1 -- non-ace score
                  group by u3.course_id, u3.h
           )
          having count(*) <= 3  -- only when less than 3 people got it
           group by u2.course_id, u2.h, u2.score
      )
     group by u.player_id
  )
  , diamond as (
    select u.player_id, count(*) aces
          from wmg_rounds_unpivot_mv u
             , wmg_tournament_players tp
             , wmg_tournament_sessions ts
         where ts.week = u.week
           and ts.id = tp.tournament_session_id
           and tp.player_id = u.player_id
           and tp.issue_code is null  -- only players with no issues are eligible
           and ts.completed_ind = 'N' -- only live results
           and ts.id = p_tournament_session_id
           and u.score = 1
         group by u.player_id
         having count(*) in (
             select max(sum(u2.score)) aces
              from wmg_rounds_unpivot_mv u2
                 , wmg_tournament_sessions ts2
              where ts2.week = u2.week
                and u2.score = 1
                and ts2.id = p_tournament_session_id
              group by u2.player_id
         )
  )
  select p.tournament_session_id
       , p.player_id
       , 'COCONUT' badge
       , 1 badge_count
    from wmg_tournament_session_points_v p
       , coconut
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = coconut.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'CACTUS' badge
       , cactus.n badge_count
    from wmg_tournament_session_points_v p
       , cactus
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = cactus.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'DUCK' badge
       , duck.n badge_count
    from wmg_tournament_session_points_v p
       , duck
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = duck.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'BEETLE' badge
       , beetle.n badge_count
    from wmg_tournament_session_points_v p
       , beetle
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = beetle.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'DIAMOND' badge
       , 1 badge_count
    from wmg_tournament_session_points_v p
       , diamond
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = diamond.player_id;

  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('END', l_scope);

end snapshot_badges;







/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Discard the lowest points fom each player
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure discard_points (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'discard_points';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. restore previously discarded session', l_scope);
  update wmg_tournament_players
     set discarded_points_flag = null
   where id in (
      with curr_tournament as (
        select id
          from wmg_tournaments
         where id = p_tournament_id
      )
      , discard as (
        select floor( count(*)/3 ) drop_count
             , count(*) total_sessions
          from wmg_tournament_sessions ts
             , curr_tournament
         where ts.tournament_id = curr_tournament.id
         and ts.registration_closed_flag = 'Y'
      )
      select tournament_player_id
      from (
          select p.id tournament_player_id
               , p.player_id
               , p.points
               , p.discarded_points_flag
               , ts.tournament_id
               , ts.round_num
               , ts.week
               , ts.session_date
      --         , sum(case when p.discarded_points_flag = 'Y' then 0 else p.points end) season_total
               , row_number() over (partition by p.player_id order by p.points nulls first, ts.session_date) discard_order
               , count(*) over (partition by p.player_id) sessions_played
          from wmg_tournament_sessions ts
             , wmg_tournament_players p
             , curr_tournament
          where ts.id = p.tournament_session_id
            and ts.tournament_id = curr_tournament.id
          -- and p.player_id in ( 22, 24, 26)
          order by p.player_id, ts.session_date
      )
       , discard
       -- (total_sessions - sessions_played) is needed in case they did not participate in all sessions
       where (total_sessions >= sessions_played and discard_order > (discard.drop_count - (total_sessions - sessions_played)))
    )
   and discarded_points_flag = 'Y';
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('.. Discarding session', l_scope);

  update wmg_tournament_players
     set discarded_points_flag = 'Y' 
   where id in (
      with curr_tournament as (
        select id
          from wmg_tournaments
         where id = p_tournament_id
      )
      , discard as (
        select floor( count(*)/3 ) drop_count
             , count(*) total_sessions
          from wmg_tournament_sessions ts
             , curr_tournament
         where ts.tournament_id = curr_tournament.id
         and ts.registration_closed_flag = 'Y'
      )
      select tournament_player_id
      from (
          select p.id tournament_player_id
               , p.player_id
               , p.points
               , p.discarded_points_flag
               , ts.tournament_id
               , ts.round_num
               , ts.week
               , ts.session_date
      --         , sum(case when p.discarded_points_flag = 'Y' then 0 else p.points end) season_total
               , row_number() over (partition by p.player_id order by p.points nulls first, ts.session_date) discard_order
               , count(*) over (partition by p.player_id) sessions_played
          from wmg_tournament_sessions ts
             , wmg_tournament_players p
             , curr_tournament
          where ts.id = p.tournament_session_id
            and ts.tournament_id = curr_tournament.id
          -- and p.player_id in ( 22, 24, 26)
          order by p.player_id, ts.session_date
      )
       , discard
       -- (total_sessions - sessions_played) is needed in case they did not participate in all sessions
       where (total_sessions >= sessions_played and discard_order <= (discard.drop_count - (total_sessions - sessions_played)))
    );

  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('.. Un-Discard penalty points', l_scope);
  -- Negative points, -1 will always be sticky and cannot be discarded
  -- find discarded negative numbers and bring them back

  update wmg_tournament_players
     set discarded_points_flag = null
   where id in (
      with curr_tournament as (
        select id
          from wmg_tournaments
         where id = p_tournament_id
      )
      select p.id tournament_player_id
          from wmg_tournament_sessions ts
             , wmg_tournament_players p
             , curr_tournament
          where ts.id = p.tournament_session_id
            and ts.tournament_id = curr_tournament.id
            and p.points < 0  -- find discarded negative numbers and bring them back
            and p.discarded_points_flag = 'Y'
    );

  log('END', l_scope);

end discard_points;




/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Promote players to their new status: Ama, Semi, Pro
 *
 * Guideline:
 *
 *    PRO status can be achieved by the following:
 *    (1x) Top 5 -or- (3x) Top 10 
 *
 *    Players with 85 season points or more retained PRO status from Season 8
 *
 *    SEMI-PRO status can be achieved by the following:
 *    (1x) Top 15  -or- (3x) Top 20 with 9 pts.
 *
 **
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure promote_players (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'promote_players';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. Advance all players that played from NEW to Amateur', l_scope);
  update wmg_players
     set rank_code = 'AMA'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.points > 0  -- new players that actually played
       and p.rank_code = 'NEW'
   );

  log(SQL%ROWCOUNT || ' rows updated.', l_scope);


  /*
   *    RISING status can be achieved by the following:
   *    (1x) Top 25  -or- .. TBD
   */

  log('.. Advance to RISING', l_scope);
  update wmg_players
     set rank_code = 'RISING'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 25
       and p.rank_code not in ('PRO', 'SEMI', 'RISING')
   );

  /*
   *    SEMI-PRO status can be achieved by the following:
   *    (1x) Top 10  -or- TBD
   */

  log('.. Advance to SEMI-PRO', l_scope);
  update wmg_players
     set rank_code = 'SEMI'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 10
       and p.rank_code not in ('PRO', 'SEMI')
   );

  log(SQL%ROWCOUNT || ' rows updated.', l_scope);



  /*
   *    PRO status can be achieved by the following:
   *    (1x) Top 3 -or- TBD
   */

  log('.. Advance to PRO', l_scope);
  update wmg_players
     set rank_code = 'PRO'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 3
       and p.rank_code != 'PRO'
   );

  log(SQL%ROWCOUNT || ' rows updated.', l_scope);



  log('END', l_scope);

end promote_players;




/**
 * Given a tournament ID perform the necessary steps to close the week
 *  1. Validate the tournamet and session are correct
 *  2. Calculate points and assign to each player
 *  3. Flag Points to discard
 *  4. Set session as completed
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 20, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure close_tournament_session (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'close_tournament_session';
begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. validations', l_scope);
  validate_tournament_state(
      p_tournament_id => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );


  log('.. snaptshot points', l_scope);
  snapshot_points(
      p_tournament_id         => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );

  log('.. discarding points', l_scope);
  discard_points(
      p_tournament_id         => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );

  log('.. Add Unicorns', l_scope);
  add_unicorns(
     p_tournament_session_id => p_tournament_session_id
  );

  log('.. Add Badges', l_scope);
  snapshot_badges(
      p_tournament_id         => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );

  if g_must_be_current then -- make sure it's the current tournament. Only false for historical loads
    log('.. promote players', l_scope);
    promote_players(
        p_tournament_id         => p_tournament_id
      , p_tournament_session_id => p_tournament_session_id
    );
  end if;


  log('.. close tournament session', l_scope);
  update wmg_tournament_sessions ts
     set ts.completed_ind = 'Y'
       , ts.completed_on = current_timestamp
   where ts.id = p_tournament_session_id
     and ts.tournament_id = p_tournament_id;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end close_tournament_session;



/**
 * Detect when a sesson is over.
 *  * If we have a p_tournament_session_id then we're actively in a season
 *  * Or if the very las round is round 12 and it's completed
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 5, 2024
 * @param p_tournament_session_id
 * @return boolean
 */
function is_season_over(
   p_tournament_session_id in wmg_tournament_sessions.id%type
)
return boolean
is
  $IF $$LOGGER $THEN
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'is_season_over';
  l_params logger.tab_param;
  $END

  l_tournament_session_id wmg_tournament_sessions.id%type;
  l_round_num wmg_tournament_sessions.round_num%type;
  l_completed_ind wmg_tournament_sessions.completed_ind%type;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- logger.log('BEGIN', l_scope, null, l_params);


  if nvl(p_tournament_session_id,-1) != -1 then
    return false;
  end if;

  select id, round_num, completed_ind
    into l_tournament_session_id, l_round_num, l_completed_ind
    from wmg_tournament_sessions
   where week not like '%B%'  -- skip the special inbetween tournaments
   order by session_date desc
   fetch first 1 rows only;

  if l_round_num = 12 and l_completed_ind = 'Y' then
    return true;
  end if;

  return false;

  -- logger.log('END', l_scope, null, l_params);

  exception
    when no_data_found then
      -- no real previous season
      return false;

    when OTHERS then
      $IF $$LOGGER $THEN
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      $END
      -- x_result_status := mm_api.g_ret_sts_unexp_error;
      raise;
end is_season_over;





/**
 * Given a finishing rank, calculate the score the player will receive
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created 
 * @param p_rank         rank the player finished
 * @param p_percent_rank player percent rank (the top 10 do NOT use percent rank)
 * @param p_player_count players in the field
 * @return
 */
function score_points(
    p_rank         in number
  , p_percent_rank in number
  , p_player_count in number
)
return number
is
  l_scope  scope_t := gc_scope_prefix || 'score_points';
  -- l_params logger.tab_param;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- log('BEGIN', l_scope);

  if p_rank <= 10 then
    return 
      case p_rank
      when  1 then 25
      when  2 then 21 
      when  3 then 18 
      when  4 then 16 
      when  5 then 15 
      when  6 then 14 
      when  7 then 13 
      when  8 then 12 
      when  9 then 11 
      when 10 then 10
      end;
  else
    if p_player_count < 21 then
     return 20 - p_rank;
    elsif p_percent_rank <= 0.111 then
      return 9;
    elsif p_percent_rank <= 0.222 then
      return 8;
    elsif p_percent_rank <= 0.333 then
      return 7;
    elsif p_percent_rank <= 0.444 then
      return 6;
    elsif p_percent_rank <= 0.555 then
      return 5;
    elsif p_percent_rank <= 0.666 then
      return 4;
    elsif p_percent_rank <= 0.777 then
      return 3;
    elsif p_percent_rank <= 0.888 then
      return 2;
    else
      return 1;
    end if;
  end if;


  -- log('END', l_scope);

exception
  when OTHERS then
    log('Unhandled Exception', l_scope);
    raise;
end score_points;





/**
 * Given a player keep track if their easy or hard score card is missing
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 20, 2023
 * @param p_player_id
 * @param p_course_id
 * @param p_remove
 * @return
 */
procedure score_entry_verification(
   p_week      in wmg_rounds.week%type
 , p_player_id in wmg_players.id%type
 , p_course_id in number default null
 , p_remove    in boolean default false
)
is
  l_scope  scope_t := gc_scope_prefix || 'score_entry_verification';

  l_course_rec  wmg_courses%rowtype;
begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  if p_course_id is not null then
    select *
      into l_course_rec
      from wmg_courses
     where id = p_course_id;
  end if;


  if p_remove then
    delete 
      from wmg_verification_queue 
     where week = p_week and (easy_player_id = p_player_id or hard_player_id = p_player_id);
  else

    merge into wmg_verification_queue q
    using (
      select r.week
           , r.players_id
           , r.course_id
           , l_course_rec.course_mode course_mode
        from wmg_rounds r
       where r.week = p_week
         and r.players_id = p_player_id
         and r.course_id = l_course_rec.id
    ) r
    on (
          q.week = r.week
      and (q.easy_player_id = r.players_id or q.hard_player_id = r.players_id)
    )
    when matched then
      update
         set q.easy_player_id = decode(r.course_mode, 'E', r.players_id, q.easy_player_id)
           , q.hard_player_id = decode(r.course_mode, 'H', r.players_id, q.hard_player_id)
    when not matched then
      insert (
          week
        , easy_player_id
        , hard_player_id
      )
      values (
          r.week
        , decode(r.course_mode, 'E', r.players_id, null)
        , decode(r.course_mode, 'H', r.players_id, null)
      );
  end if;  

  -- delete the finished entries
  delete from wmg_verification_queue
   where week = p_week
     and easy_player_id = p_player_id
    and hard_player_id = p_player_id;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end score_entry_verification;





/**
 * Given a player action (noshow, noscore, vialoation), (S)et | (C)lear according 
 * to the operation
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 11, 2023
 * @param p_player_id
 * @param p_issue_code: NOSHOW, NOSCORE, INFRACTION
 * @param p_operation: (S)et | (C)lear
 * @return
 */
procedure set_verification_issue(
   p_player_id  in wmg_players.id%type
 , p_issue_code in varchar2 default null
 , p_operation  in varchar2 default null  -- (S)et | (C)lear
 , p_from_ajax  in boolean default true
)
is
  l_scope  scope_t := gc_scope_prefix || 'set_verification_issue';

  l_issue_code wmg_tournament_players.issue_code%type;
  l_issue_rec wmg_issues%rowtype;
  l_operation  varchar2(1);  -- (S)et | (C)lear
begin
  -- logger.append_param(l_params, 'p_player_id', p_player_id);
  -- logger.append_param(l_params, 'p_issue_code', p_issue_code);
  -- logger.append_param(l_params, 'p_operation', p_operation);
  log('BEGIN', l_scope);
  log('.. p_player_id:'  || p_player_id, l_scope);
  log('.. p_issue_code:' || p_issue_code, l_scope);
  log('.. p_operation:'  || p_operation, l_scope);

  if p_issue_code is null then
    l_issue_code := c_issue_noshow;  -- the default issue value
    l_operation := 'S';    -- if we had no value we're always setting
  else
    l_issue_code := p_issue_code;
    l_operation := p_operation;
  end if;

  log('.. l_issue_code:' || l_issue_code, l_scope);
  log('.. l_operation:' || l_operation, l_scope);

  select *
    into l_issue_rec
    from wmg_issues
   where code = l_issue_code;

  -- toggle the verification
  update wmg_tournament_players
   set issue_code = case
                      when l_operation = 'C' then null
                      else l_issue_code
                    end
     , verified_score_flag = case when l_operation = 'C' then null else 'Y' end
     , verified_by         = case when l_operation = 'C' then null else sys_context('APEX$SESSION','APP_USER') end
     , verified_on         = case when l_operation = 'C' then null else current_timestamp end
     , verified_note       = 
        case 
          when l_operation = 'C' then null 
          else l_issue_rec.description
        end
      , points_override = 
        case 
          when l_operation = 'C' then null 
          else l_issue_rec.tournament_points_override
        end
    where id = p_player_id;

  log('.. rows:' || SQL%ROWCOUNT, l_scope);

  if p_from_ajax then
    apex_json.open_object; -- {
      apex_json.write('success', true);
    apex_json.close_object; -- }
  end if;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      if p_from_ajax then
        apex_json.open_object; -- {
          apex_json.write('success', false);
          apex_json.write('error', sqlerrm);
        apex_json.close_object; -- }
      else
        raise;
      end if;
end set_verification_issue;





/**
 * Given a player verify the room if all the other players have been verified
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 13, 2023
 * @param p_tournament_player_id
 * @return
 */
procedure verify_players_room(
   p_tournament_player_id  in wmg_tournament_players.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'verify_players_room';

  l_tournament_session_id wmg_tournament_sessions.id%type;
  l_verified_score_flag   wmg_tournament_rooms.verified_score_flag%type;
  l_time_slot wmg_tournament_rooms.time_slot%type;
  l_room_no   wmg_tournament_rooms.room_no%type;
begin
  -- logger.append_param(l_params, 'p_player_id', p_player_id);
  -- logger.append_param(l_params, 'p_issue_code', p_issue_code);
  -- logger.append_param(l_params, 'p_operation', p_operation);
  log('BEGIN', l_scope);
  log('.. p_tournament_player_id:'  || p_tournament_player_id, l_scope);

  <<room_status>>
  begin
    -- If all the rows match their verification then l_verified_score_flag will have the value
    -- usually Y
    -- But if there are too_many_rows, we see if there's at least one E(rror)
    select distinct tournament_session_id, verified_score_flag, time_slot, room_no
      into l_tournament_session_id, l_verified_score_flag, l_time_slot, l_room_no
    from wmg_tournament_players
    where (tournament_session_id, time_slot, room_no) in (
        select tournament_session_id, time_slot, room_no
          from wmg_tournament_players
         where id = p_tournament_player_id
    );

  exception
  when TOO_MANY_ROWS then
    l_verified_score_flag := null;

    -- if there's at least one E on the room keep the room with an E
    select case when count(*) > 0 then 'E' else null end
      into l_verified_score_flag
      from wmg_tournament_players
      where (tournament_session_id, time_slot, room_no) in (
          select tournament_session_id, time_slot, room_no
            from wmg_tournament_players
           where id = p_tournament_player_id
      )
       and verified_score_flag = 'E';

  end room_status;

  update wmg_tournament_rooms
     set verified_score_flag = l_verified_score_flag
   where tournament_session_id = l_tournament_session_id
     and time_slot = l_time_slot
     and room_no = l_room_no;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end verify_players_room;





/**
 * Given a tournament ID, Tournament session and Time Slot
 * close out the ability to enter scores by setting the "verified" flag on
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 6, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @param p_time_slot
 * @return
 */
procedure close_time_slot_time_entry (
    p_tournament_session_id in wmg_tournament_sessions.id%type
  , p_time_slot             in wmg_tournament_players.time_slot%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'close_time_slot_time_entry';
  l_issue_rec wmg_issues%rowtype;

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);


  -- Send channel notifications of the people thay did not send a notification
  wmg_notification.notify_channel_about_players(
      p_tournament_session_id => p_tournament_session_id
    , p_time_slot => p_time_slot
  );


  begin
      select *
        into l_issue_rec
        from wmg_issues
       where code = c_issue_noshow;
  exception 
    -- protect against errors in case the issue is gone
    when no_data_found then
      l_issue_rec.code := c_issue_noshow;
      l_issue_rec.description := 'No show or No Score';
  end;

  log('.. loop throough pending time entries', l_scope);
  for p in (
    select p.week
         , p.player_id
         , p.tournament_player_id
         , p.player_name
         , p.time_slot
         , p.room_no
         , r.total_score
         , r.round_created_on
         , r.easy_scorecard
         , r.hard_scorecard
         , r.total_scorecard
         -- , r.round_created_on
         , p.verified_score_flag
         , p.verified_note
         , p.verified_by
         , p.verified_on
      from wmg_tournament_results_v r
         , wmg_tournament_player_v p
     where p.week = r.week (+)
       and p.player_id = r.player_id (+)
       and p.tournament_session_id = p_tournament_session_id
       and p.time_slot = p_time_slot
       and p.active_ind = 'Y'            -- still registed
       and p.verified_score_flag is null -- not verified yet
       and p.issue_code is null          -- no issues raised
       and r.total_scorecard is null     -- No scores entered
  )
  loop


    /*  WE DO NOT WANT SCORE AT THIS TIME
    -- if p.round_created_on is null then

      -- add empty rounds because there was no round created
      insert into wmg_rounds(week, course_id, players_id, room_name
         , override_score
         , override_reason
         , override_by
         , override_on
        )
      select p.week
           , c.course_id
           , p.player_id
           , 'WMGT' || p.room_no
           , 36 override_score
           , 'Scored not entered on time' override_reason
           , 'SYSTEM' override_by
           , current_timestamp override_on
        from wmg_tournament_courses c
       where c.tournament_session_id = p_tournament_session_id
       order by c.course_no;

    -- end if;
    */

    /*
        No automatic points yet
         , points = -1           -- this will make the -1 visual before the tournament closes
         , points_override = -1  -- this will maintain the -1 when the tournament closes
    */
    update wmg_tournament_players
       set verified_by = 'SYSTEM'
         , verified_on = current_timestamp
         , verified_note = l_issue_rec.description
         , verified_score_flag = 'Y'
         , issue_code = l_issue_rec.code
         , points_override = l_issue_rec.tournament_points_override
     where id = p.tournament_player_id;

    verify_players_room(p_tournament_player_id => p.tournament_player_id );

    commit;  -- just in case something fails

  end loop;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end close_time_slot_time_entry;





/**
 * Create a Job `WMGT_CLOSE_SCORING` that will be called on-demand
 * at the time rooms are defined and open
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 6, 2023
 * @param x_result_status
 * @return
 */
procedure create_close_scoring_job(
    p_tournament_session_id in wmg_tournament_sessions.id%type
  , p_slot_number           in wmg_tournament_players.time_slot%type
  , p_time_slot             in wmg_tournament_players.time_slot%type
  , p_job_run               in timestamp with time zone
)
is
  l_scope  scope_t := gc_scope_prefix || 'create_close_scoring_job';

  l_job_name  varchar2(100);
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

/*
PROCEDURE create_job(
  job_name                IN VARCHAR2,
  job_type                 IN VARCHAR2,
  job_action              IN VARCHAR2,
  number_of_arguments     IN PLS_INTEGER              DEFAULT 0,
  start_date              IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  event_condition         IN VARCHAR2                 DEFAULT NULL,
  queue_spec              IN VARCHAR2,
  end_date                IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  job_class               IN VARCHAR2              DEFAULT '$SCHED_DEFAULT$',
  enabled                 IN BOOLEAN                  DEFAULT FALSE,
  auto_drop               IN BOOLEAN                  DEFAULT TRUE,
  comments                IN VARCHAR2                 DEFAULT NULL,
  credential_name         IN VARCHAR2                 DEFAULT NULL,
  destination_name        IN VARCHAR2                 DEFAULT NULL);
*/

  l_job_name := 'WMGT_CLOSE_SCORING_' || p_tournament_session_id || '_' || p_slot_number;
  log('.. scheduling ' || l_job_name, l_scope);

  sys.dbms_scheduler.create_job (
      job_name        => l_job_name
    , job_type        => 'STORED_PROCEDURE'
    , job_action      => 'wmg_util.close_time_slot_time_entry'
    , number_of_arguments => 2
    , start_date      => p_job_run
    , enabled         => false
    , auto_drop       => true
    , comments        => 'Job that closes scoring 4 hoours after the time_slot begins'
  );

  sys.dbms_scheduler.set_job_argument_value (
     job_name          => l_job_name
   , argument_position => 1
   , argument_value    => p_tournament_session_id
  );

  sys.dbms_scheduler.set_job_argument_value (
      job_name          => l_job_name
    , argument_position => 2
    , argument_value    => p_time_slot
  );

  -- sys.dbms_scheduler.run_job(job_name => l_job_name, use_current_session => false);
  sys.dbms_scheduler.enable(name => l_job_name);


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unexpected error', l_scope);
      raise;
end create_close_scoring_job;





/**
 * Create a Job `WMGT_CLOSE_SCORING` that will be called on-demand
 * at the time rooms are defined and open
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 6, 2023
 * @param x_result_status
 * @return
 */
procedure submit_close_scoring_jobs(
    p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'submit_close_scoring_jobs';
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  for slots in (
    with slots_n as (
        select level n
         from dual
         connect by level <= 6
        )
    , slots as (
        select slot || ':00' d, slot t
        from (
            select lpad( (n-1)*4,2,0) slot
            from slots_n
            union all
            select '02' from dual
            union all
            select '18' from dual
        )
    )
    , ts as (
        select s.session_date
        from wmg_tournament_sessions s
       where id = p_tournament_session_id
    )
    select t
         , slots.t || ':00' time_slot
         , to_utc_timestamp_tz(to_char(ts.session_date, 'yyyy-mm-dd') || 'T' || slots.t || ':00') UTC
         , to_utc_timestamp_tz(to_char(ts.session_date, 'yyyy-mm-dd') || 'T' || slots.t || ':00') + INTERVAL '4' HOUR job_run
    from ts
       , slots
    order by t
  )
  loop
    create_close_scoring_job(
        p_tournament_session_id => p_tournament_session_id
      , p_slot_number => slots.t
      , p_time_slot   => slots.time_slot
      , p_job_run     => slots.job_run
    );
  end loop;

  log('END', l_scope);

  exception
    when OTHERS then
      raise;
end submit_close_scoring_jobs;





/**
 * Up to the given tournament_session, find the new unicorns
 * Unicorn: Something rare and unique. In this case a unicorn is a 
 * unique Hole in One made after 5 times a tournament was played
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 31, 2023
 * @param x_result_status
 * @return
 */
procedure add_unicorns(
    p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'add_unicorns';
  l_attempts number;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  for u in (
  with course_play_count as (
        select c.course_id, count(*) play_count, max(s.week) week, max(s.session_date) session_date
        from wmg_tournament_courses c
           , wmg_tournament_sessions s
        where s.id = c.tournament_session_id
          and c.course_id in (select course_id from wmg_tournament_courses where tournament_session_id = p_tournament_session_id)
          and s.completed_ind = 'Y'
        group by c.course_id
  )
  , courses_played as (
      select c.course_id, c.name course_name, cc.play_count, cc.week, cc.session_date
      from wmg_courses_v  c
         , course_play_count cc
      where c.course_id = cc.course_id
        and cc.play_count >= 5  -- filter qualifying courses. 5 x or more
  )
  select uni.course_name
       , uni.course_id
       , uni.play_count
       , uni.h
       , uni.week
       , (select u.player_id
        from wmg_rounds_unpivot_mv u
       where u.course_id = uni.course_id
         and u.h = uni.h
         and u.week <= uni.week
         and u.player_id != 0 -- skip system records
         and u.score = 1) ace_by_player_id
      /*
        -- for debuging
       , (select listagg(u.week || ' - ' || p.player_name, ',') player_name
        from wmg_rounds_unpivot_mv u
           , wmg_players_v p
       where u.player_id = p.id
         and u.course_id = uni.course_id
         and u.h = uni.h
         and u.week <= uni.week
         and u.score = 1) ace_by
        */
  from (
      select u.course_id, cp.course_name, cp.play_count, u.h
           , max(u.week) week
        from wmg_rounds_unpivot_mv u
           , courses_played cp
        where u.score = 1
          and u.course_id = cp.course_id
          and u.player_id != 0 -- skip system records
          and cp.play_count >= 5
          and u.week in (select ts.week from wmg_tournament_sessions ts where ts.session_date <= cp.session_date)
          and (u.course_id, u.h) not in (select course_id, h from wmg_player_unicorns) -- eliminate previous unicorns
        group by u.course_id, cp.course_name, cp.play_count, u.h
       having count(*) = 1
  ) uni
  order by uni.course_name, uni.h
  )
  loop

    -- count the number of attempts at the hole before the unicorn
    select count(*) attempts
      into l_attempts
     from wmg_rounds_unpivot_mv a
     where a.course_id = u.course_id
       and a.h = u.h
       and a.week in (
          select ts.week                       -- collect all the weeks before the unicorn and including
            from wmg_tournament_sessions ts 
           where ts.session_date <= (          -- get all the sessions before that
             select wts.session_date           -- date the unicorn was achived
               from wmg_tournament_sessions wts 
              where wts.week = u.week
           )
         );

    insert into wmg_player_unicorns (
       course_id
     , player_id
     , h
     , attempt_count
     , score_tournament_session_id
     , award_tournament_session_id
    )
    select u.course_id
       , u.ace_by_player_id
       , u.h
       , l_attempts
       , ts.id                    score_tournament_session_id
       , p_tournament_session_id  award_tournament_session_id
     from wmg_tournament_sessions ts
     where ts.week = u.week;

    log('.. Added ' || SQL%ROWCOUNT, l_scope);
  end loop;


  log('.. Updating repeat unicorns, ie commoncorns', l_scope);
  for courses in (
    with course_play_count as (
          select c.course_id, count(*) play_count, max(s.week) week, max(s.session_date) session_date
          from wmg_tournament_courses c
             , wmg_tournament_sessions s
          where s.id = c.tournament_session_id
            and s.session_date <= (select ts.session_date from wmg_tournament_sessions ts where ts.id = p_tournament_session_id)
            and c.course_id in (
              select c.course_id
                from wmg_tournament_sessions ts
                   , wmg_tournament_courses c
                 where ts.id = c.tournament_session_id 
                   and ts.id = p_tournament_session_id
                )
          group by c.course_id
    )
    , courses_played as (
        select c.course_id, c.name course_name, cc.play_count, cc.week, cc.session_date
        from wmg_courses_v  c
           , course_play_count cc
        where c.course_id = cc.course_id
          and cc.play_count >= 5
    )
    select course_id
      from courses_played
  )
  loop
    -- for each course and for each hole, update the number of 
    -- unicorn repeats
    update wmg_player_unicorns pu
    set pu.repeat_count = (
       select case when n = 1 then null else n -1 end
         from (
          select count(*) n
          from wmg_rounds_unpivot_mv u
             , wmg_players_v p
          where u.player_id = p.id
            and u.course_id = pu.course_id
            and u.h = pu.h
            and u.score = 1
      )
    )
    where pu.course_id = courses.course_id;

  end loop;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end add_unicorns;




procedure unavailable_application (p_message in varchar2 default null)
is
  c_default_message varchar2(200) := 'This application is curently being updated and will return shortly';
begin
  htp.p('<html>'
    || '<head>'
    || '<link rel="stylesheet" href="/i/22.2.0/app_ui/css/Core.min.css?v=22.2.4" type="text/css">'
    || '<link rel="stylesheet" href="/i/22.2.0/app_ui/css/Theme-Standard.min.css?v=22.2.4" type="text/css">'
    || '<link rel="stylesheet" href="/i/22.2.0/themes/theme_42/22.2/css/Redwood.min.css?v=22.2.4" type="text/css">'
    -- || '<link rel="stylesheet" href="/i/themes/theme_42/1.6/css/css/Vita.min.css" type="text/css">'
    -- || '<link rel="stylesheet" href="r/mastermind/557/files/theme/42/v70/17084618446454482.css" type="text/css">'
    || '<style>
    .t-Alert--colorBG.t-Alert--warning {
      background-color: #fef7e0;
      color: #000000;
    }
    .t-Alert--warning .t-Alert-icon .t-Icon {
      color: #FBCE4A;
    }
    .t-Alert--warning.t-Alert--horizontal .t-Alert-icon {
      background-color: rgba(251, 206, 74, 0.15);
    }
    </style>'
    || '</head>'
  );

  htp.p(
    '<div class="t-Body">'
    );

  htp.p(
     '<div class="t-Alert t-Alert--colorBG t-Alert--horizontal t-Alert--defaultIcons t-Alert--warning"'
  || ' style="width: 720px; margin: 40px auto;"' || ' id="unavailableRegion">'
  || '  <div class="t-Alert-wrap">'
  || '    <div class="t-Alert-icon">'
  || '      <span class="t-Icon "></span>'
  || '    </div>'
  || '    <div class="t-Alert-content">'
  || '      <div class="t-Alert-header">'
  || '        <h2 class="t-Alert-title" id="unavailableRegion_heading">Unavailable</h2>'
  || '      </div>'
  || '      <div class="t-Alert-body">' || nvl(p_message, c_default_message) || '</div>'
  || '    </div>'
  || '    <div class="t-Alert-buttons"></div>'
  || '  </div>'
  || '</div>'
  );

  htp.p(
    '</div>'
  ||  '</html>'
  );
end unavailable_application;


----------------------------------------
/**
 * {description here}
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 21, 2024
 * @param x_result_status
 * @return
 */
procedure save_stream_scores(
    p_stream_id wmg_streams.id%type
  , p_scores_json in out nocopy varchar2
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'save_stream_scores';
  l_params logger.tab_param;

  l_stream_rec       wmg_streams%rowtype;
  l_stream_round_rec wmg_stream_round%rowtype;

begin
  logger.append_param(l_params, 'p_stream_id', p_stream_id);
  logger.append_param(l_params, 'p_scores_json', p_scores_json);
  logger.log('BEGIN', l_scope, null, l_params);

  select *
    into l_stream_rec
    from wmg_streams
   where id = p_stream_id;

  select *
    into l_stream_round_rec
    from wmg_stream_round
   where stream_id = p_stream_id;


  /* Merge scores for player 1 "e" */
  merge into wmg_stream_scores sc
  using (
    select s.id stream_id
         , sr.current_course_id course_id
         , sr.current_round
         , s.player1_id player_id
         , nullif(jt.es1, 0) es1
         , nullif(jt.es2, 0) es2
         , nullif(jt.es3, 0) es3
         , nullif(jt.es4, 0) es4
         , nullif(jt.es5, 0) es5
         , nullif(jt.es6, 0) es6
         , nullif(jt.es7, 0) es7
         , nullif(jt.es8, 0) es8
         , nullif(jt.es9, 0) es9
         , nullif(jt.es10, 0) es10
         , nullif(jt.es11, 0) es11
         , nullif(jt.es12, 0) es12
         , nullif(jt.es13, 0) es13
         , nullif(jt.es14, 0) es14
         , nullif(jt.es15, 0) es15
         , nullif(jt.es16, 0) es16
         , nullif(jt.es17, 0) es17
         , nullif(jt.es18, 0) es18
         , total_easy
    from wmg_streams s
       , wmg_stream_round sr
       , json_table(
          p_scores_json, -- This is the JSON string containing the scores
          '$'
          columns (
            es1 NUMBER PATH '$.es1',
            es2 NUMBER PATH '$.es2',
            es3 NUMBER PATH '$.es3',
            es4 NUMBER PATH '$.es4',
            es5 NUMBER PATH '$.es5',
            es6 NUMBER PATH '$.es6',
            es7 NUMBER PATH '$.es7',
            es8 NUMBER PATH '$.es8',
            es9 NUMBER PATH '$.es9',
            es10 NUMBER PATH '$.es10',
            es11 NUMBER PATH '$.es11',
            es12 NUMBER PATH '$.es12',
            es13 NUMBER PATH '$.es13',
            es14 NUMBER PATH '$.es14',
            es15 NUMBER PATH '$.es15',
            es16 NUMBER PATH '$.es16',
            es17 NUMBER PATH '$.es17',
            es18 NUMBER PATH '$.es18',
            total_easy NUMBER PATH '$.total_easy'
          )
        ) jt
      where s.id = sr.stream_id
        and s.id = p_stream_id
  ) src
  on (sc.stream_id = src.stream_id and sc.course_id = src.course_id and sc.course_no = src.current_round and sc.player_id = src.player_id)
  when matched then
      update set
          sc.s1 = src.es1,
          sc.s2 = src.es2,
          sc.s3 = src.es3,
          sc.s4 = src.es4,
          sc.s5 = src.es5,
          sc.s6 = src.es6,
          sc.s7 = src.es7,
          sc.s8 = src.es8,
          sc.s9 = src.es9,
          sc.s10 = src.es10,
          sc.s11 = src.es11,
          sc.s12 = src.es12,
          sc.s13 = src.es13,
          sc.s14 = src.es14,
          sc.s15 = src.es15,
          sc.s16 = src.es16,
          sc.s17 = src.es17,
          sc.s18 = src.es18,
          sc.final_score = src.total_easy
  when not matched then
      insert (
          stream_id, course_no, course_id, player_id
        , s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
        , s11, s12, s13, s14, s15, s16, s17, s18
        , final_score
      )
      values (
          src.stream_id, src.current_round, src.course_id, src.player_id
        , src.es1, src.es2, src.es3, src.es4, src.es5, src.es6, src.es7, src.es8, src.es9
        , src.es10, src.es11, src.es12, src.es13, src.es14, src.es15, src.es16, src.es17, src.es18
        , src.total_easy
      );

  logger.log('p1 Rows: ' || SQL%ROWCOUNT, l_scope);
  logger.log('l_stream_round_rec.current_round: ' || l_stream_round_rec.current_round, l_scope);


  -- Update the round score for player 1
  if l_stream_round_rec.current_round = 1 then
  logger.log('l_stream_rec.player1_id:' || l_stream_rec.player1_id);
    update wmg_stream_round sr
       set sr.player1_round1_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player1_id
          )
     where stream_id = p_stream_id;
  else
    update wmg_stream_round sr
       set sr.player1_round2_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player1_id
          )
     where stream_id = p_stream_id;
  end if;

----------------------------------------
  /* Merge scores for player 2 "h" */
  merge into wmg_stream_scores sc
  using (
    select s.id stream_id
         , sr.current_course_id course_id
         , sr.current_round
         , s.player2_id player_id
         , nullif(jt.hs1, 0) hs1
         , nullif(jt.hs2, 0) hs2
         , nullif(jt.hs3, 0) hs3
         , nullif(jt.hs4, 0) hs4
         , nullif(jt.hs5, 0) hs5
         , nullif(jt.hs6, 0) hs6
         , nullif(jt.hs7, 0) hs7
         , nullif(jt.hs8, 0) hs8
         , nullif(jt.hs9, 0) hs9
         , nullif(jt.hs10, 0) hs10
         , nullif(jt.hs11, 0) hs11
         , nullif(jt.hs12, 0) hs12
         , nullif(jt.hs13, 0) hs13
         , nullif(jt.hs14, 0) hs14
         , nullif(jt.hs15, 0) hs15
         , nullif(jt.hs16, 0) hs16
         , nullif(jt.hs17, 0) hs17
         , nullif(jt.hs18, 0) hs18
         , total_hard
    from wmg_streams s
       , wmg_stream_round sr
       , json_table(
          p_scores_json, -- This is the JSON string containing the scores
          '$'
          columns (
            hs1 NUMBER PATH '$.hs1',
            hs2 NUMBER PATH '$.hs2',
            hs3 NUMBER PATH '$.hs3',
            hs4 NUMBER PATH '$.hs4',
            hs5 NUMBER PATH '$.hs5',
            hs6 NUMBER PATH '$.hs6',
            hs7 NUMBER PATH '$.hs7',
            hs8 NUMBER PATH '$.hs8',
            hs9 NUMBER PATH '$.hs9',
            hs10 NUMBER PATH '$.hs10',
            hs11 NUMBER PATH '$.hs11',
            hs12 NUMBER PATH '$.hs12',
            hs13 NUMBER PATH '$.hs13',
            hs14 NUMBER PATH '$.hs14',
            hs15 NUMBER PATH '$.hs15',
            hs16 NUMBER PATH '$.hs16',
            hs17 NUMBER PATH '$.hs17',
            hs18 NUMBER PATH '$.hs18',
            total_hard NUMBER PATH '$.total_hard'
          )
        ) jt
      where s.id = sr.stream_id
        and s.id = p_stream_id
  ) src
  on (sc.stream_id = src.stream_id and sc.course_id = src.course_id and sc.course_no = src.current_round and sc.player_id = src.player_id)
  when matched then
      update set
          sc.s1 = src.hs1,
          sc.s2 = src.hs2,
          sc.s3 = src.hs3,
          sc.s4 = src.hs4,
          sc.s5 = src.hs5,
          sc.s6 = src.hs6,
          sc.s7 = src.hs7,
          sc.s8 = src.hs8,
          sc.s9 = src.hs9,
          sc.s10 = src.hs10,
          sc.s11 = src.hs11,
          sc.s12 = src.hs12,
          sc.s13 = src.hs13,
          sc.s14 = src.hs14,
          sc.s15 = src.hs15,
          sc.s16 = src.hs16,
          sc.s17 = src.hs17,
          sc.s18 = src.hs18,
          sc.final_score = src.total_hard
  when not matched then
      insert (
          stream_id, course_no, course_id, player_id
        , s1, s2, s3, s4, s5, s6, s7, s8, s9
        , s10, s11, s12, s13, s14, s15, s16, s17, s18
        , final_score
      )
      values (
          src.stream_id, src.current_round, src.course_id, src.player_id
        , src.hs1, src.hs2, src.hs3, src.hs4, src.hs5, src.hs6, src.hs7, src.hs8, src.hs9
        , src.hs10, src.hs11, src.hs12, src.hs13, src.hs14, src.hs15, src.hs16, src.hs17, src.hs18
        , src.total_hard
      );

  logger.log('p2 Rows: ' || SQL%ROWCOUNT, l_scope);

  -- Update the round score for player 2
  if l_stream_round_rec.current_round = 1 then
    update wmg_stream_round sr
       set sr.player2_round1_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player2_id
          )
     where stream_id = p_stream_id;
  else
    update wmg_stream_round sr
       set sr.player2_round2_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player2_id
          )
     where stream_id = p_stream_id;
  end if;

  update wmg_stream_round sr
     set player1_score = sr.player1_round1_score + nvl(sr.player1_round2_score, 0)
       , player2_score = sr.player2_round1_score + nvl(sr.player2_round2_score, 0)
   where stream_id = p_stream_id;

  -- x_result_status := mm_api.g_ret_sts_success;
  logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      -- x_result_status := mm_api.g_ret_sts_unexp_error;
      raise;
end save_stream_scores;


end wmg_util;
/

Package Body WMG_UTIL compiled


--------------------------------------------------------
--  Constraints for Table LOGGER_LOGS_APEX_ITEMS
--------------------------------------------------------

  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("LOG_ID" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("APP_SESSION" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("ITEM_NAME" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" ADD CONSTRAINT "LOGGER_LOGS_APX_ITMS_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;











--------------------------------------------------------
--  Constraints for Table WMG_CONSTRAINT_LOOKUP
--------------------------------------------------------

  ALTER TABLE "WMG_CONSTRAINT_LOOKUP" MODIFY ("MESSAGE" NOT NULL ENABLE);
  ALTER TABLE "WMG_CONSTRAINT_LOOKUP" ADD PRIMARY KEY ("CONSTRAINT_NAME") USING INDEX  ENABLE;





--------------------------------------------------------
--  Constraints for Table WMG_PARAMETERS
--------------------------------------------------------

  ALTER TABLE "WMG_PARAMETERS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_PARAMETERS" MODIFY ("CATEGORY" NOT NULL ENABLE);
  ALTER TABLE "WMG_PARAMETERS" MODIFY ("NAME_KEY" NOT NULL ENABLE);
  ALTER TABLE "WMG_PARAMETERS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_PARAMETERS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_PARAMETERS" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_PARAMETERS" ADD CONSTRAINT "WMG_PARAMETERS_U" UNIQUE ("NAME_KEY") USING INDEX  ENABLE;















--------------------------------------------------------
--  Constraints for Table WMG_BADGE_TYPES
--------------------------------------------------------

  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("CODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("DISPLAY_SEQ" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("SYSTEM_CALCULATED_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("SELECTABLE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_BADGE_TYPES" ADD CONSTRAINT "WMG_BADGE_TYPES_SYS_IND_CK" CHECK (system_calculated_ind in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_BADGE_TYPES" ADD CONSTRAINT "WMG_BADGE_TYPES_SELECT_IND_CK" CHECK (selectable_ind        in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_BADGE_TYPES" ADD CONSTRAINT "WMG_BADGE_TYPES_ACTIVE_IND_CK" CHECK (active_ind in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_BADGE_TYPES" ADD CONSTRAINT "WMG_BADGE_TYPES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_BADGE_TYPES" ADD CONSTRAINT "WMG_BADGE_TYPES_CODE_UNQ" UNIQUE ("CODE") USING INDEX  ENABLE;
  ALTER TABLE "WMG_BADGE_TYPES" ADD CONSTRAINT "WMG_BADGE_TYPES_NAME_UNQ" UNIQUE ("NAME") USING INDEX  ENABLE;































--------------------------------------------------------
--  Constraints for Table WMG_COURSE_STROKES
--------------------------------------------------------

  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H2" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H3" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H4" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H5" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H6" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H7" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H8" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H9" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H10" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H11" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H12" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H13" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H14" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H15" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H16" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H17" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H18" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" ADD CONSTRAINT "WMG_COURSE_STROKES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_STROKES" MODIFY ("H1" NOT NULL ENABLE);









































--------------------------------------------------------
--  Constraints for Table WMG_ISSUES
--------------------------------------------------------

  ALTER TABLE "WMG_ISSUES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_ISSUES" MODIFY ("DISPLAY_SEQ" NOT NULL ENABLE);
  ALTER TABLE "WMG_ISSUES" MODIFY ("CODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_ISSUES" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "WMG_ISSUES" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_ISSUES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_ISSUES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_ISSUES" ADD CONSTRAINT "WMG_ISSUES_CK_ACTIVE" CHECK (active_ind in ('Y', 'N')) ENABLE;
  ALTER TABLE "WMG_ISSUES" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_ISSUES" ADD UNIQUE ("CODE") USING INDEX  ENABLE;





















--------------------------------------------------------
--  Constraints for Table WMG_MESSAGES
--------------------------------------------------------

  ALTER TABLE "WMG_MESSAGES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("TO_PLAYER_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("MESSAGE_FROM" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("MESSAGE" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("DISPLAY_COUNT" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("NEW_MESSAGE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("DISPLAY_MODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("MESSAGE_DATE" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_MESSAGES" ADD CONSTRAINT "WMG_MESSAGES_CK_DISPLAY_MODE" CHECK (display_mode in ('POPUP', 'BANNER')) ENABLE;
  ALTER TABLE "WMG_MESSAGES" ADD CONSTRAINT "WMG_MESSAGES_CK_NEW" CHECK (new_message_ind in ('Y', 'N')) ENABLE;
  ALTER TABLE "WMG_MESSAGES" ADD CONSTRAINT "MESSAGES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;



























--------------------------------------------------------
--  Constraints for Table WMG_PLAYER_BADGES
--------------------------------------------------------

  ALTER TABLE "WMG_PLAYER_BADGES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_BADGES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_BADGES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_BADGES" ADD CONSTRAINT "WMG_PLAYER_BADGES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;









--------------------------------------------------------
--  Constraints for Table WMG_STREAM_ROUND
--------------------------------------------------------

  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("STREAM_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("CURRENT_ROUND" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("CURRENT_HOLE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("CURRENT_HOLE_PAR" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("PLAYER1_ROUND1_SCORE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("PLAYER2_ROUND1_SCORE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("PLAYER1_ROUND2_SCORE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("PLAYER2_ROUND2_SCORE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("PLAYER1_SCORE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" MODIFY ("PLAYER2_SCORE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_ROUND" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;

























--------------------------------------------------------
--  Constraints for Table WMG_STREAM_SCORES
--------------------------------------------------------

  ALTER TABLE "WMG_STREAM_SCORES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_SCORES" MODIFY ("STREAM_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_SCORES" MODIFY ("COURSE_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_SCORES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_SCORES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAM_SCORES" ADD CONSTRAINT "WMG_STREAM_SCORES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_STREAM_SCORES" ADD CONSTRAINT "WMG_STREAM_SCORES_ONE_UK" UNIQUE ("STREAM_ID", "PLAYER_ID", "COURSE_ID") USING INDEX  ENABLE;















--------------------------------------------------------
--  Constraints for Table WMG_TOURNAMENT_ROOMS
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_ROOMS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_ROOMS" MODIFY ("TOURNAMENT_SESSION_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_ROOMS" MODIFY ("TIME_SLOT" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_ROOMS" MODIFY ("ROOM_NO" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_ROOMS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_ROOMS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_ROOMS" ADD CONSTRAINT "WMG_TOURNAMENT_ROOM_TIME_SLO_CK" CHECK (time_slot in ('00:00','02:00','04:00','06:00','08:00','12:00','14:00','16:00','18:00','20:00')) ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_ROOMS" ADD CONSTRAINT "WMG_TOURNAMENT_ROOM_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;

















--------------------------------------------------------
--  Constraints for Table WMG_TOURNAMENT_SESSIONS
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" MODIFY ("ROUND_NUM" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" MODIFY ("COMPLETED_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" ADD CONSTRAINT "WMG_TOURNAMENT_COMPLETED_I_CK" CHECK (completed_ind in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" ADD CONSTRAINT "WMG_TOURNAMENT_SES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" MODIFY ("WEEK" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" ADD CONSTRAINT "WMG_TOURNAMENT_SESSIONS_UK1" UNIQUE ("WEEK") USING INDEX  ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" MODIFY ("TOURNAMENT_ID" NOT NULL ENABLE);





















--------------------------------------------------------
--  Constraints for Table OG_WEEKS_TMP
--------------------------------------------------------

  ALTER TABLE "OG_WEEKS_TMP" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "OG_WEEKS_TMP" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;






--------------------------------------------------------
--  Constraints for Table COUNTRY
--------------------------------------------------------

  ALTER TABLE "COUNTRY" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "COUNTRY" MODIFY ("ISO" NOT NULL ENABLE);
  ALTER TABLE "COUNTRY" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "COUNTRY" MODIFY ("FORMATTED_NAME" NOT NULL ENABLE);
  ALTER TABLE "COUNTRY" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;











--------------------------------------------------------
--  Constraints for Table WMG_NOTES
--------------------------------------------------------

  ALTER TABLE "WMG_NOTES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTES" MODIFY ("NOTE_TYPE" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTES" MODIFY ("DISPLAY_SEQ" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTES" ADD CONSTRAINT "WMG_NOTES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;













--------------------------------------------------------
--  Constraints for Table WMG_PLAYERS
--------------------------------------------------------

  ALTER TABLE "WMG_PLAYERS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYERS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYERS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYERS" ADD CONSTRAINT "PLAYERS_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_PLAYERS" MODIFY ("RANK_CODE" NOT NULL ENABLE);











--------------------------------------------------------
--  Constraints for Table WMG_COURSES
--------------------------------------------------------

  ALTER TABLE "WMG_COURSES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSES" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSES" ADD CONSTRAINT "COURSES_COURSE_MODE_CK" CHECK (course_mode in ('E','H')) ENABLE;
  ALTER TABLE "WMG_COURSES" ADD CONSTRAINT "COURSES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_COURSES" ADD CONSTRAINT "COURSES_CODE_UNQ" UNIQUE ("CODE") USING INDEX  ENABLE;
  ALTER TABLE "WMG_COURSES" MODIFY ("RELEASE_DATE" NOT NULL ENABLE);

















--------------------------------------------------------
--  Constraints for Table WMG_NOTIFICATION_TYPES
--------------------------------------------------------

  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("CODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("DISPLAY_SEQ" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("PLAYER_SELECTABLE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("TD_SELECTABLE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_NOTIFICATION_TYPES" ADD CONSTRAINT "WMG_NOTIFICATION_TYPES_P_SELECT_IND_CK" CHECK (player_selectable_ind        in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_NOTIFICATION_TYPES" ADD CONSTRAINT "WMG_NOTIFICATION_TYPES_TD_SELECT_IND_CK" CHECK (td_selectable_ind        in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_NOTIFICATION_TYPES" ADD CONSTRAINT "WMG_NOTIFICATION_TYPES_ACTIVE_IND_CK" CHECK (active_ind in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_NOTIFICATION_TYPES" ADD CONSTRAINT "WMG_NOTIFICATION_TYPES_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_NOTIFICATION_TYPES" ADD CONSTRAINT "WMG_NOTIFICATION_TYPES_CODE_UNQ" UNIQUE ("CODE") USING INDEX  ENABLE;
  ALTER TABLE "WMG_NOTIFICATION_TYPES" ADD CONSTRAINT "WMG_NOTIFICATION_TYPES_NAME_UNQ" UNIQUE ("NAME") USING INDEX  ENABLE;































--------------------------------------------------------
--  Constraints for Table WMG_ROUNDS
--------------------------------------------------------

  ALTER TABLE "WMG_ROUNDS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_ROUNDS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_ROUNDS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_ROUNDS" ADD CONSTRAINT "ROUNDS_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_ROUNDS" ADD CONSTRAINT "WMG_ROUNDS_ONE_UK" UNIQUE ("PLAYERS_ID", "WEEK", "COURSE_ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_ROUNDS" MODIFY ("TOURNAMENT_SESSION_ID" NOT NULL ENABLE);













--------------------------------------------------------
--  Constraints for Table WMG_TOURNAMENT_PLAYERS
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" MODIFY ("TOURNAMENT_SESSION_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" MODIFY ("PLAYER_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" MODIFY ("TIME_SLOT" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" ADD CONSTRAINT "WMG_TOURNAMENT_PLA_TIME_SLO_CK" CHECK (time_slot in ('00:00','02:00','04:00','06:00','08:00','12:00','14:00','16:00','18:00','20:00')) ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" ADD CONSTRAINT "WMG_TOURNAMENT_PLAYERS_CK_ACTIVE" CHECK (active_ind in ('Y', 'N')) ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" ADD CONSTRAINT "WMG_TOURNAMENT_PLA_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;





















--------------------------------------------------------
--  Constraints for Table LOGGER_PREFS_BY_CLIENT_ID
--------------------------------------------------------

  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" MODIFY ("CLIENT_ID" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" MODIFY ("LOGGER_LEVEL" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" MODIFY ("INCLUDE_CALL_STACK" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" MODIFY ("CREATED_DATE" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" MODIFY ("EXPIRY_DATE" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" ADD CONSTRAINT "LOGGER_PREFS_BY_CLIENT_ID_CK1" CHECK (logger_level in ('OFF','PERMANENT','ERROR','WARNING','INFORMATION','DEBUG','TIMING', 'APEX', 'SYS_CONTEXT')) ENABLE;
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" ADD CONSTRAINT "LOGGER_PREFS_BY_CLIENT_ID_CK2" CHECK (expiry_date >= created_date) ENABLE;
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" ADD CONSTRAINT "LOGGER_PREFS_BY_CLIENT_ID_CK3" CHECK (include_call_stack in ('TRUE', 'FALSE')) ENABLE;
  ALTER TABLE "LOGGER_PREFS_BY_CLIENT_ID" ADD CONSTRAINT "LOGGER_PREFS_BY_CLIENT_ID_PK" PRIMARY KEY ("CLIENT_ID") USING INDEX  ENABLE;



















--------------------------------------------------------
--  Constraints for Table WMG_PLAYER_UNICORNS
--------------------------------------------------------

  ALTER TABLE "WMG_PLAYER_UNICORNS" MODIFY ("AWARD_TOURNAMENT_SESSION_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_UNICORNS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_UNICORNS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_UNICORNS" ADD CONSTRAINT "WMG_PLAYER_UNICORNS_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_PLAYER_UNICORNS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_UNICORNS" MODIFY ("COURSE_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_PLAYER_UNICORNS" MODIFY ("SCORE_TOURNAMENT_SESSION_ID" NOT NULL ENABLE);















--------------------------------------------------------
--  Constraints for Table WMG_TOURNAMENTS
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENTS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENTS" MODIFY ("CODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENTS" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENTS" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENTS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENTS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENTS" ADD CONSTRAINT "WMG_TOURNAMENTS_ACTIVE_IND_CK" CHECK (active_ind in ('Y','N')) ENABLE;
  ALTER TABLE "WMG_TOURNAMENTS" ADD CONSTRAINT "WMG_TOURNAMENTS_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_TOURNAMENTS" ADD CONSTRAINT "WMG_TOURNAMENTS_CODE_UNQ" UNIQUE ("CODE") USING INDEX  ENABLE;
  ALTER TABLE "WMG_TOURNAMENTS" ADD CONSTRAINT "WMG_TOURNAMENTS_NAME_UNQ" UNIQUE ("NAME") USING INDEX  ENABLE;





















--------------------------------------------------------
--  Constraints for Table WMG_TOURNAMENT_COURSES
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_COURSES" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_COURSES" MODIFY ("COURSE_NO" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_COURSES" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_COURSES" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_TOURNAMENT_COURSES" ADD CONSTRAINT "WMG_TOURNAMENT_COU_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;











--------------------------------------------------------
--  Constraints for Table WMG_VERIFICATION_QUEUE
--------------------------------------------------------

  ALTER TABLE "WMG_VERIFICATION_QUEUE" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_VERIFICATION_QUEUE" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_VERIFICATION_QUEUE" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_VERIFICATION_QUEUE" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;









--------------------------------------------------------
--  Constraints for Table LOGGER_PREFS
--------------------------------------------------------

  ALTER TABLE "LOGGER_PREFS" MODIFY ("PREF_VALUE" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS" ADD CONSTRAINT "LOGGER_PREFS_PK" PRIMARY KEY ("PREF_TYPE", "PREF_NAME") USING INDEX  ENABLE;
  ALTER TABLE "LOGGER_PREFS" MODIFY ("PREF_TYPE" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS" ADD CONSTRAINT "LOGGER_PREFS_CK1" CHECK (pref_name = upper(pref_name)) ENABLE;
  ALTER TABLE "LOGGER_PREFS" ADD CONSTRAINT "LOGGER_PREFS_CK2" CHECK (pref_type = upper(pref_type)) ENABLE;











--------------------------------------------------------
--  Constraints for Table WMG_COURSE_PREVIEWS
--------------------------------------------------------

  ALTER TABLE "WMG_COURSE_PREVIEWS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_PREVIEWS" MODIFY ("HOLE" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_PREVIEWS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_PREVIEWS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_COURSE_PREVIEWS" ADD CONSTRAINT "WMG_COURSE_PREVIEWS_ID_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;











--------------------------------------------------------
--  Constraints for Table WMG_RANKS
--------------------------------------------------------

  ALTER TABLE "WMG_RANKS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_RANKS" MODIFY ("DISPLAY_SEQ" NOT NULL ENABLE);
  ALTER TABLE "WMG_RANKS" MODIFY ("CODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_RANKS" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "WMG_RANKS" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_RANKS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_RANKS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_RANKS" ADD CONSTRAINT "WMG_RANKS_CK_ACTIVE" CHECK (active_ind in ('Y', 'N')) ENABLE;
  ALTER TABLE "WMG_RANKS" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_RANKS" ADD CONSTRAINT "WMG_RANKS_U" UNIQUE ("CODE") USING INDEX  ENABLE;





















--------------------------------------------------------
--  Constraints for Table COURSE_STROKES
--------------------------------------------------------

  ALTER TABLE "COURSE_STROKES" MODIFY ("H1" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H2" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H3" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H4" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H5" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H6" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H7" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H8" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H9" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H10" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H11" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H12" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H13" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H14" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H15" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H16" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H17" NOT NULL ENABLE);
  ALTER TABLE "COURSE_STROKES" MODIFY ("H18" NOT NULL ENABLE);





































--------------------------------------------------------
--  Constraints for Table LOGGER_LOGS
--------------------------------------------------------

  ALTER TABLE "LOGGER_LOGS" ADD CONSTRAINT "LOGGER_LOGS_LVL_CK" CHECK (logger_level in (1,2,4,8,16,32,64,128)) ENABLE;
  ALTER TABLE "LOGGER_LOGS" ADD CONSTRAINT "LOGGER_LOGS_PK" PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "LOGGER_LOGS" MODIFY ("LOGGER_LEVEL" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS" MODIFY ("TIME_STAMP" NOT NULL ENABLE);









--------------------------------------------------------
--  Constraints for Table WMG_STREAMS
--------------------------------------------------------

  ALTER TABLE "WMG_STREAMS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" MODIFY ("PLAYER1_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" MODIFY ("PLAYER2_ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" MODIFY ("ROUNDS_TOTAL" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" MODIFY ("PLAY_MODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_STREAMS" ADD CONSTRAINT "WMG_STREAMS_CK_ACTIVE" CHECK (active_ind in ('Y', 'N')) ENABLE;
  ALTER TABLE "WMG_STREAMS" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;





















--------------------------------------------------------
--  Constraints for Table WMG_WEBHOOKS
--------------------------------------------------------

  ALTER TABLE "WMG_WEBHOOKS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "WMG_WEBHOOKS" MODIFY ("CODE" NOT NULL ENABLE);
  ALTER TABLE "WMG_WEBHOOKS" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "WMG_WEBHOOKS" MODIFY ("WEBHOOK_URL" NOT NULL ENABLE);
  ALTER TABLE "WMG_WEBHOOKS" MODIFY ("ACTIVE_IND" NOT NULL ENABLE);
  ALTER TABLE "WMG_WEBHOOKS" MODIFY ("CREATED_BY" NOT NULL ENABLE);
  ALTER TABLE "WMG_WEBHOOKS" MODIFY ("CREATED_ON" NOT NULL ENABLE);
  ALTER TABLE "WMG_WEBHOOKS" ADD CONSTRAINT "WMG_WEBHOOKS_CK_ACTIVE" CHECK (active_ind in ('Y', 'N')) ENABLE;
  ALTER TABLE "WMG_WEBHOOKS" ADD PRIMARY KEY ("ID") USING INDEX  ENABLE;
  ALTER TABLE "WMG_WEBHOOKS" ADD CONSTRAINT "WMG_WEBHOOKS_U" UNIQUE ("CODE") USING INDEX  ENABLE;




--------------------------------------------------------
--  Ref Constraints for Table WMG_COURSE_PREVIEWS
--------------------------------------------------------

  ALTER TABLE "WMG_COURSE_PREVIEWS" ADD CONSTRAINT "WMG_COURSE_PREVIEWS_COURSE_ID_FK" FOREIGN KEY ("COURSE_ID") REFERENCES "WMG_COURSES" ("ID") ON DELETE CASCADE ENABLE;




--------------------------------------------------------
--  Ref Constraints for Table WMG_COURSE_STROKES
--------------------------------------------------------

  ALTER TABLE "WMG_COURSE_STROKES" ADD CONSTRAINT "WMG_COURSE_STROKES_COURSE_ID_FK" FOREIGN KEY ("COURSE_ID") REFERENCES "WMG_COURSES" ("ID") ON DELETE CASCADE ENABLE;




--------------------------------------------------------
--  Ref Constraints for Table WMG_MESSAGES
--------------------------------------------------------

  -- ALTER TABLE "WMG_MESSAGES" ADD CONSTRAINT "WMG_MESSAGES_TO_PLAYER_I_FK" FOREIGN KEY ("TO_PLAYER_ID") REFERENCES "WMG_PLAYERS" ("ID") ENABLE;






--------------------------------------------------------
--  Ref Constraints for Table WMG_PLAYERS
--------------------------------------------------------

  ALTER TABLE "WMG_PLAYERS" ADD CONSTRAINT "WMG_PLAYERS_RANK_FK" FOREIGN KEY ("RANK_CODE") REFERENCES "WMG_RANKS" ("CODE") ENABLE;



--------------------------------------------------------
--  Ref Constraints for Table WMG_PLAYER_BADGES
--------------------------------------------------------

  ALTER TABLE "WMG_PLAYER_BADGES" ADD CONSTRAINT "WMG_PLAYER_BADGE_TYP_FK" FOREIGN KEY ("BADGE_TYPE_CODE") REFERENCES "WMG_BADGE_TYPES" ("CODE") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_PLAYER_BADGES" ADD CONSTRAINT "WMG_PLAYER_TOURNAMENT_BADGE_FK" FOREIGN KEY ("TOURNAMENT_SESSION_ID") REFERENCES "WMG_TOURNAMENT_SESSIONS" ("ID") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_PLAYER_BADGES" ADD CONSTRAINT "WMG_PLAYER_BADGES_PLAYER_ID_FK" FOREIGN KEY ("PLAYER_ID") REFERENCES "WMG_PLAYERS" ("ID") ON DELETE CASCADE ENABLE;







--------------------------------------------------------
--  Ref Constraints for Table WMG_PLAYER_UNICORNS
--------------------------------------------------------

  ALTER TABLE "WMG_PLAYER_UNICORNS" ADD CONSTRAINT "WMG_PLAYER_UNI_COURSE_FK" FOREIGN KEY ("COURSE_ID") REFERENCES "WMG_COURSES" ("ID") ENABLE;
  ALTER TABLE "WMG_PLAYER_UNICORNS" ADD CONSTRAINT "WMG_PLAYER_UNICORNS_PLAYER_ID_FK" FOREIGN KEY ("PLAYER_ID") REFERENCES "WMG_PLAYERS" ("ID") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_PLAYER_UNICORNS" ADD CONSTRAINT "WMG_PLAYER_TOURNAMENT_SCORE_UNICORN_FK" FOREIGN KEY ("SCORE_TOURNAMENT_SESSION_ID") REFERENCES "WMG_TOURNAMENT_SESSIONS" ("ID") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_PLAYER_UNICORNS" ADD CONSTRAINT "WMG_PLAYER_TOURNAMENT_AWARD_UNICORN_FK" FOREIGN KEY ("AWARD_TOURNAMENT_SESSION_ID") REFERENCES "WMG_TOURNAMENT_SESSIONS" ("ID") ON DELETE CASCADE ENABLE;










--------------------------------------------------------
--  Ref Constraints for Table WMG_ROUNDS
--------------------------------------------------------

  ALTER TABLE "WMG_ROUNDS" ADD CONSTRAINT "WMG_ROUND_TOURNAMENT_SESS_FK" FOREIGN KEY ("TOURNAMENT_SESSION_ID") REFERENCES "WMG_TOURNAMENT_SESSIONS" ("ID") ENABLE;
  ALTER TABLE "WMG_ROUNDS" ADD CONSTRAINT "WMG_ROUNDS_COURSE_ID_FK" FOREIGN KEY ("COURSE_ID") REFERENCES "WMG_COURSES" ("ID") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_ROUNDS" ADD CONSTRAINT "WMG_ROUNDS_PLAYERS_ID_FK" FOREIGN KEY ("PLAYERS_ID") REFERENCES "WMG_PLAYERS" ("ID") ON DELETE CASCADE ENABLE;








--------------------------------------------------------
--  Ref Constraints for Table WMG_STREAM_ROUND
--------------------------------------------------------

  ALTER TABLE "WMG_STREAM_ROUND" ADD CONSTRAINT "WMG_STREAM_FK" FOREIGN KEY ("STREAM_ID") REFERENCES "WMG_STREAMS" ("ID") ON DELETE CASCADE ENABLE;



--------------------------------------------------------
--  Ref Constraints for Table WMG_STREAM_SCORES
--------------------------------------------------------

  ALTER TABLE "WMG_STREAM_SCORES" ADD CONSTRAINT "WMG_STREAM_SCORES_STREAM_FK" FOREIGN KEY ("STREAM_ID") REFERENCES "WMG_STREAMS" ("ID") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_STREAM_SCORES" ADD CONSTRAINT "WMG_STREAM_SCORES_COURSE_ID_FK" FOREIGN KEY ("COURSE_ID") REFERENCES "WMG_COURSES" ("ID") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_STREAM_SCORES" ADD CONSTRAINT "WMG_STREAM_SCORES_PLAYER_ID_FK" FOREIGN KEY ("PLAYER_ID") REFERENCES "WMG_PLAYERS" ("ID") ON DELETE CASCADE ENABLE;








--------------------------------------------------------
--  Ref Constraints for Table WMG_TOURNAMENT_COURSES
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_COURSES" ADD CONSTRAINT "WMG_TOURNAMEN_TOURNAMENT_SE_FK" FOREIGN KEY ("TOURNAMENT_SESSION_ID") REFERENCES "WMG_TOURNAMENT_SESSIONS" ("ID") ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_COURSES" ADD CONSTRAINT "WMG_TOURNAMENT_COU_COURSE_I_FK" FOREIGN KEY ("COURSE_ID") REFERENCES "WMG_COURSES" ("ID") ENABLE;





--------------------------------------------------------
--  Ref Constraints for Table WMG_TOURNAMENT_PLAYERS
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" ADD CONSTRAINT "WMG_TOURNAMENT_PLA_ISSUE_FK" FOREIGN KEY ("ISSUE_CODE") REFERENCES "WMG_ISSUES" ("CODE") ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" ADD CONSTRAINT "WMG_TOURNAMEN_TOURNAMENT_FK15" FOREIGN KEY ("TOURNAMENT_SESSION_ID") REFERENCES "WMG_TOURNAMENT_SESSIONS" ("ID") ENABLE;
  ALTER TABLE "WMG_TOURNAMENT_PLAYERS" ADD CONSTRAINT "WMG_TOURNAMENT_PLA_PLAYER_I_FK" FOREIGN KEY ("PLAYER_ID") REFERENCES "WMG_PLAYERS" ("ID") ENABLE;







--------------------------------------------------------
--  Ref Constraints for Table WMG_TOURNAMENT_ROOMS
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_ROOMS" ADD CONSTRAINT "WMG_TOURNAMEN_TOURNAMENT_FK16" FOREIGN KEY ("TOURNAMENT_SESSION_ID") REFERENCES "WMG_TOURNAMENT_SESSIONS" ("ID") ENABLE;



--------------------------------------------------------
--  Ref Constraints for Table WMG_TOURNAMENT_SESSIONS
--------------------------------------------------------

  ALTER TABLE "WMG_TOURNAMENT_SESSIONS" ADD CONSTRAINT "WMG_TOURNAMENT_TOURNAMENT_FK" FOREIGN KEY ("TOURNAMENT_ID") REFERENCES "WMG_TOURNAMENTS" ("ID") ENABLE;



--------------------------------------------------------
--  Ref Constraints for Table WMG_VERIFICATION_QUEUE
--------------------------------------------------------

  ALTER TABLE "WMG_VERIFICATION_QUEUE" ADD CONSTRAINT "WMG_VERIFICATION_QE_PLAYERS_ID_FK" FOREIGN KEY ("EASY_PLAYER_ID") REFERENCES "WMG_PLAYERS" ("ID") ON DELETE CASCADE ENABLE;
  ALTER TABLE "WMG_VERIFICATION_QUEUE" ADD CONSTRAINT "WMG_VERIFICATION_QH_PLAYERS_ID_FK" FOREIGN KEY ("HARD_PLAYER_ID") REFERENCES "WMG_PLAYERS" ("ID") ON DELETE CASCADE ENABLE;





--- END --------------------------------------------------------------------


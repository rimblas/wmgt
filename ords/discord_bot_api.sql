-- Discord Bot API Endpoints
-- Generated for Discord Tournament Registration Bot

BEGIN
  -- Enable schema if not already enabled
  ORDS.ENABLE_SCHEMA(
      p_enabled             => TRUE,
      p_schema              => 'WMGT',
      p_url_mapping_type    => 'BASE_PATH',
      p_url_mapping_pattern => 'wmgt',
      p_auto_rest_auth      => FALSE);
    
  -- Define Discord Bot API module
  ORDS.DEFINE_MODULE(
      p_module_name    => 'Discord Bot API',
      p_base_path      => '/api/',
      p_items_per_page => 25,
      p_status         => 'PUBLISHED',
      p_comments       => 'API endpoints for Discord bot tournament registration');

  -- Template: /api/tournaments/current
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'Discord Bot API',
      p_pattern        => 'tournaments/current',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'Get current active tournament with sessions and courses');

  -- Handler: GET /api/tournaments/current
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'Discord Bot API',
      p_pattern        => 'tournaments/current',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_items_per_page => 0,
      p_mimes_allowed  => NULL,
      p_comments       => 'Returns current active tournament with available sessions and courses',
      p_source         => 
'declare
  l_clob clob;
  l_scope logger_logs.scope%type := ''REST:current_tournament'';
begin
  logger.log(p_text => ''START'', p_scope => l_scope);

  select json_object(
    ''tournament'' value json_object(
      ''id'' value t.tournament_id,
      ''name'' value t.name,
      ''code'' value t.code
    )
    ,''sessions'' value json_object(
          ''id'' value t.tournament_session_id,
          ''week'' value t.week,
          ''session_date'' value to_char(t.session_date, ''YYYY-MM-DD"T"HH24:MI:SS"Z"''),
          ''open_registration_on'' value to_char(t.open_registration_on, ''YYYY-MM-DD"T"HH24:MI:SS"Z"''),
          ''close_registration_on'' value to_char(t.close_registration_on, ''YYYY-MM-DD"T"HH24:MI:SS"Z"''),
          ''registration_open'' value case 
            when current_timestamp between t.open_registration_on and t.close_registration_on 
            then ''true'' else ''false'' end
            ,''available_time_slots'' value (
            select json_arrayagg(
              j' || 'son_object(
                ''time_slot'' value ts.time_slot,
                ''day_offset'' value ts.day_offset,
                ''display'' value ts.prepared_time_slot
              ) order by ts.seq
            )
            from wmg_time_slots_all_v ts
          )
          ,''courses'' value (
            select json_arrayagg(
              json_object(
                ''course_no'' value case when tc.course_no = 1 then 1 else 2 end,
                ''course_name'' value c.name,
                ''course_code'' value c.code,
                ''difficulty'' value case when tc.course_no = 1 then ''Easy'' else ''Hard'' end
              )
            )
            from wmg_tournament_courses tc
            join wmg_courses c on tc.course_id = c.id
            where tc.tournament_session_id = t.tournament_session_id
          )
        -- returning clob
      )
    )
    -- returning clob
  into l_clob
  from (
    select t.id tournament_id, t.name, t.code
    , s.tournament_ses' || 'sion_id
    , s.week
    , s.session_date
    , s.open_registration_on
    , s.close_registration_on
    from wmg_tournaments t
        , wmg_tournament_sessions_v s
    where s.tournament_id = t.id
      and t.current_flag = ''Y''
      and t.active_ind = ''Y''
        and s.session_date + 1 >= trunc(current_timestamp)
        and s.completed_ind = ''N''
    fetch first 1 rows only
  ) t;

  if l_clob is null then
    l_clob := ''{}'';
    /*
    json_object(
      ''tournament'' value null,
      ''sessions'' value json_array()
    );
    */
  end if;

 sys.owa_util.mime_header(''application/json'', true);
  apex_util.prn(
    p_clob   => l_clob,
    p_escape => false
  );

  logger.log(p_text => ''END'', p_scope => l_scope);
exception
  when others then
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
    raise;
end;');

  -- Template: /api/tournaments/register
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'Discord Bot API',
      p_pattern        => 'tournaments/register',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'Register player for tournament session');

  -- Handler: POST /api/tournaments/register
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'Discord Bot API',
      p_pattern        => 'tournaments/register',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_items_per_page => 0,
      p_mimes_allowed  => 'application/json',
      p_comments       => 'Register a Discord user for a tournament session',
      p_source         => 
'declare
  l_body clob;
  l_json json_object_t;
  l_discord_user t_discord_user;
  l_session_id number;
  l_time_slot varchar2(5);
  l_existing_registration number;
  l_registration_open varchar2(1);
  l_week varchar2(10);
  l_response clob;
  l_scope logger_logs.scope%type := ''REST:api/tournaments/register'';
begin
  logger.log(p_text => ''START'', p_scope => l_scope);
  
  -- Get request body
  l_body := :body_text;
  l_json := json_object_t.parse(l_body);
  
  -- Extract parameters
  l_session_id := l_json.get_number(''session_id'');
  l_time_slot := l_json.get_string(''time_slot'');
  
  logger.log(p_text => ''session_id: '' || l_session_id || '', time_slot: '' || l_time_slot, p_scope => l_scope);
  
  -- Validate session exists and registration is open
  select case 
    when current_timestamp between open_registration_on and close_registration_on 
    then ''Y'' else ''N'' end,
    week
  into l_registration_open, l_week
  from wmg_tournament_sessions
  where id = l_session_id;
  
  if l_registration_open = ''N'' then
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''REGISTRATION_CLOSED'');
    apex_json.write(''message'', ''Registration for this tournament session has closed'');
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    goto output_response;
  end if;
  
  -- Initialize Discord user from JSON
  l_discord_user := t_discord_user();
  l_discord_user.init_from_json(l_json.get_object(''discord_user'').to_clob());
  l_discord_user.sync_player();
  
  logger.log(p_text => ''player_id: '' || l_discord_user.player_id, p_scope => l_scope);
  
  -- Check if already registered for this session
  select count(*)
  into l_existing_registration
  from wmg_tournament_players
  where tournament_session_id = l_session_id
    and player_id = l_discord_user.player_id
    and active_ind = ''Y'';
    
  if l_existing_registration > 0 then
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''ALREADY_REGISTERED'');
    apex_json.write(''message'', ''Player is already registered for this tournament session'');
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    goto output_response;
  end if;
  
  -- Validate time slot
  declare
    l_valid_slot_count number;
  begin
    select count(*)
    into l_valid_slot_count
    from wmg_time_slots_all_v
    where time_slot = l_time_slot;
    
    if l_valid_slot_count = 0 then
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.write(''success'', false);
      apex_json.write(''error_code'', ''INVALID_TIME_SLOT'');
      apex_json.write(''message'', ''Selected time slot is not available'');
      apex_json.close_object;
      l_response := apex_json.get_clob_output;
      apex_json.free_output;
      goto output_response;
    end if;
  end;
  
  -- Register player
  insert into wmg_tournament_players (
    tournament_session_id,
    player_id,
    time_slot,
    active_ind
  ) values (
    l_session_id,
    l_discord_user.player_id,
    l_time_slot,
    ''Y''
  );
  
  commit;
  
  apex_json.initialize_clob_output;
  apex_json.open_object;
  apex_json.write(''success'', true);
  apex_json.write(''message'', ''Successfully registered for '' || l_week || '' at '' || l_time_slot || '' UTC'');
  apex_json.open_object(''registration'');
  apex_json.write(''session_id'', l_session_id);
  apex_json.write(''week'', l_week);
  apex_json.write(''time_slot'', l_time_slot);
  apex_json.write(''room_no'', null);
  apex_json.close_object;
  apex_json.close_object;
  l_response := apex_json.get_clob_output;
  apex_json.free_output;
  
  <<output_response>>
  apex_util.prn(
    p_clob   => l_response,
    p_escape => false
  );
  
  logger.log(p_text => ''END'', p_scope => l_scope);
exception
  when no_data_found then
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''SESSION_NOT_FOUND'');
    apex_json.write(''message'', ''Tournament session does not exist'');
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    apex_util.prn(p_clob => l_response, p_escape => false);
    logger.log_error(p_text => ''Session not found: '' || l_session_id, p_scope => l_scope);
  when others then
    rollback;
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''REGISTRATION_FAILED'');
    apex_json.write(''message'', ''Registration failed: '' || sqlerrm);
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    apex_util.prn(p_clob => l_response, p_escape => false);
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
end;');

  -- Template: /api/tournaments/unregister
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'Discord Bot API',
      p_pattern        => 'tournaments/unregister',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'Unregister player from tournament session');

  -- Handler: POST /api/tournaments/unregister
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'Discord Bot API',
      p_pattern        => 'tournaments/unregister',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_items_per_page => 0,
      p_mimes_allowed  => 'application/json',
      p_comments       => 'Unregister a Discord user from a tournament session',
      p_source         => 
'declare
  l_body clob;
  l_json json_object_t;
  l_discord_user t_discord_user;
  l_session_id number;
  l_existing_registration number;
  l_week varchar2(10);
  l_session_started varchar2(1);
  l_response clob;
  l_scope logger_logs.scope%type := ''REST:api/tournaments/unregister'';
begin
  logger.log(p_text => ''START'', p_scope => l_scope);
  
  -- Get request body
  l_body := :body_text;
  l_json := json_object_t.parse(l_body);
  
  -- Extract parameters
  l_session_id := l_json.get_number(''session_id'');
  
  logger.log(p_text => ''session_id: '' || l_session_id, p_scope => l_scope);
  
  -- Initialize Discord user from JSON
  l_discord_user := t_discord_user();
  l_discord_user.init_from_json(l_json.get_object(''discord_user'').to_clob());
  l_discord_user.sync_player();
  
  logger.log(p_text => ''player_id: '' || l_discord_user.player_id, p_scope => l_scope);
  
  -- Check if session exists and get details
  select week,
         case when session_date <= current_date then ''Y'' else ''N'' end
  into l_week, l_session_started
  from wmg_tournament_sessions
  where id = l_session_id;
  
  -- Check if tournament has started
  if l_session_started = ''Y'' then
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''UNREGISTRATION_FAILED'');
    apex_json.write(''message'', ''Cannot unregister after tournament has started'');
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    goto output_response;
  end if;
  
  -- Check if player is registered
  select count(*)
  into l_existing_registration
  from wmg_tournament_players
  where tournament_session_id = l_session_id
    and player_id = l_discord_user.player_id
    and active_ind = ''Y'';
    
  if l_existing_registration = 0 then
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''NOT_REGISTERED'');
    apex_json.write(''message'', ''Player is not registered for this tournament session'');
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    goto output_response;
  end if;
  
  -- Unregister player (set active_ind to N)
  update wmg_tournament_players
  set active_ind = ''N''
  where tournament_session_id = l_session_id
    and player_id = l_discord_user.player_id
    and active_ind = ''Y'';
  
  commit;
  
  apex_json.initialize_clob_output;
  apex_json.open_object;
  apex_json.write(''success'', true);
  apex_json.write(''message'', ''Successfully unregistered from '' || l_week);
  apex_json.close_object;
  l_response := apex_json.get_clob_output;
  apex_json.free_output;
  
  <<output_response>>
  apex_util.prn(
    p_clob   => l_response,
    p_escape => false
  );
  
  logger.log(p_text => ''END'', p_scope => l_scope);
exception
  when no_data_found then
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''SESSION_NOT_FOUND'');
    apex_json.write(''message'', ''Tournament session does not exist'');
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    apex_util.prn(p_clob => l_response, p_escape => false);
    logger.log_error(p_text => ''Session not found: '' || l_session_id, p_scope => l_scope);
  when others then
    rollback;
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write(''success'', false);
    apex_json.write(''error_code'', ''UNREGISTRATION_FAILED'');
    apex_json.write(''message'', ''Unregistration failed: '' || sqlerrm);
    apex_json.close_object;
    l_response := apex_json.get_clob_output;
    apex_json.free_output;
    apex_util.prn(p_clob => l_response, p_escape => false);
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
end;');

  -- Template: /players/registrations/{discord_id}
 -- Template: /players/registrations/{discord_id}
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'WMGT Tournament',
      p_pattern        => 'players/registrations/:discord_id',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'Get player registrations by Discord ID');

  -- Handler: GET /api/players/registrations/{discord_id}
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'WMGT Tournament',
      p_pattern        => 'players/registrations/:discord_id',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_items_per_page => 0,
      p_mimes_allowed  => NULL,
      p_comments       => 'Returns all active registrations for a player by Discord ID',
      p_source         => 
'declare
  l_clob clob;
  l_discord_id varchar2(50);
  l_player_id number;
  l_player_name varchar2(100);
  l_scope logger_logs.scope%type := ''REST:/players/registrations'';
begin
  logger.log(p_text => ''START'', p_scope => l_scope);
  
  l_discord_id := :discord_id;
  logger.log(p_text => ''discord_id: '' || l_discord_id, p_scope => l_scope);
  
  -- Get player info
  select id, player_name
  into l_player_id, l_player_name
  from wmg_players_v
  where discord_id = to_number(l_discord_id default null on conversion error);
  
  -- Build response
  select json_object(
    ''player'' value json_object(
      ''id'' value l_player_id,
      ''name'' value l_player_name,
      ''discord_id'' value l_discord_id
    ),
    ''registrations'' value (
      select json_arrayagg(
        json_object(
          ''session_id'' value tp.tournament_session_id,
          ''week'' value ts.week,
          ''time_slot'' value tp.time_slot,
          ''session_date'' value to_char(ts.session_date, ''YYYY-MM-DD"T"HH24:MI:SS"Z"''),
          ''room_no'' value tp.room_no
        ) returning clob
      )
      from wmg_tournament_players tp
      join wmg_tournament_sessions ts on tp.tournament_session_id = ts.id
      where tp.player_id = l_player_id
        and tp.active_ind = ''Y''
        and ts.session_date + 1 >= trunc(current_timestamp)
      order by ts.session_date
    ) returning clob
  ) into l_clob;

  if l_clob is null then
    l_clob := json_object(
      ''player'' value json_object(
        ''id'' value l_player_id,
        ''name'' value l_player_name,
        ''discord_id'' value l_discord_id
      ),
      ''registrations'' value json_array()
    );
  end if;

  apex_util.prn(
    p_clob   => l_clob,
    p_escape => false
  );

  logger.log(p_text => ''END'', p_scope => l_scope);
exception
  when no_data_found then
    l_clob := json_object(
      ''success'' value false,
      ''error_code'' value ''PLAYER_NOT_FOUND'',
      ''message'' value ''Discord user not linked to WMGT player account''
    );
    apex_util.prn(p_clob => l_clob, p_escape => false);
    logger.log_error(p_text => ''Player not found: '' || l_discord_id, p_scope => l_scope);
  when others then
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
    raise;
end;');

  -- Define parameter for discord_id
  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'WMGT Tournament',
      p_pattern            => 'players/registrations/:discord_id',
      p_method             => 'GET',
      p_name               => 'discord_id',
      p_bind_variable_name => 'discord_id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => 'Discord user ID');

COMMIT;

END;
/
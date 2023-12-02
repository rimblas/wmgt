create or replace package body wmg_notification
is


--------------------------------------------------------------------------------
-- TYPES
/**
 * @type
 */

-- CONSTANTS
 c_embed_color_green     number := 5832556;
 c_embed_color_lightblue number := 5814783;
 c_crlf varchar2(2) := chr(13)||chr(10);

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
  $IF $$LOGGER $THEN
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $ELSE
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
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
    l_body := '{' ||
        '    "ENV":'                 || apex_json.stringify( wmg_util.get_param('ENV') ) ||
        '   ,"PLAYER_NAME":'         || apex_json.stringify( p.player_name ) ||
        '   ,"DISCORD_AVATAR":'      || apex_json.stringify( p.avatar_image ) ||
        '   ,"TIME_SLOT":'           || apex_json.stringify( l_time_slot ) ||
        '   ,"REGISTRATION_ATTEMPTS":'|| apex_json.stringify( l_registration_attempts ) ||
        '   ,"ACCOUNT":'             || apex_json.stringify( p.account ) ||
        '   ,"NAME":'                || apex_json.stringify( p.name ) ||
        '   ,"DISCORD_ID":'          || apex_json.stringify( p.discord_id ) ||
        '   ,"PREFERED_TZ":'         || apex_json.stringify( p.prefered_tz ) ||
        '   ,"MY_APPLICATION_LINK":' || '"' || apex_mail.get_instance_url || 'r/wmgt/wmgt/home' || '"' ||
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
                 'image' value json_object('url' value p.avatar_image),
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
    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'BEAR313'
       , p_content      => l_content
       , p_embeds       => l_embeds
    );


  end loop;

  apex_mail.push_queue;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end new_player;





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
               , case when s.rooms_open_flag = 'Y' then nvl2(p.room_no, 'WMGT', '') || p.room_no else '' end room_no
               , case when s.rooms_open_flag = 'Y' then '' else row_number() over (order by p.tournament_player_id) || ': ' end
              || apex_escape.html(p.player_name) player
               , to_utc_timestamp_tz(to_char(s.session_date, 'yyyy-mm-dd') || 'T' || p.time_slot) at time zone r.tz local_tz
               , r.tz
          from wmg_tournament_player_v p
             , wmg_tournament_sessions s
             , my_room r
          where s.id =  p.tournament_session_id
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

  c_crlf varchar2(2) := chr(13)||chr(10);
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
         , easy_course_name
         , hard_course_name
         , easy_course_code
         , hard_course_code
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






end wmg_notification;
/

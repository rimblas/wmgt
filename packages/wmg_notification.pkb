-- alter session set PLSQL_CCFLAGS='NO_LOGGER:TRUE';
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
        select '- Leaderboard: ' score_type, min(l.score) under_par
          from wmg_leaderboards l
         where l.course_id = new_session.easy_course_id
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
        select '- Leaderboard: ' score_type, min(l.score) under_par
          from wmg_leaderboards l
         where l.course_id = new_session.hard_course_id
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

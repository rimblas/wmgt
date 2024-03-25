declare
 c_embed_color_green     number := 5832556;
 c_embed_color_lightblue number := 5814783;

  l_time_slot      wmg_tournament_players.time_slot%type;

  l_content varchar2(1000);
  l_embeds  varchar2(1000);
  l_avatar_image  varchar2(1000);

begin
  l_time_slot := '00:00';
  for p in (
    select p.* from wmg_players_v p where id = 62 -- p_player_id
  )
  loop
    -- People with a default discord avatar use an internal image lacking the protocol
    -- if there's not protocol, add it
    l_avatar_image := case 
                      when instr(p.avatar_image, 'http') = 0 then
                         apex_util.host_url('SCRIPT')
                      end || p.avatar_image;

     -- Construct the embeds JSON for the webhook
     l_content := 'New Player: __' || p.player_name || '__ just registered for __' || l_time_slot || '__';
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
end loop;

end;
/
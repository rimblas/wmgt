create or replace type body t_discord_user
as 

constructor function t_discord_user return self as result is
begin
    logger.log(p_text => 'INIT', p_scope => 't_discord_user');
    return;
end;

member procedure init_from_json(p_json in clob)
is
    l_json_obj json_object_t;
begin
    l_json_obj := json_object_t.parse(p_json);
    self.player_id              := null;
    self.discord_id             := l_json_obj.get_string('id');
    self.username               := l_json_obj.get_string('username');
    self.global_name            := l_json_obj.get_string('global_name');
    self.avatar                 := l_json_obj.get_string('avatar');
    self.accent_color           := l_json_obj.get_number('accent_color');
    self.banner_color           := l_json_obj.get_string('banner_color');
    self.discriminator          := l_json_obj.get_string('discriminator');
    self.public_flags           := l_json_obj.get_number('public_flags');
    self.flags                  := l_json_obj.get_number('flags');
    self.banner                 := l_json_obj.get_string('banner');
    self.avatar_decoration_data := l_json_obj.get_string('avatar_decoration_data');
    -- self.clan                   := l_json_obj.get_string('clan');
    -- self.mfa_enabled            := l_json_obj.get_boolean('mfa_enabled');
    self.locale                 := l_json_obj.get_string('locale');
    self.premium_type           := l_json_obj.get_number('premium_type');
    self.player_in_sync_flag    := null;
end init_from_json;


member procedure init_from_player(p_player_id number)
is
begin
    select p.id player_id
         , p.discord_id
         , p.account username
         , p.player_name
         , p.discord_avatar
         , p.accent_color
         , p.discord_discriminator
      into self.player_id
         , self.discord_id
         , self.username
         , self.global_name
         , self.avatar
         , self.accent_color
         , self.discriminator
     from wmg_players_v p
    where p.id = p_player_id;

  self.player_in_sync_flag := 'Y'; -- avoid syncing since we just fetched this player

end init_from_player;




member procedure insert_player
is
begin
    insert into wmg_players (
        account
      , name
      , discord_id
      , discord_avatar
      , accent_color
      , discord_discriminator
      , account_login
    )
    values (
        self.username
      , self.global_name
      , self.discord_id
      , self.avatar
      , self.accent_color
      , self.discriminator
      , self.username || ' (discord)'
    )
    returning id into self.player_id;

end insert_player;




member procedure sync_player
is
  l_player_id number;
begin

  if self.player_in_sync_flag = 'Y' then
    logger.log(p_text => '.. player previously synced. skipping', p_scope => 't_discord_user');
    goto done_with_sync;
  end if;


  -- sync username if it changed
  update wmg_players p
     set p.account        = nvl(self.username, p.account)
       , p.account_login  = nvl(self.username, p.account) || '  (discord)'
       , p.discord_avatar = nvl(self.avatar, p.discord_avatar)
       , p.accent_color   = self.accent_color
       , p.name           = nvl(self.global_name, name)
       , p.discord_discriminator = nvl(self.discriminator, p.discord_discriminator)
    where discord_id = self.discord_id
      and (nvl(account, '~NA~') != nvl(self.username, '~NA~')
        or nvl(name, '~NA~') != nvl(self.global_name, '~NA~')
      )
    returning id into l_player_id;


   -- if we don't have a player_id, is probably because 
   -- the account and username did not change
   -- see if the avatar changes
  if l_player_id is null then
     update wmg_players
       set name = self.global_name
         , discord_avatar = self.avatar
         , accent_color = self.accent_color
     where discord_id = self.discord_id
    returning id into l_player_id;
  end if;

  -- if the player_id is still null then see if we need to 
  -- find the player if not, finally add the player
  if l_player_id is null then

    select max(id)
      into l_player_id
      from wmg_players
     where discord_id = self.discord_id;

    -- finally add the player
    if l_player_id is null then
      logger.log(p_text => '.. inserting player. discord_id ' || self.discord_id, p_scope => 't_discord_user');

      insert into wmg_players (
         discord_id
       , account
       , account_login
       , discord_avatar
       , accent_color
       , name
       , discord_discriminator
      )
      values (
          self.discord_id
        , self.username
        , self.username || '  (discord)'
        , self.avatar
        , self.accent_color
        , nvl(self.global_name, self.username)
        , self.discriminator
      )
      returning id into l_player_id;
    end if; -- player insert

  end if;   -- find existing player

  logger.log('.. player_id:' || l_player_id, p_scope => 't_discord_user.sync_player');
  self.player_id := l_player_id;

  <<done_with_sync>>
  null;

end sync_player;


end;
/

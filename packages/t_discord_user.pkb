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
end init_from_json;


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

  -- sync username if it changed
  update wmg_players
     set account        = self.username
       , account_login  = self.username || '  (discord)'
       , discord_avatar = self.avatar
       , accent_color   = self.accent_color
       , name           = nvl(self.global_name, name)
       , discord_discriminator = self.discriminator
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

end sync_player;


end;
/

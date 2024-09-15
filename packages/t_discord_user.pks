create or replace type t_discord_user as object (
    discord_id             number
  , player_id              number
  , username               varchar2(32)
  , global_name            varchar2(100 char)
  , avatar                 varchar2(64)
  , accent_color           number
  , banner_color           varchar2(10)
  , discriminator          varchar2(4)
  , public_flags           number
  , flags                  number
  , banner                 varchar2(64)
  , avatar_decoration_data varchar2(64)
  -- , clan                   varchar2(64)
  , locale                 varchar2(10)
  , premium_type           number
  , player_in_sync_flag    varchar2(1)
  , constructor function t_discord_user return self as result
  , static function get_player(p_player in varchar2) return number
  , member procedure init_from_json(p_json in clob)
  , member procedure init_from_player(p_player_id in number)
  , member procedure init_from_discord_id(p_discord_id in varchar2)
  , member procedure insert_player
  , member procedure sync_player
)
/

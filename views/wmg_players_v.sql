create or replace force view wmg_players_v
as
select p.id
     , p.account
     , p.name
     , nvl(p.name, p.account) player_name
     , p.discord_id
     , p.discord_avatar
     , p.discord_discriminator
     , p.account_login
     , p.prefered_tz
     , p.country_code
     , c.name country
     , p.rank_code
     , r.name          rank_name
     , r.display_seq   rank_display_seq
     , r.profile_class rank_profile_class
     , r.list_class    rank_list_class
     , wmg_discord.avatar(p.discord_id, p.discord_avatar) avatar_image
     , p.created_on
     , p.created_by
     , p.updated_on
     , p.updated_by
from wmg_players p
   , wmg_ranks r
   , wmg_country_iso_v c
where p.rank_code = r.code
  and p.country_code = c.iso_code (+)
/

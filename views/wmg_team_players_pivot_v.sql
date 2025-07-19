create or replace view wmg_team_players_pivot_v
as
with w_team_list as (
select t.tournament_id
     , t.id        team_id
     , p.id player_id
     , p.discord_id
     , p.player_name
     , p.account
     , row_number() over (partition by t.tournament_id, t.id order by tp.id) player_num
     , count(*) over (partition by t.tournament_id, t.id) player_count
  from wmg_teams t
  join wmg_team_players tp on t.id = tp.team_id
  join wmg_players_v p on tp.player_id = p.id
)
, w_team_pivot as (
select tl.tournament_id
     , tl.team_id
     , any_value(decode(tl.player_num, 1, tl.player_id)) player_id1
     , any_value(decode(tl.player_num, 1, tl.player_name)) player_name1
     , any_value(decode(tl.player_num, 1, tl.account)) player_account1
     , any_value(decode(tl.player_num, 2, tl.player_id)) player_id2
     , any_value(decode(tl.player_num, 2, tl.player_name)) player_name2
     , any_value(decode(tl.player_num, 2, tl.account)) player_account2
from w_team_list tl
group  by tl.tournament_id
     , tl.team_id
)
select tp.tournament_id
     , tp.team_id
     , t.team_complete_ind
     , row_number() over (partition by tp.tournament_id, t.team_complete_ind order by t.team_completed_on, t.id) team_no
     , t.team_name
     , tp.player_id1
     , tp.player_name1
     , tp.player_account1
     , wmg_discord.avatar(p1.discord_id, p1.discord_avatar) avatar1
     , wmg_discord.avatar_link(p1.discord_id, p1.discord_avatar) avatar_link1
     , tp.player_id2
     , tp.player_name2
     , tp.player_account2
     , wmg_discord.avatar(p2.discord_id, p2.discord_avatar) avatar2
     , wmg_discord.avatar_link(p2.discord_id, p2.discord_avatar) avatar_link2
     , t.team_logo
     , t.mimetype
     , t.filename
from w_team_pivot tp
join wmg_teams t on (t.tournament_id = tp.tournament_id and t.id = tp.team_id)
join wmg_players p1 on (tp.player_id1 = p1.id)
left join wmg_players p2 on (tp.player_id2 = p2.id)
/
variable tournament_session_id number
exec :tournament_session_id := 2;

begin
insert into wmg_tournament_players (
    tournament_session_id
  , player_id
  , time_slot     
  , active_ind
)
WITH time_slots AS (
  SELECT '00:00' AS time FROM dual UNION ALL
  SELECT '02:00' AS time FROM dual UNION ALL
  SELECT '04:00' AS time FROM dual UNION ALL
  SELECT '08:00' AS time FROM dual UNION ALL
  SELECT '12:00' AS time FROM dual UNION ALL
  SELECT '16:00' AS time FROM dual UNION ALL
  SELECT '18:00' AS time FROM dual UNION ALL
  SELECT '20:00' AS time FROM dual
),
ranked_time_slots AS (
  SELECT time, ROW_NUMBER() OVER (ORDER BY dbms_random.value) AS slot_rank
  FROM time_slots
),
players AS (
  SELECT p.id, p.player_name, ROW_NUMBER() OVER (ORDER BY dbms_random.value) AS player_rank
  FROM wmg_players_v p, fhit_player_invites i
  WHERE p.id = i.player_id AND i.invite_ind = 'Y'
),
ranked_players AS (
  SELECT p.id, p.player_name, p.player_rank, MOD(p.player_rank, (SELECT COUNT(*) FROM ranked_time_slots)) + 1 AS mod_rank
  FROM players p
  where p.id not in (select player_id from wmg_tournament_players where tournament_session_id = :tournament_session_id)
)
SELECT :tournament_session_id
     , rp.id
     -- , rp.player_name
     , rts.time AS time_slot
     , 'Y'
FROM ranked_players rp
JOIN ranked_time_slots rts ON rp.mod_rank = rts.slot_rank;

end;
/

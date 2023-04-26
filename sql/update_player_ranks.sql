set serveroutput on

var P60_TOURNAMENT_ID varchar2(5);
var P60_WEEK varchar2(6);

begin
 :P60_TOURNAMENT_ID := 41;
 :P60_WEEK := 'S08W12';
end;
/

merge into wmg_players p
 using (
with all_weeks as (
  select ts.id tournament_session_id, ts.round_num, ts.week, ts.session_date
   from wmg_tournament_sessions ts
  where ts.tournament_id = :P60_TOURNAMENT_ID
)
, all_tournament_players as (
  select distinct p.player_id, w.tournament_session_id, w.round_num, w.week, w.session_date
    from wmg_tournament_players p
       , all_weeks w
   where p.tournament_session_id in (
      select aw.tournament_session_id
       from all_weeks aw
    )
)
, sessions_pivot as (
    select player_id
         , max(w1_points)        w1_points
         , max(w1_week)          w1_week
         , max(w1_discarded_points_flag)  w1_discard
         , max(w2_points)        w2_points
         , max(w2_week)          w2_week
         , max(w2_discarded_points_flag)  w2_discard
         , max(w3_points)        w3_points
         , max(w3_week)          w3_week
         , max(w3_discarded_points_flag)  w3_discard
         , max(w4_points)        w4_points
         , max(w4_week)          w4_week
         , max(w4_discarded_points_flag)  w4_discard
         , max(w5_points)        w5_points
         , max(w5_week)          w5_week
         , max(w5_discarded_points_flag)  w5_discard
         , max(w6_points)        w6_points
         , max(w6_week)          w6_week
         , max(w6_discarded_points_flag)  w6_discard
         , max(w7_points)        w7_points
         , max(w7_week)          w7_week
         , max(w7_discarded_points_flag)  w7_discard
         , max(w8_points)        w8_points
         , max(w8_week)          w8_week
         , max(w8_discarded_points_flag)  w8_discard
         , max(w9_points)        w9_points
         , max(w9_week)          w9_week
         , max(w9_discarded_points_flag)  w9_discard
         , max(w10_points)       w10_points
         , max(w10_week)         w10_week
         , max(w10_discarded_points_flag) w10_discard
         , max(w11_points)       w11_points
         , max(w11_week)         w11_week
         , max(w11_discarded_points_flag) w11_discard
         , max(w12_points)       w12_points
         , max(w12_week)         w12_week
         , max(w12_discarded_points_flag) w12_discard
    from (
        select ap.player_id
             , coalesce(sp.points, p.points) points
             , p.discarded_points_flag
             , ap.round_num
             , coalesce(sp.week, ap.week) week
             , ap.session_date
    --         , sum(case when p.discarded_points_flag = 'Y' then 0 else p.points end) season_total
        from wmg_tournament_players p
           , all_tournament_players ap
           , wmg_tournament_session_points_v sp
        where ap.player_id = p.player_id(+)
          and ap.tournament_session_id = p.tournament_session_id (+)
          and ap.week = sp.week (+)
          and ap.player_id = sp.player_id (+)
          and sp.week (+) = :P60_WEEK
        order by ap.session_date
    )
    pivot (
        any_value(round_num)    round_num
      , any_value(week)         week
      , any_value(session_date) session_date
      , any_value(points)       points
      , any_value(discarded_points_flag) discarded_points_flag
      for round_num in (
          1 as W1
        , 2 as W2
        , 3 as W3
        , 4 as W4
        , 5 as W5
        , 6 as W6
        , 7 as W7
        , 8 as W8
        , 9 as W9
        , 10 as W10
        , 11 as W11
        , 12 as W12
      )
    )
    group by player_id
)
, final as (
select r.player_id
     , r.player_name
     , r.season_total
  from (
  select p.id player_id
        , p.player_name
       , p.country_code
       , p.rank_name
       , p.rank_list_class
       , decode(sp.w1_discard, 'Y', 0, nvl(sp.w1_points,0))
       + decode(sp.w2_discard, 'Y', 0, nvl(sp.w2_points,0))
       + decode(sp.w3_discard, 'Y', 0, nvl(sp.w3_points,0))
       + decode(sp.w4_discard, 'Y', 0, nvl(sp.w4_points,0))
       + decode(sp.w5_discard, 'Y', 0, nvl(sp.w5_points,0))
       + decode(sp.w6_discard, 'Y', 0, nvl(sp.w6_points,0))
       + decode(sp.w7_discard, 'Y', 0, nvl(sp.w7_points,0))
       + decode(sp.w8_discard, 'Y', 0, nvl(sp.w8_points,0))
       + decode(sp.w9_discard, 'Y', 0, nvl(sp.w9_points,0))
       + decode(sp.w10_discard, 'Y', 0, nvl(sp.w10_points,0))
       + decode(sp.w11_discard, 'Y', 0, nvl(sp.w11_points,0))
       + decode(sp.w12_discard, 'Y', 0, nvl(sp.w12_points,0)) season_total
--     , sp.*
  from sessions_pivot sp
     , wmg_players_v p
  where p.id = sp.player_id
) r
)
select f.player_id, f.season_total
          , case when f.season_total >= 85 then 'PRO'
             when f.season_total between 70 and 84 then 'SEMI' 
             else 'NEW'
            end rank_code
    from final f
    where f.season_total >= 70
) ranks 
on (p.id = ranks.player_id)
when matched then
update set p.rank_code = ranks.rank_code
/
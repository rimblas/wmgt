insert into wmg_rounds (week, course_id, players_id, s1, s2 , s3 , s4 , s5 , s6 , s7 , s8 , s9 , s10 , s11 , s12 , s13 , s14 , s15 , s16 , s17 , s18 )
select 'S6W10' week, 42 course_id, p.id player_id
, c1
, c2
, c3
, c4
, c5
, c6
, c7
, c8
, c9
, c10
, c11
, c12
, c13
, c14
, c15
, c16
, c17
, c18
from S6W10 s
, wmg_players p
where s.username = p.account
and hd is not null


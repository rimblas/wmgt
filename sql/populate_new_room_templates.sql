select tt.tournament_id, t.name, count(*)
from wmg_tournament_room_template tt
  join wmg_tournaments t on t.id = tt.tournament_id
group by tt.tournament_id, t.name
/


insert into wmg_tournament_room_template (
    tournament_id
  , room_no
  , extra_rooms
  , day_offset
  , time_slot
)
select 243 tournament_id -- new season
  , room_no
  , extra_rooms
  , day_offset
  , time_slot
from wmg_tournament_room_template
where tournament_id = 203  -- prev season
/
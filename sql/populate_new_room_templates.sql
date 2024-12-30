insert into wmg_tournament_room_template (
    tournament_id
  , room_no
  , extra_rooms
  , day_offset
  , time_slot
)
select 243 tournament_id
  , room_no
  , extra_rooms
  , day_offset
  , time_slot
from wmg_tournament_room_template
where tournament_id = 203

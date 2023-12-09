
set define off;

PROMPT wmg_notification_types data

declare
  l_json clob;
begin

  -- Load data in JSON object
  l_json := q'!
[
  {
    "code": "NEW_TOURNAMENT",
    "name": "New tournament",
    "description": "Get notified when a new tournament is open for registration",
    "icon_class": "em em-golf",
    "player_selectable": "Y",
    "td_selectable": "Y",
    "seq": 10
  },
  {
    "code": "TOURNAMENT_CLOSE",
    "name": "Tournament Close",
    "description": "Get notified when the tournament is officially closed",
    "icon_class": "em em-thropy",
    "player_selectable": "Y",
    "td_selectable": "Y",
    "seq": 20
  },
  {
    "code": "ROOM_DEFINED",
    "name": "Tournament Room Defined",
    "description": "Get notified when your tournament room has been defined",
    "icon_class": "em em-golfer",
    "player_selectable": "Y",
    "td_selectable": "N",
    "seq": 30
  },
  {
    "code": "SCORING_CLOSING",
    "name": "Score Entry Window Closing",
    "description": "Get notified 15 min before the score entry window closes and you have not entered your scores yet.",
    "icon_class": "em em-alarm_clock",
    "player_selectable": "Y",
    "td_selectable": "N",
    "seq": 40
  },
  {
    "code": "NEW_PLAYER",
    "name": "New Player Signup",
    "description": "Get notified a brand new player registers for the tournament",
    "icon_class": "em em-sunny",
    "player_selectable": "N",
    "td_selectable": "Y",
    "seq": 30
  },
]
!';


  for data in (
    select *
    from json_table(l_json, '$[*]' columns
      code varchar2(4000) path '$.code',
      name varchar2(4000) path '$.name',
      description varchar2(4000) path '$.description',
      icon_class varchar2(4000) path '$.icon_class',
      player_selectable varchar2(4000) path '$.player_selectable',
      td_selectable varchar2(4000) path '$.td_selectable',
      seq number path '$.seq'
    )
  ) loop
    
    -- Note: looping over each entry to make it easier to debug in case one entry is invalid
    -- If performance is an issue can move the loop's select statement into the merge statement
    merge into wmg_notification_types dest
      using (
        select
          data.code code
        from dual
      ) src
      on (1=1
        and dest.code = src.code
      )
    when matched then
      update
        set
          -- Don't update the value as it's probably a key/secure value
          -- Deletions are handled above
          dest.name = data.name,
          dest.description = data.description,
          dest.icon_class = data.icon_class,
          dest.player_selectable_ind = data.player_selectable,
          dest.td_selectable_ind = data.td_selectable,
          dest.display_seq = data.seq
    when not matched then
      insert (
        code,
        name,
        description,
        icon_class,
        display_seq,
        player_selectable_ind,
        td_selectable_ind,
        active_ind,
        created_on,
        created_by)
      values(
        data.code,
        data.name,
        data.description,
        data.icon_class,
        data.seq,
        data.player_selectable,
        data.td_selectable,
        'Y',
        sysdate,
        'SYSTEM')
    ;
  end loop;

end;
/
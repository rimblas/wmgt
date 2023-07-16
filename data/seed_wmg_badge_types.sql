
set define off;

PROMPT wmg_badge_types data

declare
  l_json clob;
begin

  -- Load data in JSON object
  l_json := q'!
[
  {
    "code": "FIRST",
    "name": "1st Place",
    "description": "1st Place",
    "icon_class": "em em-first_place_medal",
    "system": "Y",
    "selectable": "N",
    "seq": 1
  },
  {
    "code": "SECOND",
    "name": "2nd Place",
    "description": "2nd Place",
    "icon_class": "em em-second_place_medal",
    "system": "Y",
    "selectable": "N",
    "seq": 2
  },
  {
    "code": "THIRD",
    "name": "3rd Place",
    "description": "3rd Place",
    "icon_class": "em em-third_place_medal",
    "system": "Y",
    "selectable": "N",
    "seq": 3
  },
  {
    "code": "TOP10",
    "name": "Top 10 Finish",
    "description": "Top 10 Finish",
    "icon_class": "em em-sports_medal",
    "system": "Y",
    "selectable": "N",
    "seq": 4
  },
  {
    "code": "COCONUT",
    "name": "Coconut",
    "description": "Par or under for all 36 holes",
    "icon_class": "em em-coconut",
    "system": "Y",
    "selectable": "Y",
    "seq": 10
  },
  {
    "code": "DIAMOND",
    "name": "Diamond",
    "description": "Most Aces thru 36 holes",
    "icon_class": "em em-large_blue_diamond",
    "system": "N",
    "selectable": "Y",
    "seq": 20
  },
  {
    "code": "CACTUS",
    "name": "Cactus",
    "description": "Solo Ace (Only player to ace a hole)",
    "icon_class": "em em-cactus",
    "system": "Y",
    "selectable": "Y",
    "seq": 30
  },
  {
    "code": "DUCK",
    "name": "Duck",
    "description": "Rare Ace (Small number of players to ace a hole)",
    "icon_class": "em em-duck",
    "system": "N",
    "selectable": "Y",
    "seq": 40
  },
  {
    "code": "BEETLE",
    "name": "Beetle",
    "description": "Rare non-ace best score (Small number of players)",
    "icon_class": "em em-beetle",
    "system": "N",
    "selectable": "Y",
    "seq": 50
  }
]
!';


  for data in (
    select *
    from json_table(l_json, '$[*]' columns
      code varchar2(4000) path '$.code',
      name varchar2(4000) path '$.name',
      description varchar2(4000) path '$.description',
      icon_class varchar2(4000) path '$.icon_class',
      selectable varchar2(4000) path '$.selectable',
      system varchar2(4000) path '$.system',
      seq number path '$.seq'
    )
  ) loop
    
    -- Note: looping over each entry to make it easier to debug in case one entry is invalid
    -- If performance is an issue can move the loop's select statement into the merge statement
    merge into wmg_badge_types dest
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
          dest.selectable_ind = data.selectable,
          dest.system_calculated_ind = data.system,
          dest.display_seq = data.seq
    when not matched then
      insert (
        code,
        name,
        description,
        icon_class,
        display_seq,
        selectable_ind,
        system_calculated_ind,
        active_ind,
        created_on,
        created_by)
      values(
        data.code,
        data.name,
        data.description,
        data.icon_class,
        data.seq,
        data.selectable,
        data.system,
        'Y',
        sysdate,
        'SYSTEM')
    ;
  end loop;

end;
/
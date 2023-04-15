
set define off;

PROMPT wmg_badge_types data

declare
  l_json clob;
begin

  -- Load data in JSON object
  l_json := q'!
[
  {
    "code": "COCONUT",
    "name": "Coconut",
    "description": "Par or under for all 36 holes",
    "icon_class": "em em-coconut",
    "system": "Y",
    "seq": 10
  },
  {
    "code": "DIAMOND",
    "name": "Diamond",
    "description": "Most Aces thru 36 holes",
    "icon_class": "em em-large_blue_diamond",
    "system": "N",
    "seq": 20
  },
  {
    "code": "CACTUS",
    "name": "Cactus",
    "description": "Solo Ace (Only player to ace a hole)",
    "icon_class": "em em-cactus",
    "system": "Y",
    "seq": 30
  },
  {
    "code": "DUCK",
    "name": "Duck",
    "description": "Dual Ace (One of only 2 players to ace a hole)",
    "icon_class": "em em-duck",
    "system": "N",
    "seq": 40
  },
  {
    "code": "BEETLE",
    "name": "Beetle",
    "description": "Rare (1-3 players) non-ace best scores",
    "icon_class": "em em-beetle",
    "system": "N",
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
          dest.system_calculated_ind = data.system,
          dest.display_seq = data.seq
    when not matched then
      insert (
        code,
        name,
        description,
        icon_class,
        display_seq,
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
        data.system,
        'Y',
        sysdate,
        'SYSTEM')
    ;
  end loop;

end;
/
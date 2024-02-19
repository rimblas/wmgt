
set define off;

PROMPT wmg_accolades data

declare
  l_json clob;
begin

  -- Load data in JSON object
  l_json := q'!
[
  {
    "code": "50CLUB",
    "name": "Under 50 Club",
    "description": "Players that have scored -50 or better",
    "icon_class": "em em-first_place_medal",
    "season_flag": ""
    "seq": 1
  },
  {
    "code": "144CLUB",
    "name": "144 Club (8+ podiumns)",
    "description": "The 144 club, or 144 season points, represents the scoring amount of pts in a season equivalent of having 8 podium finishes or better",
    "icon_class": "em em-dart",
    "season_flag": "Y"
    "seq": 2
  },
  {
    "code": "TOPSEASONHN1",
    "name": "Top HN1 for the season",
    "description": "Top holder of hole in one''s for a season",
    "icon_class": "em em-package",
    "season_flag": "Y"
    "seq": 3
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
      season_flag varchar2(4000) path '$.season_flag',
      seq number path '$.seq'
    )
  ) loop
    
    -- Note: looping over each entry to make it easier to debug in case one entry is invalid
    -- If performance is an issue can move the loop's select statement into the merge statement
    merge into wmg_accolades dest
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
          dest.season_specific_flag = data.season_flag
          dest.display_seq = data.seq
    when not matched then
      insert (
        code,
        name,
        description,
        icon_class,
        season_specific_flag,
        display_seq,
        active_ind,
        created_on,
        created_by)
      values(
        data.code,
        data.name,
        data.description,
        data.icon_class,
        data.season_flag,
        data.seq,
        'Y',
        sysdate,
        'SYSTEM')
    ;
  end loop;

end;
/
set define off;

PROMPT wmg_issues data

declare
  l_json clob;
begin

  -- Load data in JSON object
  l_json := q'!
[
  {
    "code": "NOSHOW",
    "name": "No Show",
    "icon": "em em-ghost",
    "description": "No show",
    "active_ind": "Y",
    "points": null,
    "seq": 10
  },
  {
    "code": "NOSCORE",
    "name": "No Scores",
    "icon": "em em-x",
    "description": "Score not entered on time",
    "active_ind": "Y",
    "points": -1,
    "seq": 20
  },
  {
    "code": "INFRACTION",
    "name": "Infraction",
    "icon": "em em-red_circle",
    "description": "Infraction",
    "active_ind": "Y",
    "points": 0,
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
      icon varchar2(4000) path '$.icon',
      points number path '$.points',
      active_ind varchar2(1) path '$.active_ind',
      seq number path '$.seq'
    )
  ) loop
    
    -- Note: looping over each entry to make it easier to debug in case one entry is invalid
    -- If performance is an issue can move the loop's select statement into the merge statement
    merge into wmg_issues dest
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
          dest.icon = data.icon,
          dest.description = data.description,
          dest.tournament_points_override = data.points,
          dest.active_ind = data.active_ind,
          dest.display_seq = data.seq
    when not matched then
      insert (
        code,
        name,
        description,
        icon,
        tournament_points_override,
        display_seq,
        active_ind,
        created_on,
        created_by)
      values(
        data.code,
        data.name,
        data.description,
        data.icon,
        data.points,
        data.seq,
        data.active_ind,
        sysdate,
        'SYSTEM')
    ;
  end loop;

end;
/
set define off;

PROMPT wmg_ranks data

declare
  l_json clob;
begin

  -- Load data in JSON object
  l_json := q'!
[
  {
    "code": "NEW",
    "name": "New Player!",
    "profile_class": "-wm-rank-new-profile rank",
    "list_class": "-wm-rank-new fa",
    "active_ind": "N",
    "seq": 0
  },
  {
    "code": "AMA",
    "name": "Amateur",
    "profile_class": "-wm-rank-ama-profile rank",
    "list_class": "-wm-rank-ama fa",
    "active_ind": "Y",
    "seq": 10
  },
  {
    "code": "RISING",
    "name": "Rising Star",
    "profile_class": "-wm-rank-rise-profile rank",
    "list_class": "-wm-rank-rise fa",
    "active_ind": "N",
    "seq": 50
  },
  {
    "code": "SEMI",
    "name": "Semi-Pro",
    "profile_class": "-wm-rank-semi-profile rank",
    "list_class": "-wm-rank-semi fa",
    "active_ind": "Y",
    "seq": 30
  },
  {
    "code": "PRO",
    "name": "Pro",
    "profile_class": "-wm-rank-pro-profile rank",
    "list_class": "-wm-rank-pro fa",
    "active_ind": "Y",
    "seq": 40
  },
  {
    "code": "ELITE",
    "name": "Elite",
    "profile_class": "-wm-rank-elite-profile rank",
    "list_class": "-wm-rank-elite fa",
    "active_ind": "Y",
    "seq": 50
  }
]
!';


  for data in (
    select *
    from json_table(l_json, '$[*]' columns
      code varchar2(4000) path '$.code',
      name varchar2(4000) path '$.name',
      profile_class varchar2(4000) path '$.profile_class',
      list_class varchar2(4000) path '$.list_class',
      active_ind varchar2(1) path '$.active_ind',
      seq number path '$.seq'
    )
  ) loop
    
    -- Note: looping over each entry to make it easier to debug in case one entry is invalid
    -- If performance is an issue can move the loop's select statement into the merge statement
    merge into wmg_ranks dest
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
          dest.profile_class = data.profile_class,
          dest.list_class = data.list_class,
          dest.active_ind = data.active_ind,
          dest.display_seq = data.seq
    when not matched then
      insert (
        code,
        name,
        profile_class,
        list_class,
        display_seq,
        active_ind,
        created_on,
        created_by)
      values(
        data.code,
        data.name,
        data.profile_class,
        data.list_class,
        data.seq,
        data.active_ind,
        sysdate,
        'SYSTEM')
    ;
  end loop;

end;
/
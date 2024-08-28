set define off
declare


  TYPE color_array_type IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
  colors color_array_type;

  l_content varchar2(1000);
  l_embeds  varchar2(1000);
  l_room    varchar2(1000);

  l_date TIMESTAMP WITH TIME ZONE;
  l_epoch NUMBER;

begin
  -- Populate the colors array
  colors(1) := 1752220;
  colors(2) := 1146986;
  colors(3) := 5763719;
  colors(4) := 2067276;
  colors(5) := 3447003;
  colors(6) := 2123412;
  colors(7) := 10181046;
  colors(8) := 7419530;
  colors(9) := 15277667;
  colors(10) := 11342935;
  colors(11) := 15844367;
  colors(12) := 12745742;
  colors(13) := 15105570;
  colors(14) := 11027200;
  colors(15) := 15548997;
  colors(16) := 10038562;
  colors(17) := 9807270;
  colors(18) := 9936031;
  colors(19) := 8359053;
  colors(20) := 12370112;
  colors(21) := 3426654;
  colors(22) := 2899536;
  colors(23) := 16776960;
  colors(24) := 5832556;
  colors(25) := 5814783;

  l_room := 'KWT';

  -- Convert the string to a timestamp with timezone
  -- v_date := to_timestamp_tz('Friday, August 16, 2024 00:00 UTC', 'Day, Month DD, YYYY HH24:MI TZR');
  


  for p in (
    with slots_n as (
        select level n
         from dual
         connect by level <= 6
        )
    , slots as (
        select seq, day_offset, slot || ':00' d, slot t
        from (
            select n-1 seq, lpad( (n-1)*4,2,0) slot, 0 day_offset
            from slots_n
            -- union all select 7 room, '22' slot, -1 day_offset from dual
            union all
            select 2 seq, '02' slot, 0 day_offset from dual
            union all
            select 18 seq, '18' slot, 0 day_offset from dual
        )
    )
    select rownum room, to_utc_timestamp_tz(to_char(to_date('2024-08-16', 'YYYY-MM-DD'), 'yyyy-mm-dd') || 'T' || t || ':00') utc
      from slots
     order by day_offset, seq
  )
  loop

    -- select (cast(sys_extract_utc(current_timestamp) as date) - TO_DATE('1970-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) * 86400 as gmt_epoch
    -- Convert the timestamp to epoch (UNIX timestamp)
    l_epoch := (cast(p.UTC as date) - TO_DATE('1970-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) * 86400; -- 86400 is the number of seconds in a day

     -- Construct the embeds JSON for the webhook
     l_content := l_room || p.room || ' - <t:' || round(l_epoch) || ':F>';
     l_embeds := json_array (
               json_object(
                 'title' value l_content,
                 'description' value '## Widows Easy & Hard' || chr(13) || '## ROOM ' || l_room || p.room || chr(13),
                 'color' value colors(p.room),
                 'image' value json_object('url' value 'https://apex.skillbuilders.com/ords/wmgt/img/kwt')
             )
           );

    wmg_notification.send_to_discord_webhook(
         p_webhook_code => 'EL_JORGE'
       , p_content      => chr(13) || '-# ' || 'React :thumbsup: below to sign-up' -- l_content
       , p_embeds       => l_embeds
    );
end loop;

end;
/
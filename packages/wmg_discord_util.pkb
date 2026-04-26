create or replace package body wmg_discord_util
is

--------------------------------------------------------------------------------
/**
 * Given a date mask return a Discord Markdown Timestamp
 *
 * Format options and examples:
 *  <t:1777150800:F>	Saturday, April 25, 2026 at 4:00 PM	
 *  <t:1777150800:f>	April 25, 2026 at 4:00 PM	
 *  <t:1777150800:D>	April 25, 2026	
 *  <t:1777150800:d>	04/25/2026	
 *  <t:1777150800:t>	4:00 PM	
 *  <t:1777150800:T>	4:00:00 PM	
 *  <t:1777150800:R>	in 4 hours	
 *  <t:1777150800:s>	04/25/2026, 4:00 PM	
 *  <t:1777150800:S>	04/25/2026, 4:00:00 PM	
 *
 * @example

select discord_timestamp_markdown(
    p_date_str  => '2026/04/25 16:00'
  , p_timezone  => 'America/Chicago'
  , p_md_format in varchar2 default 't'
)
from dual
----------------------------------------
<t:1777150800:t>

 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 25, 2026
 * @param p_date_str
 * @param p_timezone
 * @param p_md_format
 * @return
 */
 
 function discord_timestamp_markdown(
    p_date_str  in varchar2
  , p_timezone  in varchar2 default null
  , p_md_format in varchar2 default 't'
) return varchar2
is
  l_ts        timestamp;
  l_tstz      timestamp with time zone;
  l_utc_tstz  timestamp with time zone;
  l_epoch     number;
begin
  -- parse the input string into a plain timestamp
  l_ts := to_timestamp(p_date_str, 'YYYY/MM/DD HH24:MI');

  -- apply timezone: treat as local time in the given zone, or UTC when null
  l_tstz := from_tz(l_ts, coalesce(p_timezone, 'UTC'));

  -- normalise to UTC
  l_utc_tstz := l_tstz at time zone 'UTC';

  -- calculate epoch (seconds since 1970-01-01 00:00:00 UTC)
  l_epoch := round(
                 extract(day    from (l_utc_tstz - timestamp '1970-01-01 00:00:00 UTC')) * 86400
               + extract(hour   from (l_utc_tstz - timestamp '1970-01-01 00:00:00 UTC')) * 3600
               + extract(minute from (l_utc_tstz - timestamp '1970-01-01 00:00:00 UTC')) * 60
               + extract(second from (l_utc_tstz - timestamp '1970-01-01 00:00:00 UTC'))
             );

  return '<t:' || l_epoch || ':' || p_md_format || '>';

exception
  when others then
    return null;
end discord_timestamp_markdown;

end wmg_discord_util;
/

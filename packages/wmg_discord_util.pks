create or replace package wmg_discord_util
is

--------------------------------------------------------------------------------
--*
--* Discord Utility Functions
--* Provides helper functions for generating Discord-specific formatting
--*
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Discord Markdown Timestamp
--
-- Converts a date string and optional timezone into a Discord timestamp tag.
-- Discord renders these tags in the viewer's local timezone automatically.
--
-- Parameters:
--   p_date_str   - Date/time string in 'YYYY/MM/DD HH24:MI' format
--   p_timezone   - IANA timezone name (e.g. 'America/Chicago', 'US/Eastern').
--                  When null the date string is treated as UTC.
--   p_md_format  - Discord timestamp style flag:
--                    F  Saturday, April 25, 2026 at 4:00 PM
--                    f  April 25, 2026 at 4:00 PM
--                    D  April 25, 2026
--                    d  04/25/2026
--                    t  4:00 PM              (default)
--                    T  4:00:00 PM
--                    R  in 4 hours  (relative)
--                    s  04/25/2026, 4:00 PM
--                    S  04/25/2026, 4:00:00 PM
--
-- Returns:
--   Discord markdown timestamp, e.g. '<t:1777150800:t>'
--   Returns null on error.
--
-- Example:
--   select wmg_discord_util.discord_timestamp_markdown(
--              p_date_str  => '2026/04/25 16:00',
--              p_timezone  => 'America/Chicago',
--              p_md_format => 't')
--     from dual;
--   -- <t:1777150800:t>
--------------------------------------------------------------------------------
function discord_timestamp_markdown(
    p_date_str  in varchar2
  , p_timezone  in varchar2 default null
  , p_md_format in varchar2 default 't'
) return varchar2;

end wmg_discord_util;
/

create or replace view wmg_bar_chart_colors
as
select '#82a372' selected 
     , '#a890b6' selected_highlight  -- plum
     , '#4c825c' regular             -- green
     , '#846a92' regular_highlight   -- plum
from sys.dual
/

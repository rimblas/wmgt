create or replace view wmg_country_iso_v
as
select d name, r iso_code
from (
select 'England' d, 'england' r from dual union all
select 'Scotland' d, 'scotland' r from dual union all
select 'Wales' d, 'wales' r from dual union all
select formatted_name d, lower(iso) r
from country
)
/

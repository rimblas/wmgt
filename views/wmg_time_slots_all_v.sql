create or replace view wmg_time_slots_all_v
as
with slots_n as (
    select level n
     from dual
     connect by level <= 6
    )
, slots as (
    select day_offset, slot || ':00' time_slot, slot t
    from (
        select lpad( (n-1)*4,2,0) slot, 0 day_offset
        from slots_n
        union all
        select '22' slot, -1 day_offset from dual
        union all
        select '02' slot, 0 day_offset from dual
        union all
        select '18' slot, 0 day_offset from dual
    )
)
select row_number() over (order by day_offset, t) seq
     , day_offset
     , time_slot
     , time_slot || case when day_offset = -1 then ' -1' end prepared_time_slot
     , t
from slots
/


select *
from wmg_time_slots_all_v
order by seq
/
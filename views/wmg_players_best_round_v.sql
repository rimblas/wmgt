create or replace view wmg_players_best_round_v
as
with players_best as (
  select players_id, round_id, course_id, under_par
  from (
    select r.players_id, r.id round_id, r.course_id, coalesce(r.override_score, r.final_score) under_par
         , row_number() over (partition by r.players_id, r.course_id order by coalesce(r.override_score, r.final_score)) rn
     from wmg_rounds r
  )
  where rn = 1
)
select *
from players_best
/

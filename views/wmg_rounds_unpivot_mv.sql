-- drop materialized view wmg_rounds_unpivot_mv;
create materialized view wmg_rounds_unpivot_mv
as
select week, course_id, player_id
     , h, score, par
 from wmg_rounds_v
 unpivot (
   (score, par) for h in (
   (s1, par1) as 1,
   (s2, par2) as 2,
   (s3, par3) as 3,
   (s4, par4) as 4,
   (s5, par5) as 5,
   (s6, par6) as 6,
   (s7, par7) as 7,
   (s8, par8) as 8,
   (s9, par9) as 9,
   (s10, par10) as 10,
   (s11, par11) as 11,
   (s12, par12) as 12,
   (s13, par13) as 13,
   (s14, par14) as 14,
   (s15, par15) as 15,
   (s16, par16) as 16,
   (s17, par17) as 17,
   (s18, par18) as 18
   )
 )
/
create unique index wmg_rounds_unpivot_mv_u on wmg_rounds_unpivot_mv(week, player_id, course_id, h);


comment on materialized view wmg_rounds_unpivot_mv is 'Transforms wmg_rounds where hole 1,2,3,4...18 are columns to each hole being a row.';

comment on column wmg_rounds_unpivot_mv.h is 'Hole being playes 1-18';
comment on column wmg_rounds_unpivot_mv.score is 'Strokes taken by the player';
comment on column wmg_rounds_unpivot_mv.par is 'The under par value for a hole.';

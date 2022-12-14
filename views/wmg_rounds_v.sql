create or replace view wmg_rounds_v
as
select 
    p.id                                         player_id,
    p.account                                    account,
    p.name                                       player_name,
    c.id                                         course_id,
    c.code                                       course_code,
    c.name                                       course_name,
    c.course_mode                                course_mode,
    cs.h1    h1,
    cs.h2    h2,
    cs.h3    h3,
    cs.h4    h4,
    cs.h5    h5,
    cs.h6    h6,
    cs.h7    h7,
    cs.h8    h8,
    cs.h9    h9,
    cs.h10   h10,
    cs.h11   h11,
    cs.h12   h12,
    cs.h13   h13,
    cs.h14   h14,
    cs.h15   h15,
    cs.h16   h16,
    cs.h17   h17,
    cs.h18   h18,
    cs.h1+ cs.h2+ cs.h3+ cs.h4+ cs.h5+ cs.h6+ cs.h7+ cs.h8+ cs.h9+ cs.h10+ cs.h11+ cs.h12+ cs.h13+ cs.h14+ cs.h15+ cs.h16+ cs.h17+ cs.h18 course_par,
    r.id                                          round_id,
    r.round_played_on                             round_played_on,
    r.week,
    r.room_name                                   room_name,
    r.s1,
    r.s2,
    r.s3,
    r.s4,
    r.s5,
    r.s6,
    r.s7,
    r.s8,
    r.s9,
    r.s10,
    r.s11,
    r.s12,
    r.s13,
    r.s14,
    r.s15,
    r.s16,
    r.s17,
    r.s18,
    nvl(r.s1,0)+ nvl(r.s2,0)+ nvl(r.s3,0)+ nvl(r.s4,0)+ nvl(r.s5,0)+ nvl(r.s6,0)+ nvl(r.s7,0)+ nvl(r.s8,0)+ nvl(r.s9,0)+ nvl(r.s10,0)+ nvl(r.s11,0)+ nvl(r.s12,0)+ nvl(r.s13,0)+ nvl(r.s14,0)+ nvl(r.s15,0)+ nvl(r.s16,0)+ nvl(r.s17,0)+ nvl(r.s18,0) round_strokes
    , nvl(r.s1 - cs.h1, 0) par1
    , nvl(r.s2 - cs.h2, 0) par2
    , nvl(r.s3 - cs.h3, 0) par3
    , nvl(r.s4 - cs.h4, 0) par4
    , nvl(r.s5 - cs.h5, 0) par5
    , nvl(r.s6 - cs.h6, 0) par6
    , nvl(r.s7 - cs.h7, 0) par7
    , nvl(r.s8 - cs.h8, 0) par8
    , nvl(r.s9 - cs.h9, 0) par9
    , nvl(r.s10 - cs.h10, 0) par10
    , nvl(r.s11 - cs.h11, 0) par11
    , nvl(r.s12 - cs.h12, 0) par12
    , nvl(r.s13 - cs.h13, 0) par13
    , nvl(r.s14 - cs.h14, 0) par14
    , nvl(r.s15 - cs.h15, 0) par15
    , nvl(r.s16 - cs.h16, 0) par16
    , nvl(r.s17 - cs.h17, 0) par17
    , nvl(r.s18 - cs.h18, 0) par18

   , nvl(r.s1 - cs.h1, 0) +
    nvl(r.s2 - cs.h2, 0) +
    nvl(r.s3 - cs.h3, 0) +
    nvl(r.s4 - cs.h4, 0) +
    nvl(r.s5 - cs.h5, 0) +
    nvl(r.s6 - cs.h6, 0) +
    nvl(r.s7 - cs.h7, 0) +
    nvl(r.s8 - cs.h8, 0) +
    nvl(r.s9 - cs.h9, 0) +
    nvl(r.s10 - cs.h10, 0) +
    nvl(r.s11 - cs.h11, 0) +
    nvl(r.s12 - cs.h12, 0) +
    nvl(r.s13 - cs.h13, 0) +
    nvl(r.s14 - cs.h14, 0) +
    nvl(r.s15 - cs.h15, 0) +
    nvl(r.s16 - cs.h16, 0) +
    nvl(r.s17 - cs.h17, 0) +
    nvl(r.s18 - cs.h18, 0) under_par
  , r.created_on
  , r.created_by
  , r.updated_on
  , r.updated_by
from 
    wmg_rounds r,
    wmg_players p,
    wmg_courses c,
    wmg_course_strokes cs
where r.players_id = p.id
  and r.course_id = c.id
  and cs.course_id(+) = c.id
/


@../install/wmg_badge_types.sql

@../data/seed_wmg_badge_types.sql

@../data/seed_wmg_ranks.sql


update wmg_players
    set rank_code = 'AMA'
  where id < 1505
    and rank_code = 'NEW';
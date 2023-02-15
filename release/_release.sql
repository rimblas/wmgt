

alter table wmg_tournament_players add points number;
comment on column wmg_tournament_players.points is 'Points scored by a player on the session. 1st = 25, 2nd = 21, etc...';

alter table wmg_tournament_players add discarded_points_flag varchar2(1);
comment on column wmg_tournament_players.discarded_points_flag is 'Indicates these points have been discarded as 1 out of every 3 sessions gets points discarded';


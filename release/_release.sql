

PRO TABLES
PRO ----------------------------------------
alter table wmg_tournament_players add (
    verified_score_flag            varchar2(1),
    verified_by                    varchar2(60),
    verified_on                    timestamp with local time zone
);
comment on column wmg_tournament_players.verified_score_flag is 'Indicates these scorecard submission has been verified';

PRO VIEWS
PRO ----------------------------------------
PRO .. wmg_rounds_v
@../views/wmg_rounds_v.sql

PRO .. wmg_tournament_results_v
@../views/wmg_tournament_results_v.sql

PRO .. wmg_tournament_player_v
@../views/wmg_tournament_player_v.sql


PRO PACKAGES
PRO ----------------------------------------

@wmg_util.pkb
@wmg_discord.pkb

PRO DML
PRO ----------------------------------------

drop table wmg_wmgt_scores_tmp;
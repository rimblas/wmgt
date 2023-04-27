
set feedback off
set verify off

@../packages/wmg_util.pks
@../packages/wmg_util.pkb

PRO APEX DISABLE APP
PRO ----------------------------------------

set define &
@../apex/apex_disable 200
set define off

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

@../packages/wmg_util.pks
@../packages/wmg_util.pkb
@../packages/wmg_discord.pkb

PRO DML
PRO ----------------------------------------

insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
      'Players' -- category
    , 'LAST_REGISTERED_ID' -- name_key
    , 1505 -- value
    , 'Last player_id that registered after the last tournament' -- description
);


exec wmg_util.set_param('LAST_PLAYER_ID')

PRO DDL
PRO ----------------------------------------

drop table wmg_wmgt_scores_tmp;

PRO APEX 
PRO ----------------------------------------
@@../apex/_ins.sql

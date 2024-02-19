-- drop table wmg_tournament_hof_accolades cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_tournament_hof_accolades (
    id              number        generated always as identity (start with 1) primary key not null
  , acco_code       varchar2(60) not null
                        constraint wmg_tournament_hof_acco_fk
                        references wmg_accolades (code)
  , player_id       number not null
                        constraint wmg_tournament_hof_pla_player_fk
                        references wmg_players(id)
  , tournament_session_id   number
                        constraint wmg_tournament_hof_tournament_sess_fk
                        references wmg_tournament_sessions(id)
  , created_on      timestamp with local time zone default on null current_timestamp not null
  , created_by      varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null
  , updated_on      timestamp with local time zone
  , updated_by      varchar2(60 char)
  , constraint wmg_tournament_hof_accolades_ck_active
      check (active_ind in ('Y', 'N'))
)
enable primary key using index
/

comment on table wmg_tournament_hof_accolades is 'Hall of Fame Player Accolades';

comment on column wmg_tournament_hof_accolades.id is 'Primary Key ID';
comment on column wmg_tournament_hof_accolades.acco_code is 'Accolade Type';
comment on column wmg_tournament_hof_accolades.player_id is 'Player that obtain the accolate';
comment on column wmg_tournament_hof_accolades.player_id is 'Player that obtain the accolate';
comment on column wmg_tournament_hof_accolades.tournament_id is 'Optional Season for the accolade, if applicable';
comment on column wmg_tournament_hof_accolades.created_by is 'User that created this record';
comment on column wmg_tournament_hof_accolades.created_on is 'Date the record was first created';
comment on column wmg_tournament_hof_accolades.updated_by is 'User that last modified this record';
comment on column wmg_tournament_hof_accolades.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--  DDL for Trigger wmg_tournament_hof_accolades_u
--------------------------------------------------------
create or replace trigger wmg_tournament_hof_accolades_u
before update
on wmg_tournament_hof_accolades
referencing old as old new as new
for each row
begin
  if updating then
    :new.updated_on := sysdate;
    :new.updated_by := coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    );
  end if;
end;
/

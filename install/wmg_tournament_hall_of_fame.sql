create table wmg_tournament_hall_of_fame (
    id                             number generated by default on null as identity 
                                   constraint wmg_tournaments_id_pk primary key
  , tournament_id                  number
                                   constraint wmg_tournament_hof_fk
                                   references wmg_tournaments(id) not null
  , player_id                      number not null
                                   constraint wmg_tournament_hof_pla_player_fk
                                   references wmg_players(id)
  , full_total                     number
  , top3                           number default 0
  , top10                          number default 0
  , top25                          number default 0
  , created_on                     timestamp with local time zone default on null current_timestamp not null,
  , created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null,
  , updated_on                     timestamp with local time zone,
  , updated_by                     varchar2(60 char)
)
;

-- comments
comment on column wmg_tournament_hall_of_fame.player_id is 'Player that obtain Hall of Fame entry';
comment on column wmg_tournament_hall_of_fame.tournament_id is 'Season for the accolade, if applicable';
comment on column wmg_tournament_hall_of_fame.full_total is 'Total Points obtained in the season';
comment on column wmg_tournament_hall_of_fame.top3 is 'Number of Top 3 Finishes in the season';
comment on column wmg_tournament_hall_of_fame.top10 is 'Number of Top 10 Finishes in the season';
comment on column wmg_tournament_hall_of_fame.top25 is 'Number of Top 25 Finishes in the season';

-- triggers
create or replace trigger wmg_tournament_hall_of_fame_bu
    before update 
    on wmg_tournament_hall_of_fame
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_hall_of_fame_bu;
/

-- drop table wmg_tournament_players purge;
create table wmg_tournament_players (
    id                             number generated by default on null as identity 
                                   constraint wmg_tournament_pla_id_pk primary key,
    tournament_session_id          number not null
                                   constraint wmg_tournamen_tournament_fk15
                                   references wmg_tournament_sessions(id),
    player_id                      number not null
                                   constraint wmg_tournament_pla_player_i_fk
                                   references wmg_players(id),
    time_slot                      varchar2(5 char) constraint wmg_tournament_pla_time_slo_ck
                                   check (time_slot in ('00:00','04:00','08:00','12:00','16:00','20:00')) not null,
    room_no                        number,
    points                         number,
    points_override                number,
    discarded_points_flag          varchar2(1),
    verified_score_flag            varchar2(1),
    verified_by                    varchar2(60),
    verified_on                    timestamp with local time zone,
    verified_note                  varchar2(200),
    issue_code                     varchar2(1) constraint wmg_tournament_pla_issue_fk 
references wmg_issues(code)
    active_ind                     varchar2(1) constraint wmg_tournament_players_ck_active check (active_ind in ('Y', 'N')) not null,
    created_on                     timestamp with local time zone default on null current_timestamp not null,
    created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null,
    updated_on                     timestamp with local time zone,
    updated_by                     varchar2(60 char)
)
;

-- table index
create unique index wmg_tournament_pla_u1 on wmg_tournament_players (tournament_session_id,player_id);

-- comments
comment on table wmg_tournament_players is 'Players signed up for a specific session';
comment on column wmg_tournament_players.points is 'Points scored by a player on the session. 1st = 25, 2nd = 21, etc...';
comment on column wmg_tournament_players.points_override is 'Override for regular points. Applied at the time of closing.';
comment on column wmg_tournament_players.discarded_points_flag is 'Indicates these points have been discarded as 1 out of every 3 sessions gets points discarded';
comment on column wmg_tournament_players.verified_score_flag is 'Indicates these scorecard submission has been verified';
comment on column wmg_tournament_players.issue_code is 'Flag players issues: no scores, no show, infraction';
comment on column wmg_tournament_players.no_scores_flag is 'Played played but did not submit scores';
comment on column wmg_tournament_players.violation_flag is 'Played violated the rules';

create or replace trigger wmg_tournament_players_bu
    before update 
    on wmg_tournament_players
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_players_bu;
/

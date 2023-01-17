-- create tables
-- create tables
create table wmg_notes (
    id                             number generated by default on null as identity 
                                   constraint wmg_notes_id_pk primary key,
    note_type                      varchar2(20 char) not null,
    display_seq                    number not null,
    notes                          varchar2(4000 char),
    created_on                     timestamp with local time zone default on null current_timestamp not null,
    created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null,
    updated_on                     timestamp with local time zone,
    updated_by                     varchar2(60 char)
)
;

create or replace trigger wmg_notes_bu
    before update 
    on wmg_notes
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_notes_bu;
/


create table wmg_tournaments (
    id                             number generated by default on null as identity 
                                   constraint wmg_tournaments_id_pk primary key,
    code                           varchar2(20 char)
                                   constraint wmg_tournaments_code_unq unique not null,
    name                           varchar2(60 char)
                                   constraint wmg_tournaments_name_unq unique not null,
    prefix_tournament              varchar2(10 char),
    prefix_session                 varchar2(10 char),
    current_flag                   varchar2(1 char),
    active_ind                     varchar2(1 char) constraint wmg_tournaments_active_ind_ck
                                   check (active_ind in ('Y','N')) not null,
    url                            varchar2(4000 char),
    notes                          varchar2(4000 char),
    created_on                     timestamp with local time zone default on null current_timestamp not null,
    created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null,
    updated_on                     timestamp with local time zone,
    updated_by                     varchar2(60 char)
)
;

-- comments
comment on column wmg_tournaments.prefix_tournament is 'The tournament prefix gets concatenated with the session prefix and round_num to form the "WEEK"';

create table wmg_tournament_sessions (
    id                             number generated by default on null as identity 
                                   constraint wmg_tournament_ses_id_pk primary key,
    tournament_id                  number
                                   constraint wmg_tournament_tournament_fk
                                   references wmg_tournaments,
    round_num                      integer not null,
    session_date                   date,
    week                           varchar2(10 char),
    open_registration_on           timestamp with time zone,
    close_registration_on          timestamp with time zone,
    registration_closed_flag       varchar2(1),
    rooms_defined_flag             varchar2(1),
    rooms_defined_by               varchar2(60 char),
    rooms_defined_on               timestamp with time zone,
    completed_ind                  varchar2(1 char) constraint wmg_tournament_completed_i_ck
                                   check (completed_ind in ('Y','N')) not null,
    completed_on                   timestamp with local time zone,
    created_on                     timestamp with local time zone default on null current_timestamp not null,
    created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null,
    updated_on                     timestamp with local time zone,
    updated_by                     varchar2(60 char)
)
;

-- table index
create index wmg_tournament_ses_i1 on wmg_tournament_sessions (tournament_id);

-- comments
comment on column wmg_tournament_sessions.week is 'If prefixes are specified this value gets derived';

create table wmg_tournament_courses (
    id                             number generated by default on null as identity 
                                   constraint wmg_tournament_cou_id_pk primary key,
    tournament_session_id          number
                                   constraint wmg_tournamen_tournament_se_fk
                                   references wmg_tournament_sessions,
    course_no                      number not null,
    course_id                      number
                                   constraint wmg_tournament_cou_course_i_fk
                                   references wmg_courses(id),
    created_on                     timestamp with local time zone default on null current_timestamp not null,
    created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null,
    updated_on                     timestamp with local time zone,
    updated_by                     varchar2(60 char)
)
;

-- table index
create index wmg_tournament_cou_i1 on wmg_tournament_courses (course_id);
create index wmg_tournament_cou_i2 on wmg_tournament_courses (tournament_session_id);

-- comments
comment on table wmg_tournament_courses is 'Courses to be played on a specific session';

create table wmg_tournament_players (
    id                             number generated by default on null as identity 
                                   constraint wmg_tournament_pla_id_pk primary key,
    tournament_session_id          number
                                   constraint wmg_tournamen_tournament_fk15
                                   references wmg_tournament_sessions,
    player_id                      number
                                   constraint wmg_tournament_pla_player_i_fk
                                   references wmg_players(id),
    time_slot                      varchar2(5 char) constraint wmg_tournament_pla_time_slo_ck
                                   check (time_slot in ('00:00','04:00','08:00','12:00','16:00','20:00')) not null,
    room_no                        number,
    active_ind                     varchar2(1) constraint wmg_tournament_players_ck_active
      check (active_ind in ('Y', 'N')) not null 
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

-- triggers
create or replace trigger wmg_tournaments_bu
    before update 
    on wmg_tournaments
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournaments_bu;
/

create or replace trigger wmg_tournament_sessions_bu
    before update 
    on wmg_tournament_sessions
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_sessions_bu;
/

create or replace trigger wmg_tournament_courses_bu
    before update 
    on wmg_tournament_courses
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_courses_bu;
/

create or replace trigger wmg_tournament_players_bu
    before update 
    on wmg_tournament_players
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_players_bu;
/


create table wmg_course_previews (
    id                             number generated by default on null as identity 
                                   constraint wmg_course_previews_id_pk primary key
  , course_id                      number
                                   constraint wmg_course_previews_course_id_fk
                                   references wmg_courses on delete cascade
  , hole                           integer not null
  , same_as_id         number
  , image_preview      blob
  , mimetype           varchar2(255)
  , filename           varchar2(400)
  , image_last_update  timestamp (6) with local time zone
  , created_on         timestamp with local time zone default on null current_timestamp not null
  , created_by         varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null
  , updated_on         timestamp with local time zone
  , updated_by         varchar2(60 char)
)
;

-- table index
create unique index wmg_course_previews_u01 on wmg_course_previews (course_id, hole);

-- comments
comment on table wmg_course_previews is 'Preview images per hole';
comment on column wmg_course_previews.same_as_id is 'ID of a whole image that looks the same';


-- triggers
create or replace trigger wmg_course_previews_bu
    before update 
    on wmg_course_previews
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_course_previews_bu;
/



-- create views
create or replace view wmg_tournament_sessions as 
select 
    tournaments.id                                     tournament_id,
    tournaments.code                                   code,
    tournaments.name                                   name,
    tournaments.prefix_tournament                      prefix_tournament,
    tournaments.prefix_session                         prefix_session,
    tournaments.current_flag                           current_flag,
    tournaments.active_ind                             active_ind,
    tournaments.url                                    url,
    tournaments.notes                                  notes,
    tournaments.created_on                             tournament_created,
    tournaments.created_by                             tournament_created_by,
    tournaments.updated_on                             tournament_updated,
    tournaments.updated_by                             tournament_updated_by,
    tournament_sessions.id                             tournament_session_id,
    tournament_sessions.round_num                      round_num,
    tournament_sessions.session_date                   session_date,
    tournament_sessions.week                           week,
    tournament_sessions.open_registration_on           open_registration_on,
    tournament_sessions.close_registration_on          close_registration_on,
    tournament_sessions.completed_ind                  completed_ind,
    tournament_sessions.completed_on                   completed_on,
    tournament_sessions.created_on                     tournament_session_created,
    tournament_sessions.created_by                     tournament_session_created_by,
    tournament_sessions.updated_on                     tournament_session_updated,
    tournament_sessions.updated_by                     tournament_session_updated_by,
    tournament_courses.id                              tournament_course_id,
    tournament_courses.course_id                       course_id,
    tournament_courses.created_on                      tournament_course_created,
    tournament_courses.created_by                      tournament_course_created_by,
    tournament_courses.updated_on                      tournament_course_updated,
    tournament_courses.updated_by                      tournament_course_updated_by
from 
    wmg_tournaments tournaments,
    wmg_tournament_sessions tournament_sessions,
    wmg_tournament_courses tournament_courses,
    wmg_courses courses
where
    tournament_sessions.tournament_id(+) = tournaments.id and
    tournament_courses.tournament_session_id(+) = tournament_sessions.id
/

create or replace view wmg_tournament_player as 
select 
    tournaments.id                                     tournament_id,
    tournaments.code                                   code,
    tournaments.name                                   name,
    tournaments.prefix_tournament                      prefix_tournament,
    tournaments.prefix_session                         prefix_session,
    tournaments.current_flag                           current_flag,
    tournaments.active_ind                             active_ind,
    tournaments.url                                    url,
    tournaments.notes                                  notes,
    tournaments.created_on                             tournament_created,
    tournaments.created_by                             tournament_created_by,
    tournaments.updated_on                             tournament_updated,
    tournaments.updated_by                             tournament_updated_by,
    tournament_sessions.id                             tournament_session_id,
    tournament_sessions.round_num                      round_num,
    tournament_sessions.session_date                   session_date,
    tournament_sessions.week                           week,
    tournament_sessions.open_registration_on           open_registration_on,
    tournament_sessions.close_registration_on          close_registration_on,
    tournament_sessions.completed_ind                  completed_ind,
    tournament_sessions.completed_on                   completed_on,
    tournament_sessions.created_on                     tournament_session_created,
    tournament_sessions.created_by                     tournament_session_created_by,
    tournament_sessions.updated_on                     tournament_session_updated,
    tournament_sessions.updated_by                     tournament_session_updated_by,
    tournament_players.id                              tournament_player_id,
    tournament_players.player_id                       player_id,
    tournament_players.time_slot                       time_slot,
    tournament_players.created_on                      tournament_player_created,
    tournament_players.created_by                      tournament_player_created_by,
    tournament_players.updated_on                      tournament_player_updated,
    tournament_players.updated_by                      tournament_player_updated_by,
    players.id                                         player_id,
    players.account                                    account,
    players.created_on                                 player_created,
    players.created_by                                 player_created_by,
    players.updated_on                                 player_updated,
    players.updated_by                                 player_updated_by
from 
    wmg_tournaments tournaments,
    wmg_tournament_sessions tournament_sessions,
    wmg_tournament_players tournament_players,
    wmg_players players
where
    tournament_sessions.tournament_id(+) = tournaments.id and
    tournament_players.tournament_session_id(+) = tournament_sessions.id and
    tournament_players.player_id = players.id(+)
/

-- load data
 
-- Generated by Quick SQL Saturday October 01, 2022  22:32:58
 
/*
tournaments
  code vc20  /nn /unique
  name  vc60 /nn /unique
  prefix_tournament vc10 -- The tournament prefix gets concatenated with the session prefix and round_num to form the "WEEK"
  prefix_session vc10
  current_flag vc1
  active_ind vc1 /nn /check Y,N
  url
  notes
  tournament_sessions
    round_num int /nn
    session_date    
    week vc10 -- If prefixes are specified this value gets derived
    open_registration_on tswtz
    close_registration_on tswtz
    completed_ind vc1 /nn /check Y,N
    completed_on tswltz
    tournament_courses -- Courses to be played on a specific session
        course_no int /nn
        course_id /fk courses(id)
    tournament_players -- Players signed up for a specific session
        player_id /fk players(id)
        time_slot vc5 /nn /check 00:00,04:00,08:00,12:00,16:00,20:00
        room_no n

players
  account


view tournament_sessions tournaments tournament_sessions tournament_courses courses
view tournament_player tournaments tournament_sessions tournament_players players

# settings = { prefix: "WMG", onDelete: "RESTRICT", semantics: "CHAR", auditCols: true, language: "EN", APEX: true, createdCol: "created_on", updatedCol: "updated_on" }
*/

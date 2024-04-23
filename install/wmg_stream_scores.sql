-- drop table wmg_stream_scores purge;

create table wmg_stream_scores (
    id                             number generated by default on null as identity 
                                   constraint wmg_stream_scores_id_pk primary key
  , stream_id     number        not null
                                 constraint wmg_stream_scores_stream_fk
                                   references wmg_streams(id) on delete cascade
  , course_id                      number not null
                                   constraint wmg_stream_scores_course_id_fk
                                   references wmg_courses (id) on delete cascade
  , player_id                      number
                                   constraint wmg_stream_scores_player_id_fk
                                   references wmg_players(id) on delete cascade
  , s1                             integer
  , s2                             integer
  , s3                             integer
  , s4                             integer
  , s5                             integer
  , s6                             integer
  , s7                             integer
  , s8                             integer
  , s9                             integer
  , s10                            integer
  , s11                            integer
  , s12                            integer
  , s13                            integer
  , s14                            integer
  , s15                            integer
  , s16                            integer
  , s17                            integer
  , s18                            integer
  , final_score                    integer
  , created_on                     timestamp with local time zone default on null current_timestamp not null
  , created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null
  , updated_on                     timestamp with local time zone
  , updated_by                     varchar2(60 char)
)
/

-- table index
create index wmg_stream_scores_i1 on wmg_stream_scores (course_id);
create index wmg_stream_scores_i2 on wmg_stream_scores (player_id);

alter table wmg_stream_scores add constraint
wmg_stream_scores_one_uk unique (stream_id, player_id, course_id)
/

-- comments
comment on table wmg_stream_scores is 'Rounds by a player while streaming course';
comment on column wmg_stream_scores.s1 is 'hole 1 score';
comment on column wmg_stream_scores.s2 is 'hole 2 score';
comment on column wmg_stream_scores.s3 is 'hole 3 score';
comment on column wmg_stream_scores.s4 is 'hole 4 score';
comment on column wmg_stream_scores.s5 is 'hole 5 score';
comment on column wmg_stream_scores.s6 is 'hole 6 score';
comment on column wmg_stream_scores.s7 is 'hole 7 score';
comment on column wmg_stream_scores.s8 is 'hole 8 score';
comment on column wmg_stream_scores.s9 is 'hole 9 score';
comment on column wmg_stream_scores.s10 is 'hole 10 score';
comment on column wmg_stream_scores.s11 is 'hole 11 score';
comment on column wmg_stream_scores.s12 is 'hole 12 score';
comment on column wmg_stream_scores.s13 is 'hole 13 score';
comment on column wmg_stream_scores.s14 is 'hole 14 score';
comment on column wmg_stream_scores.s15 is 'hole 15 score';
comment on column wmg_stream_scores.s16 is 'hole 16 score';
comment on column wmg_stream_scores.s17 is 'hole 17 score';
comment on column wmg_stream_scores.s18 is 'hole 18 score';

comment on column wmg_stream_scores.final_score is 'Final Score by the player';


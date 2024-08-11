-- drop table wmg_stream_round cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_stream_round (
    id            number        generated always as identity (start with 1) primary key not null
  , stream_id     number        not null
                                 constraint wmg_stream_fk
                                   references wmg_streams(id) on delete cascade
  , current_round number default on null 0
  , current_course_id number
  , current_hole  number
  , current_hole_par number
  , player1_round1_score number default on null 0
  , player2_round1_score number default on null 0
  , player1_round2_score number default on null 0
  , player2_round2_score number default on null 0
  , player1_score number default on null 0
  , player2_score number default on null 0
)
enable primary key using index
/

comment on table wmg_stream_round is 'Stream Running Details';

comment on column wmg_stream_round.id is 'Primary Key ID';
comment on column wmg_stream_round.stream_id is 'Stream info';



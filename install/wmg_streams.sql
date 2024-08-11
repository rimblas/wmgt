-- drop table wmg_streams cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_streams (
    id            number        generated always as identity (start with 1) primary key not null
  , player1_id    number        not null
  , player2_id    number        not null
  , player1_bgcolor varchar2(20)
  , player2_bgcolor varchar2(20)
  , player1_color varchar2(20)
  , player2_color varchar2(20)
  , rounds_total  number        not null
  , course1_id    number
  , course2_id    number
  , room_name     varchar2(20)
  , play_mode     varchar2(10)  not null
  , started_flag  varchar2(1)
  , stream_date   timestamp with local time zone
  , notes         varchar2(4000)
  , active_ind    varchar2(1)   not null
  , created_by      varchar2(60) default on null
                    coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    )
                    not null
  , created_on      timestamp with local time zone default on null current_timestamp not null
  , updated_by      varchar2(60)
  , updated_on      timestamp with local time zone
  , constraint wmg_streams_ck_active
      check (active_ind in ('Y', 'N'))
)
enable primary key using index
/

comment on table wmg_streams is 'List of streams';

comment on column wmg_streams.id is 'Primary Key ID';
comment on column wmg_streams.active_ind is 'Is the record enabled Y/N?';
comment on column wmg_streams.created_by is 'User that created this record';
comment on column wmg_streams.created_on is 'Date the record was first created';
comment on column wmg_streams.updated_by is 'User that last modified this record';
comment on column wmg_streams.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--  DDL for Trigger wmg_streams_u
--------------------------------------------------------
create or replace trigger wmg_streams_u
before update
on wmg_streams
referencing old as old new as new
for each row
begin
  if updating then
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    );
  end if;
end;
/

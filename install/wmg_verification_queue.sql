-- drop table wmg_verification_queue cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_verification_queue (
    id            number        generated always as identity (start with 1) primary key not null
  , week             varchar2(10)
  , easy_player_id   number constraint wmg_verification_qe_players_id_fk
                                   references wmg_players on delete cascade
  , hard_player_id   number constraint wmg_verification_qh_players_id_fk
                                   references wmg_players on delete cascade
  , created_by      varchar2(60) default on null
                    coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    )
                    not null
  , created_on      date         default on null sysdate not null
  , updated_by    varchar2(60)
  , updated_on    date
)
enable primary key using index
/

comment on table wmg_verification_queue is 'Helper table for verification of rooms';

comment on column wmg_verification_queue.id is 'Primary Key ID';


--------------------------------------------------------
--  DDL for Trigger wmg_verification_queue_u
--------------------------------------------------------
create or replace trigger wmg_verification_queue_u
before update
on wmg_verification_queue
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

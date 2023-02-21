-- drop table wmg_wmgt_scores_tmp cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_wmgt_scores_tmp (
    id            number        generated always as identity (start with 1) primary key not null
  , "RANK"        varchar2(32)
  , username      varchar2(128)  not null
  , easy_score    varchar2(32)
  , hard_score    varchar2(32)
  , total_score   varchar2(32)
  , points        varchar2(32)
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

comment on table wmg_wmgt_scores_tmp is 'List of wmg_wmgt_scores_tmp';

comment on column wmg_wmgt_scores_tmp.id is 'Primary Key ID';
comment on column wmg_wmgt_scores_tmp.created_by is 'User that created this record';
comment on column wmg_wmgt_scores_tmp.created_on is 'Date the record was first created';
comment on column wmg_wmgt_scores_tmp.updated_by is 'User that last modified this record';
comment on column wmg_wmgt_scores_tmp.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--  DDL for Trigger wmg_wmgt_scores_tmp_u
--------------------------------------------------------
create or replace trigger wmg_wmgt_scores_tmp_u
before update
on wmg_wmgt_scores_tmp
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

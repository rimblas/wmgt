-- drop table wmg_issues cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_issues (
    id            number        generated always as identity (start with 1) primary key not null
  , display_seq   number        not null
  , code          varchar2(10)  not null unique
  , name          varchar2(32)  not null
  , icon          varchar2(200)
  , description   varchar2(200)
  , tournament_points_override number
  , active_ind    varchar2(1)   not null
  , created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null
  , created_on                     timestamp with local time zone default on null current_timestamp not null
  , updated_by                     varchar2(60 char)
  , updated_on                     timestamp with local time zone
  , constraint wmg_issues_ck_active
      check (active_ind in ('Y', 'N'))
)
enable primary key using index
/

comment on table wmg_issues is 'List of wmg_issues';



comment on column wmg_issues.id is 'Primary Key ID';
comment on column wmg_issues.display_seq is 'Order for displaying the lines';
comment on column wmg_issues.active_ind is 'Is the record enabled Y/N?';
comment on column wmg_issues.tournament_points_override is 'If set, this issue will override tournament points when the tournament closes';
comment on column wmg_issues.created_by is 'User that created this record';
comment on column wmg_issues.created_on is 'Date the record was first created';
comment on column wmg_issues.updated_by is 'User that last modified this record';
comment on column wmg_issues.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--  DDL for Trigger wmg_issues_u
--------------------------------------------------------
create or replace trigger wmg_issues_u
before update
on wmg_issues
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

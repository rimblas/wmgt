-- drop table wmg_guilds cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_guilds (
    id            number        generated by default on null as identity (start with 1) primary key not null
  , display_seq   number        not null
  , code          varchar2(32)  not null
  , name          varchar2(32)  not null
  , discord_id      varchar2(62)  not null
  , discord_avatar  varchar2(62)
  , active_ind    varchar2(1)   not null
  , created_on                     timestamp with local time zone default on null current_timestamp not null
  , created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null
  , updated_on                     timestamp with local time zone
  , updated_by                     varchar2(60 char)
  , constraint wmg_guilds_ck_active
      check (active_ind in ('Y', 'N'))
)
enable primary key using index
/

comment on table wmg_guilds is 'List of guilds, ie. Discord Servers';

comment on column wmg_guilds.id is 'Primary Key ID';
comment on column wmg_guilds.display_seq is 'Order for displaying the lines';
comment on column wmg_guilds.active_ind is 'Is the record enabled Y/N?';
comment on column wmg_guilds.created_by is 'User that created this record';
comment on column wmg_guilds.created_on is 'Date the record was first created';
comment on column wmg_guilds.updated_by is 'User that last modified this record';
comment on column wmg_guilds.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--  DDL for Trigger wmg_guilds_u
--------------------------------------------------------
create or replace trigger wmg_guilds_u
before update
on wmg_guilds
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

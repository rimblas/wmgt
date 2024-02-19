-- drop table wmg_accolades cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_accolades (
    id            number        generated always as identity (start with 1) primary key not null
  , display_seq   number        not null
  , code          varchar2(60)  not null
  , name          varchar2(200) not null
  , description   varchar2(400)
  , icon_class    varchar2(100)
  , season_specific_flag  varchar2(1)
  , active_ind    varchar2(1)   not null
  , created_on    timestamp with local time zone default on null current_timestamp not null
  , created_by    varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null
  , updated_on    timestamp with local time zone
  , updated_by    varchar2(60 char)
  , constraint wmg_accolades_ck_active
      check (active_ind in ('Y', 'N'))
)
enable primary key using index
/

alter table wmg_accolades add constraint wmg_accolades_u unique (code);

comment on table wmg_accolades is 'List of possible Accolades';

comment on column wmg_accolades.id is 'Primary Key ID';
comment on column wmg_accolades.display_seq is 'Order for displaying the lines';
comment on column wmg_accolades.season_specific_flag is 'Is this accolade specific to a season?';
comment on column wmg_accolades.active_ind is 'Is the record enabled Y/N?';
comment on column wmg_accolades.created_by is 'User that created this record';
comment on column wmg_accolades.created_on is 'Date the record was first created';
comment on column wmg_accolades.updated_by is 'User that last modified this record';
comment on column wmg_accolades.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--  DDL for Trigger wmg_accolades_u
--------------------------------------------------------
create or replace trigger wmg_accolades_u
before update
on wmg_accolades
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

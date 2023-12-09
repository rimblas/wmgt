PRO .. wmg_webhooks 

drop table wmg_webhooks cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_webhooks (
    id              number        generated always as identity (start with 1) primary key not null
  , code            varchar2(10)  not null
  , name            varchar2(60)  not null
  , description     varchar2(200)
  , webhook_url     varchar2(1000) not null
  , owner_username  varchar2(60)
  , active_ind      varchar2(1)   not null
  , created_by      varchar2(60) default on null
                    coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                    )
                    not null
  , created_on      date         default on null sysdate not null
  , updated_by      varchar2(60)
  , updated_on      date
  , constraint wmg_webhooks_ck_active
      check (active_ind in ('Y', 'N'))
)
enable primary key using index
/
alter table wmg_webhooks add constraint wmg_webhooks_u unique (code);

comment on table wmg_webhooks is 'List of Discord Webhooks';

comment on column wmg_webhooks.id is 'Primary Key ID';
comment on column wmg_webhooks.webhook_url is 'Class used to style the player name';
comment on column wmg_webhooks.active_ind is 'Is the record enabled Y/N?';
comment on column wmg_webhooks.created_by is 'User that created this record';
comment on column wmg_webhooks.created_on is 'Date the record was first created';
comment on column wmg_webhooks.updated_by is 'User that last modified this record';
comment on column wmg_webhooks.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--                        123456789012345678901234567890
create or replace trigger wmg_webhooks_u_trg
before update
on wmg_webhooks
referencing old as old new as new
for each row
begin
  :new.updated_on := sysdate;
  :new.updated_by := coalesce(
                         sys_context('APEX$SESSION','app_user')
                       , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                       , sys_context('userenv','session_user')
                     );
end;
/

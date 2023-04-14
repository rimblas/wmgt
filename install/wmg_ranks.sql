PRO .. wmg_ranks 

-- drop table wmg_ranks cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table wmg_ranks (
    id              number        generated always as identity (start with 1) primary key not null
  , display_seq     number        not null
  , code            varchar2(10)  not null
  , name            varchar2(32)  not null
  , profile_class   varchar2(32)
  , list_class      varchar2(32)
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
  , constraint wmg_ranks_ck_active
      check (active_ind in ('Y', 'N'))
)
enable primary key using index
/
alter table wmg_ranks add constraint wmg_ranks_u unique (code);

comment on table wmg_ranks is 'List of wmg_ranks';

comment on column wmg_ranks.id is 'Primary Key ID';
comment on column wmg_ranks.display_seq is 'Order for displaying the lines';
comment on column wmg_ranks.profile_class is 'Class used to style the player name';
comment on column wmg_ranks.active_ind is 'Is the record enabled Y/N?';
comment on column wmg_ranks.created_by is 'User that created this record';
comment on column wmg_ranks.created_on is 'Date the record was first created';
comment on column wmg_ranks.updated_by is 'User that last modified this record';
comment on column wmg_ranks.updated_on is 'Date the record was last modified';


--------------------------------------------------------
--                        123456789012345678901234567890
create or replace trigger wmg_ranks_u_trg
before update
on wmg_ranks
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

create table wmg_tournament_control (
    tournament_type_code           varchar2(10 char) 
                                   constraint wmg_tournament_control_pk primary key
  , tournament_session_id          number 
                                   constraint wmg_tournament_control_fk
                                   references wmg_tournament_sessions(id)
  , created_on                     timestamp with local time zone 
                                   default on null current_timestamp not null
  , created_by                     varchar2(60 char) 
                                   default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null
  , updated_on                     timestamp with local time zone
  , updated_by                     varchar2(60 char)
)
;

-- comments
comment on table wmg_tournament_control is 'Maintains pointers to active tournament sessions for each tournament type (WMGT, KWT, FHIT)';
comment on column wmg_tournament_control.tournament_type_code is 'Tournament type identifier (WMGT, KWT, FHIT)';
comment on column wmg_tournament_control.tournament_session_id is 'Reference to active tournament session (nullable to support tournament breaks)';

-- triggers
create or replace trigger wmg_tournament_control_bu
    before update 
    on wmg_tournament_control
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_tournament_control_bu;
/

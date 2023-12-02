-- drop objects
-- drop table wmg_notification_subs cascade constraints;

-- create tables
create table wmg_notification_subs (
    id                             number generated by default on null as identity 
                                   constraint wmg_notification_subs_id_pk primary key,
    player_id                      number not null
                                   constraint wmg_notification_subs_player_i_fk
                                   references wmg_players(id),
    notification_type_id           number not null
                                   constraint wmg_notification_subs_noti_type_i_fk
                                   references wmg_notification_types(id),
    notification_method            varchar2(20 char)
                                   constraint wmg_notification_subs_method_ck
                                   check (notification_method in ('EMAIL', 'WEBHOOK')) not null,
    name                           varchar2(60 char)
                                   constraint wmg_notification_subs_name_unq unique not null,
    display_seq                    integer not null,
    description                    varchar2(4000 char),
    icon_class                     varchar2(100 char),
    player_selectable_ind          varchar2(1 char) default 'N' constraint wmg_notification_subs_p_select_ind_ck
                                   check (player_selectable_ind        in ('Y','N')) not null,
    td_selectable_ind              varchar2(1 char) default 'N' constraint wmg_notification_subs_td_select_ind_ck
                                   check (td_selectable_ind        in ('Y','N')) not null,
    active_ind                     varchar2(1 char) default 'Y' constraint wmg_notification_subs_active_ind_ck
                                   check (active_ind in ('Y','N')) not null,
    created_on                     timestamp with local time zone default on null current_timestamp not null,
    created_by                     varchar2(60 char) default on null coalesce(sys_context('APEX$SESSION','APP_USER'),user) not null,
    updated_on                     timestamp with local time zone,
    updated_by                     varchar2(255 char)
)
;

comment on table wmg_notification_subs is 'Player Notifications Subscriptions';

-- triggers
create or replace trigger wmg_notification_subs_bu
    before update 
    on wmg_notification_subs
    for each row
begin
    :new.updated_on := current_timestamp;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
end wmg_notification_subs_bu;
/

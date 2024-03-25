delete from wmg_parameters where name_key = 'ENV';

insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'Environment'   -- category
  , 'ENV'   -- name_key
  , 'FHIT'   -- value
  , 'Environment code'   -- description
)
/

delete from wmg_parameters where name_key = 'EMAIL_OVERRIDE';
insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'Notifications' --  category
  , 'EMAIL_OVERRIDE' --  name_key
  , 'jorge@rimblas.com' --  value
  , 'When set, is the Email that will receive all emails (instead of the designated address)' --  description
)
/

delete from wmg_parameters where name_key = 'FROM_EMAIL';

insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'Notifications'   -- category
  , 'FROM_EMAIL'   -- name_key
  , 'notification@myfhit.com'   -- value
  , 'Single Email address used to send all emails'   -- description
)
/


delete from wmg_parameters where name_key = 'NEW_PLAYER_NOTIFICATION_EMAILS';
insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'Notifications'   -- category
  , 'NEW_PLAYER_NOTIFICATION_EMAILS'   -- name_key
  , 'jorge@rimblas.com,FugoHallahallarin@gmail.com'   -- value
  , 'Emails to notify when a new player signs up'   -- description
)
/

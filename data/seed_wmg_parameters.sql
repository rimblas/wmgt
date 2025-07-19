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
  , ''   -- value
  , 'Emails to notify when a new player signs up'   -- description
)
/

delete from wmg_parameters where name_key = 'GLOBAL_APP_BANNER';
insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'Notifications'   -- category
  , 'GLOBAL_APP_BANNER'   -- name_key
  , 'There was a Walkabout Mini Gold update on Thursday, June 13. You must be on this new version (v5.1) in order to play the tournament.<br>'
  || 'Updating is slow, make sure you do it with plenty of time before the tournamnent.'   -- value
  , 'Global Notification for the app. If set it will display in serverl pages as a global message.'   -- description
)
/

delete from wmg_parameters where name_key = 'GLOBAL_APP_BANNER_ON';
insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'Notifications'   -- category
  , 'GLOBAL_APP_BANNER_ON'   -- name_key
  , 'NO'   -- value
  , 'Set to YES or NO to enable/disable the Global Notification Banner for the app. Use GLOBAL_APP_BANNER to set the banner text'   -- description
)
/


delete from wmg_parameters where name_key = 'FHIT_DOUBLES_LIMITS';

insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'FHIT'   -- category
  , 'FHIT_DOUBLES_LIMITS'   -- name_key
  , '32'   -- value
  , 'FHIT Doubles Tournament Team Registration limit'   -- description
)
/


delete from wmg_parameters where name_key = 'FHIT_DOUBLES_LIMITS';

insert into wmg_parameters (
    category
  , name_key
  , value
  , description
)
values (
    'FHIT'   -- category
  , 'FHIT_DOUBLES_LIMITS'   -- name_key
  , '32'   -- value
  , 'FHIT Doubles Tournament Team Registration limit'   -- description
)
/

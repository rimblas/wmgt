--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENTS_CODE_UNQ
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENTS_CODE_UNQ" ON "WMG_TOURNAMENTS" ("CODE") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYERS_U03
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PLAYERS_U03" ON "WMG_PLAYERS" ("DISCORD_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_ROUNDS_01
--------------------------------------------------------

  CREATE INDEX "WMG_ROUNDS_01" ON "WMG_ROUNDS" ("WEEK") ;



--------------------------------------------------------
--  DDL for Index WMG_COURSE_STROKES_I1
--------------------------------------------------------

  CREATE INDEX "WMG_COURSE_STROKES_I1" ON "WMG_COURSE_STROKES" ("COURSE_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_BADGE_TYPES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_BADGE_TYPES_ID_PK" ON "WMG_BADGE_TYPES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_VERIFICATION_QUEUE_FOREIGN_KEY_INDEX_HARD_PLAYER_ID
--------------------------------------------------------

  CREATE INDEX "WMG_VERIFICATION_QUEUE_FOREIGN_KEY_INDEX_HARD_PLAYER_ID" ON "WMG_VERIFICATION_QUEUE" ("HARD_PLAYER_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_COU_I2
--------------------------------------------------------

  CREATE INDEX "WMG_TOURNAMENT_COU_I2" ON "WMG_TOURNAMENT_COURSES" ("TOURNAMENT_SESSION_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_PLA_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENT_PLA_ID_PK" ON "WMG_TOURNAMENT_PLAYERS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_PLAYERS_FOREIGN_KEY_INDEX_PLAYER_ID
--------------------------------------------------------

  CREATE INDEX "WMG_TOURNAMENT_PLAYERS_FOREIGN_KEY_INDEX_PLAYER_ID" ON "WMG_TOURNAMENT_PLAYERS" ("PLAYER_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_VERIFICATION_QUEUE_FOREIGN_KEY_INDEX_EASY_PLAYER_ID
--------------------------------------------------------

  CREATE INDEX "WMG_VERIFICATION_QUEUE_FOREIGN_KEY_INDEX_EASY_PLAYER_ID" ON "WMG_VERIFICATION_QUEUE" ("EASY_PLAYER_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_ROUNDS_ONE_UK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_ROUNDS_ONE_UK" ON "WMG_ROUNDS" ("PLAYERS_ID", "WEEK", "COURSE_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_COURSE_PREVIEWS_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_COURSE_PREVIEWS_ID_PK" ON "WMG_COURSE_PREVIEWS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_BADGE_TYPES_CODE_UNQ
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_BADGE_TYPES_CODE_UNQ" ON "WMG_BADGE_TYPES" ("CODE") ;



--------------------------------------------------------
--  DDL for Index WMG_COURSE_PREVIEWS_U01
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_COURSE_PREVIEWS_U01" ON "WMG_COURSE_PREVIEWS" ("COURSE_ID", "HOLE") ;



--------------------------------------------------------
--  DDL for Index ROUNDS_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "ROUNDS_ID_PK" ON "WMG_ROUNDS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENTS_NAME_UNQ
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENTS_NAME_UNQ" ON "WMG_TOURNAMENTS" ("NAME") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_ROOM_U1
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENT_ROOM_U1" ON "WMG_TOURNAMENT_ROOMS" ("TOURNAMENT_SESSION_ID", "TIME_SLOT", "ROOM_NO") ;



--------------------------------------------------------
--  DDL for Index WMG_ROUNDS_UNPIVOT_MV_U
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_ROUNDS_UNPIVOT_MV_U" ON "WMG_ROUNDS_UNPIVOT_MV" ("WEEK", "PLAYER_ID", "COURSE_ID", "H") ;



--------------------------------------------------------
--  DDL for Index COURSES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "COURSES_ID_PK" ON "WMG_COURSES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_BADGE_TYPES_NAME_UNQ
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_BADGE_TYPES_NAME_UNQ" ON "WMG_BADGE_TYPES" ("NAME") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_UNICORNS_FOREIGN_KEY_INDEX_SCORE_TOURNAMENT_SESSION_ID
--------------------------------------------------------

  CREATE INDEX "WMG_PLAYER_UNICORNS_FOREIGN_KEY_INDEX_SCORE_TOURNAMENT_SESSION_ID" ON "WMG_PLAYER_UNICORNS" ("SCORE_TOURNAMENT_SESSION_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_STREAM_SCORES_I2
--------------------------------------------------------

  CREATE INDEX "WMG_STREAM_SCORES_I2" ON "WMG_STREAM_SCORES" ("PLAYER_ID") ;



--------------------------------------------------------
--  DDL for Index COURSES_CODE_UNQ
--------------------------------------------------------

  CREATE UNIQUE INDEX "COURSES_CODE_UNQ" ON "WMG_COURSES" ("CODE") ;



--------------------------------------------------------
--  DDL for Index WMG_NOTES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_NOTES_ID_PK" ON "WMG_NOTES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_COU_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENT_COU_ID_PK" ON "WMG_TOURNAMENT_COURSES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_SESSIONS_UK1
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENT_SESSIONS_UK1" ON "WMG_TOURNAMENT_SESSIONS" ("WEEK") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_BADGES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PLAYER_BADGES_ID_PK" ON "WMG_PLAYER_BADGES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_ROUNDS_I2
--------------------------------------------------------

  CREATE INDEX "WMG_ROUNDS_I2" ON "WMG_ROUNDS" ("PLAYERS_ID") ;



--------------------------------------------------------
--  DDL for Index PLAYERS_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "PLAYERS_ID_PK" ON "WMG_PLAYERS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENTS_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENTS_ID_PK" ON "WMG_TOURNAMENTS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_WEBHOOKS_U
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_WEBHOOKS_U" ON "WMG_WEBHOOKS" ("CODE") ;



--------------------------------------------------------
--  DDL for Index MESSAGES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "MESSAGES_ID_PK" ON "WMG_MESSAGES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_SES_I1
--------------------------------------------------------

  CREATE INDEX "WMG_TOURNAMENT_SES_I1" ON "WMG_TOURNAMENT_SESSIONS" ("TOURNAMENT_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYERS_U02
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PLAYERS_U02" ON "WMG_PLAYERS" (LOWER("NAME")) ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_SES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENT_SES_ID_PK" ON "WMG_TOURNAMENT_SESSIONS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_UNICORNS_I01
--------------------------------------------------------

  CREATE INDEX "WMG_PLAYER_UNICORNS_I01" ON "WMG_PLAYER_UNICORNS" ("PLAYER_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_PLA_U1
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENT_PLA_U1" ON "WMG_TOURNAMENT_PLAYERS" ("TOURNAMENT_SESSION_ID", "PLAYER_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_BADGES_U01
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PLAYER_BADGES_U01" ON "WMG_PLAYER_BADGES" ("PLAYER_ID", "BADGE_TYPE_CODE", "TOURNAMENT_SESSION_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_ROOM_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_TOURNAMENT_ROOM_ID_PK" ON "WMG_TOURNAMENT_ROOMS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PARAMETERS_U
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PARAMETERS_U" ON "WMG_PARAMETERS" ("NAME_KEY") ;



--------------------------------------------------------
--  DDL for Index WMG_TOURNAMENT_COU_I1
--------------------------------------------------------

  CREATE INDEX "WMG_TOURNAMENT_COU_I1" ON "WMG_TOURNAMENT_COURSES" ("COURSE_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_COURSE_STROKES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_COURSE_STROKES_ID_PK" ON "WMG_COURSE_STROKES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_NOTIFICATION_TYPES_NAME_UNQ
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_NOTIFICATION_TYPES_NAME_UNQ" ON "WMG_NOTIFICATION_TYPES" ("NAME") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_UNICORNS_FOREIGN_KEY_INDEX_AWARD_TOURNAMENT_SESSION_ID
--------------------------------------------------------

  CREATE INDEX "WMG_PLAYER_UNICORNS_FOREIGN_KEY_INDEX_AWARD_TOURNAMENT_SESSION_ID" ON "WMG_PLAYER_UNICORNS" ("AWARD_TOURNAMENT_SESSION_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_UNICORNS_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PLAYER_UNICORNS_ID_PK" ON "WMG_PLAYER_UNICORNS" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_RANKS_U
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_RANKS_U" ON "WMG_RANKS" ("CODE") ;



--------------------------------------------------------
--  DDL for Index WMG_ROUNDS_I1
--------------------------------------------------------

  CREATE INDEX "WMG_ROUNDS_I1" ON "WMG_ROUNDS" ("COURSE_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_UNICORNS_U01
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PLAYER_UNICORNS_U01" ON "WMG_PLAYER_UNICORNS" ("COURSE_ID", "PLAYER_ID", "H") ;



--------------------------------------------------------
--  DDL for Index WMG_NOTIFICATION_TYPES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_NOTIFICATION_TYPES_ID_PK" ON "WMG_NOTIFICATION_TYPES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_STREAM_SCORES_ID_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_STREAM_SCORES_ID_PK" ON "WMG_STREAM_SCORES" ("ID") ;



--------------------------------------------------------
--  DDL for Index WMG_STREAM_SCORES_ONE_UK
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_STREAM_SCORES_ONE_UK" ON "WMG_STREAM_SCORES" ("STREAM_ID", "PLAYER_ID", "COURSE_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_NOTIFICATION_TYPES_CODE_UNQ
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_NOTIFICATION_TYPES_CODE_UNQ" ON "WMG_NOTIFICATION_TYPES" ("CODE") ;



--------------------------------------------------------
--  DDL for Index WMG_STREAM_SCORES_I1
--------------------------------------------------------

  CREATE INDEX "WMG_STREAM_SCORES_I1" ON "WMG_STREAM_SCORES" ("COURSE_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYER_BADGES_I01
--------------------------------------------------------

  CREATE INDEX "WMG_PLAYER_BADGES_I01" ON "WMG_PLAYER_BADGES" ("TOURNAMENT_SESSION_ID") ;



--------------------------------------------------------
--  DDL for Index WMG_PLAYERS_U01
--------------------------------------------------------

  CREATE UNIQUE INDEX "WMG_PLAYERS_U01" ON "WMG_PLAYERS" (LOWER("ACCOUNT")) ;




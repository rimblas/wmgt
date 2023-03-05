

alter table wmg_tournament_players add points number;
comment on column wmg_tournament_players.points is 'Points scored by a player on the session. 1st = 25, 2nd = 21, etc...';

alter table wmg_tournament_players add discarded_points_flag varchar2(1);
comment on column wmg_tournament_players.discarded_points_flag is 'Indicates these points have been discarded as 1 out of every 3 sessions gets points discarded';

alter table wmg_players add (
  country_code                   varchar2(5),
      discord_id                     number,
    discord_avatar                 varchar2(62),
    discord_discriminator          varchar2(10)
);

comment on column wmg_players.account is 'discord name';
comment on column wmg_players.discord_avatar is 'Get an avatar via https://cdn.discordapp.com/avatars/{G_DISCORD_ID}/{G_DISCORD_AVATAR}.png';


alter  table wmg_rounds add (
    final_score                    integer,
    override_score                 integer,
    override_reason                varchar2(500),
    override_by                    varchar2(60 char),
    override_on                    timestamp with local time zone
);


alter table wmg_tournament_sessions add (
    registration_closed_flag       varchar2(1)
);



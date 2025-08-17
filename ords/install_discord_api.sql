-- Installation script for Discord Bot API endpoints
-- Run this script to install the Discord Bot API endpoints

PROMPT Installing Discord Bot API endpoints...

-- First, run the main API definition
@@discord_bot_api.sql

PROMPT Discord Bot API endpoints installed successfully.
PROMPT 
PROMPT Available endpoints:
PROMPT   GET  /ords/wmgt/api/tournaments/current
PROMPT   POST /ords/wmgt/api/tournaments/register
PROMPT   POST /ords/wmgt/api/tournaments/unregister
PROMPT   GET  /ords/wmgt/api/players/registrations/{discord_id}
PROMPT 
PROMPT Installation complete.
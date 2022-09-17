set define off
create or replace package wmg_error_handler
AS


/*
 * Use with:
 * wmg_error_handler.error_handler_logging_session
 *
 */

FUNCTION error_handler_logging_session(
    p_error IN apex_error.t_error )
  RETURN apex_error.t_error_result;
    --============================================================================
  -- F O R C E   P L / S Q L   E R R O R   
  --============================================================================
PROCEDURE force_plsql_error;
END wmg_error_handler;
/

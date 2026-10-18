create or replace package body wmg_verification_engine
is

--------------------------------------------------------------------------------
-- CONSTANTS
/**
 * @constant gc_scope_prefix Standard logger package name
 */
gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';
subtype scope_t is varchar2(128);

c_total_holes constant number := 18;

/**
 * Log procedure - uses logger if available, otherwise apex_debug
 *
 * @param p_msg Message to log
 * @param p_ctx Context/scope for the log entry
 */
procedure log(
    p_msg  in varchar2,
    p_ctx  in varchar2 default null
)
is
begin
  $IF $$NOLOGGER $THEN
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
  $ELSE
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $END
end log;

/**
 * Match a card player name to a tournament database player
 * Uses wmg_leaderboard_util.get_player for consistent player matching
 *
 * @param p_card_player_name Player name from card structure
 * @return Player ID if match found, NULL if no match
 */
function match_player(
    p_card_player_name in varchar2
) return number
is
  l_scope scope_t := gc_scope_prefix || 'match_player';
  l_player_id number;
begin
  $IF $$VERBOSE_OUTPUT $THEN
  log('BEGIN - matching player: ' || p_card_player_name, l_scope);
  $END

  
  -- Use existing wmg_leaderboard_util.get_player for consistent matching
  l_player_id := wmg_leaderboard_util.get_player(p_card_player_name);
  
  $IF $$VERBOSE_OUTPUT $THEN
  if l_player_id is not null then
    log('Player matched: ' || p_card_player_name || ' -> ID: ' || l_player_id, l_scope);
  else
    log('No match found for player: ' || p_card_player_name, l_scope);
  end if;
  
  log('END', l_scope);
  $END
  return l_player_id;
  
exception
  when others then
    logger.log_error(p_text => 'Error in match_player: ' || p_card_player_name, p_scope => l_scope);
    log('Error matching player ' || p_card_player_name || ': ' || sqlerrm, l_scope);
    return null;
end match_player;




/**
 * Validate hole-by-hole scores between card and round data
 *
 * @param p_card_scores Card scores collection
 * @param p_round_scores Round scores collection  
 * @return TRUE if all scores match exactly, FALSE otherwise
 */
function validate_hole_scores(
    p_card_scores    in score_comparison_tbl,
    p_round_scores   in score_comparison_tbl
) return boolean
is
  l_scope scope_t := gc_scope_prefix || 'validate_hole_scores';
  l_match_count number := 0;
  l_total_holes number := 0;
begin
  log('BEGIN - validating hole scores', l_scope);
  
  -- Count total holes to validate
  l_total_holes := c_total_holes;
  
  if l_total_holes = 0 then
    log('No card scores to validate', l_scope);
    return false;
  end if;
  
  if p_round_scores.count != l_total_holes then
    log('Score count mismatch - Card: ' || l_total_holes || ', Round: ' || p_round_scores.count, l_scope);
    return false;
  end if;
  
  -- Compare each hole score
  for i in 1..l_total_holes loop
    if p_card_scores(i).card_score = p_round_scores(i).round_score and
       p_card_scores(i).hole_num = p_round_scores(i).hole_num then
      l_match_count := l_match_count + 1;
      $IF $$VERBOSE_OUTPUT $THEN
      log('.. Hole ' || p_card_scores(i).hole_num || ' matches: ' || p_card_scores(i).card_score, l_scope);
      $END
    else
      log('.. Hole ' || p_card_scores(i).hole_num || ' mismatch - Card: ' || 
          p_card_scores(i).card_score || ', Round: ' || p_round_scores(i).round_score, l_scope);
    end if;
  end loop;
  
  log('.. Matched ' || l_match_count || ' of ' || l_total_holes || ' holes', l_scope);
  log('END', l_scope);
  
  return (l_match_count = l_total_holes);
  
exception
  when others then
    log('Error validating hole scores: ' || sqlerrm, l_scope);
    return false;
end validate_hole_scores;




/**
 * Validate course total scores
 *
 * @param p_card_total Total from card structure
 * @param p_round_total Total from round data
 * @return TRUE if totals match exactly, FALSE otherwise
 */
function validate_course_totals(
    p_card_total     in number,
    p_round_total    in number
) return boolean
is
  l_scope scope_t := gc_scope_prefix || 'validate_course_totals';
begin
  log('BEGIN - validating totals - Card: ' || p_card_total || ', Round: ' || p_round_total, l_scope);
  
  if p_card_total is null or p_round_total is null then
    log('One or both totals are null', l_scope);
    return false;
  end if;
  
  if p_card_total = p_round_total then
    log('.. Totals match', l_scope);
    return true;
  else
    log('.. Totals do not match ⚠', l_scope);
    return false;
  end if;
  
  log('END', l_scope);
  
exception
  when others then
    log('Error validating course totals: ' || sqlerrm, l_scope);
    return false;
end validate_course_totals;




/**
 * Get hole-by-hole scores from card structure for a specific player and run
 * Implements logic to query wmg_card_runs, wmg_card_players, wmg_card_scores tables
 *
 * @param p_card_run_id Card run ID
 * @param p_card_player_name Player name from card structure
 * @return Collection of card scores by hole
 */
function get_card_scores(
      p_card_run_id      in number
    , p_card_player_id   in number
) return score_comparison_tbl
is
  l_scope scope_t := gc_scope_prefix || 'get_card_scores';

  l_scores score_comparison_tbl := score_comparison_tbl();
  l_score_rec score_comparison_rec;
  l_card_exists number := 0;
begin
  log('BEGIN - getting card scores for run ' || p_card_run_id || ', card_player_id: ' || p_card_player_id, l_scope);
    
  -- Get hole-by-hole scores from wmg_card_scores table
  for rec in (
    select cs.hole_num, cs.strokes
    from wmg_card_players cp
     join wmg_card_scores cs on cs.player = cp.player and cs.run_id = cp.run_id
    where cs.run_id = p_card_run_id
      and cp.id = p_card_player_id
    order by cs.hole_num
  )
  loop
    
    l_scores.extend;
    l_score_rec.hole_num := rec.hole_num;
    l_score_rec.card_score := rec.strokes;
    l_score_rec.player_id := null; -- Will be set by calling function
    l_score_rec.course_id := null; -- Will be set by calling function
    l_score_rec.room_no := null;   -- Will be set by calling function
    l_score_rec.round_score := null; -- Not applicable for card scores
    l_score_rec.match_flag := null;  -- Will be determined during comparison
    
    l_scores(l_scores.count) := l_score_rec;
    $IF $$VERBOSE_OUTPUT $THEN
    log('.. Card score - Hole ' || rec.hole_num || ': ' || rec.strokes, l_scope);
    $END

  end loop;
  
  -- Validate we have the expected number of holes (18)
  if l_scores.count > 0 and l_scores.count != c_total_holes then
    log('.. Warning: Expected ' || c_total_holes || ' holes but found ' || l_scores.count, l_scope);
    return score_comparison_tbl();
  end if;

  -- Retrieve the player score and store it in the first record for reference
  l_score_rec := l_scores(1);
  select distinct cp.relative
    into l_score_rec.final_score
    from wmg_card_players cp
     join wmg_card_scores cs on cs.player = cp.player and cs.run_id = cp.run_id
    where cs.run_id = p_card_run_id
      and cp.id = p_card_player_id
     fetch first row only;

  l_scores(1) := l_score_rec;

  log('Retrieved ' || l_scores.count || ' card scores', l_scope);
  log('END', l_scope);
  
  return l_scores;
  
exception
  when others then
    log('Error getting card scores: ' || sqlerrm, l_scope);
    return score_comparison_tbl();
end get_card_scores;




/**
 * Get hole-by-hole scores from tournament rounds for a specific player
 * Implements logic to query wmg_rounds table using simple SELECT queries
 *
 * @param p_tournament_session_id Tournament session ID
 * @param p_player_id Player ID
 * @param p_course_id Course ID
 * @return Collection of round scores by hole
 */
function get_round_scores(
    p_tournament_session_id in number,
    p_player_id            in number,
    p_course_id            in number
) return score_comparison_tbl
is
  l_scope scope_t := gc_scope_prefix || 'get_round_scores';
  l_scores score_comparison_tbl := score_comparison_tbl();
  l_score_rec score_comparison_rec;

begin
  log('BEGIN - getting round scores for player ID: ' || p_player_id || ', course: ' || p_course_id, l_scope);
  

  -- Get hole-by-hole scores from wmg_rounds_unpivot_mv
  for hole_rec in (
    select u.player_id,
           u.course_id,
           u.h as hole_num,
           u.score as round_score
    from wmg_rounds_unpivot_mv u
     join wmg_tournament_sessions ts on ts.week = u.week
    where u.player_id = p_player_id
      and u.course_id = p_course_id
      and ts.id = p_tournament_session_id
    order by u.h
  ) 
  loop
    
    l_scores.extend;
    l_score_rec.player_id := hole_rec.player_id;
    l_score_rec.course_id := hole_rec.course_id;
    l_score_rec.hole_num := hole_rec.hole_num;
    l_score_rec.round_score := hole_rec.round_score;
    l_scores(l_scores.count) := l_score_rec;

    $IF $$VERBOSE_OUTPUT $THEN
    log('.. Round score - Hole ' || hole_rec.hole_num || ': ' || hole_rec.round_score, l_scope);
    $END

  end loop;

  -- Retrieve the player score and store it in the first record for reference
  l_score_rec := l_scores(1);

  select r.final_score
    into l_score_rec.final_score
    from wmg_rounds r
   where r.players_id = p_player_id
     and r.course_id = p_course_id
     and r.tournament_session_id = p_tournament_session_id;

  l_scores(1) := l_score_rec;

  log('Retrieved ' || l_scores.count || ' round scores', l_scope);
  log('END', l_scope);
  
  return l_scores;
  
exception
  when others then
    log('Error getting round scores: ' || sqlerrm, l_scope);
    return score_comparison_tbl();
end get_round_scores;



/**
 * Calculate course total from hole scores
 *
 * @param p_scores Collection of hole scores
 * @return Total score for the course
 */
function calculate_course_total(
    p_scores in score_comparison_tbl
) return number
is
  l_scope scope_t := gc_scope_prefix || 'calculate_course_total';
  l_total number := 0;
begin
  log('BEGIN - calculating course total', l_scope);
  
  if p_scores is null or p_scores.count = 0 then
    log('No scores provided for total calculation', l_scope);
    return null;
  end if;
  
  if g_quick_verify then
    log('.. Quick verify mode enabled - returning final_score', l_scope);
    return p_scores(1).final_score;
  end if;

  for i in 1..p_scores.count loop
    if p_scores(i).card_score is not null then
      l_total := l_total + p_scores(i).card_score;
    elsif p_scores(i).round_score is not null then
      l_total := l_total + p_scores(i).round_score;
    end if;
  end loop;
  
  log('Calculated total: ' || l_total, l_scope);
  log('END', l_scope);
  
  return l_total;
  
exception
  when others then
    log('Error calculating course total: ' || sqlerrm, l_scope);
    return null;
end calculate_course_total;




/**
 * Compare scores between card structure and tournament rounds for a single player
 *
 * @param p_tournament_session_id Tournament session ID
 * @param p_player_id Player ID from tournament database
 * @param p_course_id Course ID
 * @param p_card_run_id Card run ID
 * @return Verification result record
 */
function compare_player_scores(
    p_tournament_session_id in number
  , p_course_id            in number
  , p_player_id            in number
  , p_card_run_id          in number
  , p_card_player_id       in number
) return verification_result_rec
is
  l_scope scope_t := gc_scope_prefix || 'compare_player_scores';

  l_result verification_result_rec;
  l_card_scores score_comparison_tbl;
  l_round_scores score_comparison_tbl;
  l_card_total number;
  l_round_total number;
  l_mismatch_details varchar2(4000) := '';
begin
  log('BEGIN', l_scope);
  
  -- Initialize result
  l_result.tournament_session_id := p_tournament_session_id;
  l_result.player_id := p_player_id;
  l_result.card_run_id := p_card_run_id;
  l_result.verification_status := 'SUCCESS';
  
  -- Get scores from both sources
  l_card_scores := get_card_scores(p_card_run_id, p_card_player_id);
  l_round_scores := get_round_scores(p_tournament_session_id, p_player_id, p_course_id);
  
  if g_quick_verify then
    log('.. Quick verify mode enabled - skipping hole-by-hole validation', l_scope);
    goto verify_totals;
  end if;

  -- Check if we have data from both sources
  if l_card_scores.count = 0 then
    l_result.verification_status := 'NO_MATCH';
    l_result.mismatch_details := 'No card scores found for player';
    log('No card scores found', l_scope);
    return l_result;
  end if;
  
  if l_round_scores.count = 0 then
    l_result.verification_status := 'NO_MATCH';
    l_result.mismatch_details := 'No round scores found for player';
    log('No round scores found', l_scope);
    return l_result;
  end if;
  
  -- Validate hole-by-hole scores
  if not validate_hole_scores(l_card_scores, l_round_scores) then
    l_result.verification_status := 'FAILED';
    l_mismatch_details := 'Hole score mismatches found';
    
    -- Build detailed mismatch information
    for i in 1..least(l_card_scores.count, l_round_scores.count) loop
      if l_card_scores(i).card_score != l_round_scores(i).round_score then
        l_mismatch_details := l_mismatch_details || 
          ' | Hole ' || l_card_scores(i).hole_num || 
          ': Card=' || l_card_scores(i).card_score || 
          ', Round=' || l_round_scores(i).round_score;
      end if;
    end loop;

    l_result.mismatch_details := l_mismatch_details;
    log('.. Hole score validation failed', l_scope);
    return l_result;
  end if;

  <<verify_totals>>
  -- Validate course totals
  l_card_total := calculate_course_total(l_card_scores);
  l_round_total := calculate_course_total(l_round_scores);
  
  if not validate_course_totals(l_card_total, l_round_total) and l_result.verification_status = 'SUCCESS' then
    l_result.verification_status := 'FAILED';
    l_result.mismatch_details := 'Course total mismatch: Card=' || l_card_total || ', Round=' || l_round_total;
    log('Course total validation failed', l_scope);
    return l_result;
  end if;
  
  -- All validations passed
  l_result.verification_status := 'SUCCESS';
  l_result.mismatch_details := null;
  log('.. All score validations PASSED', l_scope);
  
  log('END', l_scope);
  return l_result;
  
exception
  when others then
    log('Error comparing player scores: ' || sqlerrm, l_scope);
    l_result.verification_status := 'FAILED';
    l_result.mismatch_details := 'Error during comparison: ' || sqlerrm;
    return l_result;
end compare_player_scores;





/**
 * Update verification status for a single tournament player
 * Implements atomic transaction handling for verification status updates
 *
 * @param p_tournament_session_id Tournament session ID
 * @param p_player_id Player ID to update
 * @param p_verified_flag Verification flag ('Y' or 'N')
 * @param p_verified_by Who verified the scorecard (default 'SYSTEM')
 * @param p_verified_note Optional verification note
 */
procedure update_verification_status(
    p_tournament_session_id in number,
    p_player_id            in number,
    p_verified_flag        in varchar2 default 'Y',
    p_verified_by          in varchar2 default 'SYSTEM',
    p_verified_note        in varchar2 default null
)
is
  l_scope scope_t := gc_scope_prefix || 'update_verification_status';
  l_rows_updated number := 0;
begin
  log('BEGIN - updating verification status for player ' || p_player_id || 
      ' in session ' || p_tournament_session_id, l_scope);
  
  -- Validate input parameters
  if p_tournament_session_id is null then
    raise_application_error(-20001, 'Tournament session ID cannot be null');
  end if;
  
  if p_player_id is null then
    raise_application_error(-20002, 'Player ID cannot be null');
  end if;
  
  -- Update verification status with atomic transaction
  update wmg_tournament_players
  set verified_score_flag = p_verified_flag,
      verified_by = p_verified_by,
      verified_on = current_timestamp,
      verified_note = p_verified_note
  where tournament_session_id = p_tournament_session_id
    and player_id = p_player_id;
  
  l_rows_updated := sql%rowcount;
  
  if l_rows_updated = 0 then
    log('No tournament player record found for session ' || p_tournament_session_id || 
        ', player ' || p_player_id, l_scope);
    raise_application_error(-20004, 'Tournament player record not found');
  elsif l_rows_updated = 1 then
    log('Successfully updated verification status: flag=' || p_verified_flag || 
        ', by=' || p_verified_by, l_scope);
  else
    log('Warning: Updated ' || l_rows_updated || ' records (expected 1)', l_scope);
  end if;
  
  log('END', l_scope);
  
exception
  when others then
    log('Error updating verification status: ' || sqlerrm, l_scope);
    raise;
end update_verification_status;







/**
 * Single player verification procedure
 * Verifies a specific player's scorecard against card structure data
 * Called when a player submits their scores and they get inserted into wmg_rounds
 *
 * @param p_tournament_session_id Tournament session ID
 * @param p_player_id Specific player ID to verify
 * @param p_room_no Room the player played in
 * @param x_verification_results Output collection of verification results
 */
procedure verify_player(
     p_tournament_session_id in wmg_tournament_players.tournament_session_id%type
  ,  p_player_id             in wmg_tournament_players.player_id%type
  ,  p_room_no               in wmg_tournament_players.room_no%type default null
  ,  p_room_name             in varchar2 default null
  ,  x_verification_result   in out verification_result_rec
)
is
  l_scope scope_t := gc_scope_prefix || 'verify_player';

  l_result verification_result_rec;
  l_compare_result verification_result_rec;
  l_room   varchar2(100);
  l_player_name varchar2(100);
  l_card_run_id wmg_card_runs.id%type;
  l_card_player_id wmg_card_players.id%type;
  l_card_course varchar2(10);
  l_card_player_name varchar2(60);
begin
  log('BEGIN - verifying player ' || p_player_id || ' for session ' || p_tournament_session_id, l_scope);
  
  -- Assume success because failure will throw and exception
  l_result.player_id := p_player_id;
  l_result.verification_status := 'SUCCESS';
  l_result.mismatch_details := null;

  -- Set Room Name
  if env.wmgt then
    if p_room_no is not null then
      l_room := 'WMGT' || p_room_no;
    else
      l_room := p_room_name;
    end if;
  else
    if env.fhit then
    l_room := 'FHIT' || p_room_no;
    else
    l_room := p_room_no;
    end if;
  end if;

  l_result.room_no := l_room;
  
  -- Get player information from tournament
  begin
    select p.player_name
    into l_player_name
    from wmg_tournament_players tp
    join wmg_players_v p on p.id = tp.player_id
    where tp.tournament_session_id = p_tournament_session_id
      and tp.player_id = p_player_id
      and tp.active_ind = 'Y';
      
    log('.. Player found: ' || l_player_name || ' in room ' || l_room, l_scope);
    
  exception
    when no_data_found then
      log('Player ' || p_player_id || ' not found in tournament session ' || p_tournament_session_id, l_scope);
      
      l_result.tournament_session_id := p_tournament_session_id;
      l_result.player_id := p_player_id;
      l_result.verification_status := 'NO_MATCH';
      l_result.mismatch_details := 'Player not registered for tournament session';

      goto end_verify_player;
  end;
  
  log('.. Verify each course', l_scope);
  log('========================================', l_scope);
  for c in (
    select tc.course_id
         , c.name course_name
    from wmg_tournament_courses tc
    join wmg_courses c on c.id = tc.course_id
    where tc.tournament_session_id = p_tournament_session_id
  )
  loop
    log('.. ' || c.course_name, l_scope);
    log('========================================', l_scope);

    update wmg_rounds r
       set r.verification_status = 'NO_MATCH'
     where r.players_id = p_player_id
       and r.course_id = c.course_id
       and r.tournament_session_id = p_tournament_session_id
       and r.verification_status is null;

    -- Look for card runs that contain this player
      select cr.id
           , cp.id
      into l_card_run_id
         , l_card_player_id
      from wmg_card_runs cr
      join wmg_card_players cp on cp.run_id = cr.id
      where cr.channel_id = '1235326643401134122'
        and cr.room = l_room
        and (cp.player_id = p_player_id 
         or (cp.player_id is null and wmg_verification_engine.match_player(cp.player) = p_player_id)
        )
        and wmg_leaderboard_util.get_course(cr.course) = c.course_id
        fetch first row only; -- just in case

      log('.. Found matching card run ' || l_card_run_id || ' for player ' || l_player_name, l_scope);

      -- Assign the player_id to the card_player record for future reference
      update wmg_card_players
         set player_id = p_player_id
       where id = l_card_player_id;

      -- Now perform the actual score comparison
      l_compare_result := compare_player_scores(
          p_tournament_session_id => p_tournament_session_id
        , p_course_id => c.course_id
        , p_player_id => p_player_id
        , p_card_run_id => l_card_run_id
        , p_card_player_id => l_card_player_id
      );

      update wmg_card_players
         set verification_status = l_compare_result.verification_status
           , mismatch_details = l_compare_result.mismatch_details
           , pending_flag = null
       where id = l_card_player_id;

      update wmg_rounds r
         set r.verification_status = l_compare_result.verification_status
       where r.players_id = p_player_id
         and r.course_id = c.course_id
         and r.tournament_session_id = p_tournament_session_id;

  end loop;

  /* Did both cards pass verification? */
  for v in (
    select sum(decode(verification_status, 'SUCCESS', 1, 0)) success_count
        , count(*) total_count
        , listagg(cp.mismatch_details, ' | ') within group (order by cp.id) as mismatch_details
      from wmg_card_runs cr
      join wmg_card_players cp on cp.run_id = cr.id
      where cp.player_id = p_player_id
        and cr.room = l_room
  )
  loop
    if v.total_count = 0 then
      l_compare_result.verification_status := 'NO_MATCH';
    elsif v.success_count = v.total_count and v.total_count = 2 then
      l_compare_result.verification_status := 'SUCCESS';
    else
      l_compare_result.verification_status := 'FAILED';
      l_compare_result.mismatch_details := substr(v.mismatch_details, 1, 4000);
    end if;
  end loop;


  l_result.tournament_session_id := p_tournament_session_id;
  l_result.room_no := l_room;
  l_result.player_id := p_player_id;
  l_result.card_run_id := l_card_run_id;
  l_result.verification_status := l_compare_result.verification_status;
  l_result.mismatch_details := l_compare_result.mismatch_details;

  if l_result.verification_status = 'SUCCESS' then
    log('.. Player verification SUCCESSFUL for ' || l_player_name, l_scope);

    -- Card is ready for purging if no other players are pending
    update wmg_card_runs r
        set r.purge_ready_flag = 'Y'
     where r.id = l_card_run_id
       and not exists (
         select 1
           from wmg_card_players p
          where p.run_id = r.id
            and p.pending_flag = 'Y'
       );

  else
    log('.. Player verification FAILED for ' || l_player_name || ': ' || l_result.mismatch_details, l_scope);
  end if;

  <<end_verify_player>>
  x_verification_result := l_result;

  log('END', l_scope);
  
exception
  when others then
    logger.log_error('Error verifying player: ' || l_player_name, l_scope);
    
    l_result.tournament_session_id := p_tournament_session_id;
    l_result.room_no := l_room;
    l_result.player_id := p_player_id;
    l_result.card_run_id := l_card_run_id;
    l_result.verification_status := 'FAILED';
    l_result.mismatch_details := 'Error during verification: ' || sqlerrm;
    x_verification_result := l_result;    

end verify_player;


/**
 * Verify a complete room by room_no
 * Verifies all active player's scorecards for a given room.
 * 
 *
 * @param p_tournament_session_id Tournament session ID
 * @param p_room_no Room the player played in
 */
procedure verify_room(
     p_tournament_session_id in wmg_tournament_players.tournament_session_id%type
  ,  p_room_no               in wmg_tournament_players.room_no%type
)
is
  l_scope scope_t := gc_scope_prefix || 'verify_room';

  l_result verification_result_rec;
--  l_room   varchar2(100);
begin

  for p in (
    select id tournament_player_id
         , player_id
         , count(*) over () as total_players
         , row_number() over (partition by tournament_session_id order by player_id) as player_num
      from wmg_tournament_players
     where tournament_session_id = p_tournament_session_id
       and room_no = p_room_no
       and active_ind = 'Y'            -- only registered players
       and verified_score_flag is null -- only unverified players
     order by player_id
  )
  loop
    -- Assume success because failure will throw and exception
    l_result.player_id := p.player_id;
    l_result.verification_status := 'SUCCESS';
    l_result.mismatch_details := null;

    verify_player(
        p_tournament_session_id => p_tournament_session_id
      , p_player_id             => p.player_id
      , p_room_no               => p_room_no
      , x_verification_result   => l_result
    );


/*
    logger.log('.. l_result.tournament_session_id:' || l_result.tournament_session_id);
    logger.log('.. l_result.room_no:' || l_result.room_no);
    logger.log('.. l_result.player_id:' || l_result.player_id);
    logger.log('.. l_result.card_run_id:' || l_result.card_run_id);
    logger.log('.. l_result.verification_status:' || l_result.verification_status);
    logger.log('.. l_result.mismatch_details:' || l_result.mismatch_details);
*/

    if l_result.verification_status = 'SUCCESS' then
        wmg_verification_engine.update_verification_status(
            p_tournament_session_id => p_tournament_session_id
          , p_player_id             => p.player_id
          , p_verified_flag         => 'Y'
        );

       if p.player_num = p.total_players  then
          logger.log('.. Verifying if room ' || p_room_no || ' is complete');
          wmg_util.verify_players_room(p_tournament_player_id => p.tournament_player_id);
       end if;
       commit; -- take it,before something else happens
    end if;

  end loop;

exception
  when others then
    logger.log_error('Unexpected error during room verification'); 

end verify_room;


end wmg_verification_engine;
/
-- =====================================================
-- Tournament Control Data Population Script
-- =====================================================
-- This script populates the wmg_tournament_control table with initial data
-- Requirements: 5.4, 5.5

-- Clear any existing data (for re-running the script)
delete from wmg_tournament_control;

-- Insert base WMGT record with NULL tournament_session_id to represent current tournament break state
-- This satisfies the requirement to support tournament breaks
insert into wmg_tournament_control (
    tournament_type_code,
    tournament_session_id
) values (
    'WMGT',
    NULL  -- NULL indicates tournament break state
);

-- Populate other tournament types based on current active sessions
-- This looks for tournaments with current_flag = 'Y' and active_ind = 'Y'
-- and finds their current active session (not completed and within date range)
insert into wmg_tournament_control (
    tournament_type_code,
    tournament_session_id
)
select t.code as tournament_type_code,
       (select ts.id 
        from wmg_tournament_sessions ts 
        where ts.tournament_id = t.id 
          and ts.completed_ind = 'N'
          and ts.session_date >= trunc(current_timestamp) - 7  -- within last week or future
        order by ts.session_date
        fetch first 1 rows only) as tournament_session_id
  from wmg_tournaments t
 where t.current_flag = 'Y'
   and t.active_ind = 'Y'
   and t.code != 'WMGT'  -- WMGT already inserted above
   and exists (
       select 1 
       from wmg_tournament_sessions ts 
       where ts.tournament_id = t.id 
         and ts.completed_ind = 'N'
         and ts.session_date >= trunc(current_timestamp) - 7
   );

-- Insert tournament types that exist but don't have active sessions (tournament break state)
-- This ensures all known tournament types are represented in the control table
insert into wmg_tournament_control (
    tournament_type_code,
    tournament_session_id
)
select t.code as tournament_type_code,
       NULL as tournament_session_id  -- NULL indicates tournament break state
  from wmg_tournaments t
 where t.active_ind = 'Y'
   and t.code not in (
       select tc.tournament_type_code 
       from wmg_tournament_control tc
   );

-- Commit the changes
commit;

-- =====================================================
-- Data Verification Queries
-- =====================================================

-- Verify all records were inserted correctly
select 'Tournament Control Records' as verification_type,
       count(*) as record_count
  from wmg_tournament_control;

-- Show all tournament control records with details
select tc.tournament_type_code,
       tc.tournament_session_id,
       case 
         when tc.tournament_session_id is null then 'TOURNAMENT BREAK'
         else 'ACTIVE SESSION'
       end as status,
       ts.week,
       ts.session_date,
       ts.completed_ind,
       t.name as tournament_name
  from wmg_tournament_control tc
  left join wmg_tournament_sessions ts on tc.tournament_session_id = ts.id
  left join wmg_tournaments t on ts.tournament_id = t.id
 order by tc.tournament_type_code;

-- Verify foreign key relationships
select 'Foreign Key Validation' as verification_type,
       case 
         when count(*) = 0 then 'PASS - All foreign keys valid'
         else 'FAIL - ' || count(*) || ' invalid foreign key references'
       end as result
  from wmg_tournament_control tc
 where tc.tournament_session_id is not null
   and not exists (
       select 1 
       from wmg_tournament_sessions ts 
       where ts.id = tc.tournament_session_id
   );

-- Show tournament types that have active tournaments vs those in break
select case 
         when tournament_session_id is null then 'TOURNAMENT BREAK'
         else 'ACTIVE TOURNAMENT'
       end as tournament_status,
       count(*) as count
  from wmg_tournament_control
 group by case 
            when tournament_session_id is null then 'TOURNAMENT BREAK'
            else 'ACTIVE TOURNAMENT'
          end
 order by tournament_status;
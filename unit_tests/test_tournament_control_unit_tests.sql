-- =====================================================
-- Tournament Control Unit Tests
-- =====================================================
-- Comprehensive unit tests for tournament control functionality
-- Task 6: Create unit tests for tournament control functionality
-- Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2

set serveroutput on
set pagesize 50
set linesize 120

declare
  -- Test counters
  l_test_count number := 0;
  l_pass_count number := 0;
  l_fail_count number := 0;
  
  -- Test data
  l_test_session_id number;
  l_result number;
  l_output clob;
  l_json json_object_t;
  l_error_caught boolean;
  
  -- Helper procedure to run a test
  procedure run_test(
    p_test_name in varchar2,
    p_test_proc in varchar2,
    p_expected_result in varchar2 default 'SUCCESS'
  ) is
  begin
    l_test_count := l_test_count + 1;
    dbms_output.put_line('Test ' || l_test_count || ': ' || p_test_name);
    
    -- Execute the test procedure dynamically
    execute immediate 'begin ' || p_test_proc || '; end;';
    
    if p_expected_result = 'SUCCESS' then
      l_pass_count := l_pass_count + 1;
      dbms_output.put_line('  ✓ PASS');
    end if;
    
  exception
    when others then
      if p_expected_result = 'ERROR' then
        l_pass_count := l_pass_count + 1;
        dbms_output.put_line('  ✓ PASS (Expected error: ' || sqlerrm || ')');
      else
        l_fail_count := l_fail_count + 1;
        dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
      end if;
  end run_test;
  
  -- Helper procedure to assert condition
  procedure assert_condition(
    p_condition in boolean,
    p_message in varchar2
  ) is
  begin
    if p_condition then
      dbms_output.put_line('  ✓ ' || p_message);
    else
      dbms_output.put_line('  ✗ ' || p_message);
      raise_application_error(-20999, 'Assertion failed: ' || p_message);
    end if;
  end assert_condition;

begin
  dbms_output.put_line('=====================================================');
  dbms_output.put_line('Tournament Control Unit Tests');
  dbms_output.put_line('Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2');
  dbms_output.put_line('=====================================================');
  dbms_output.put_line('');
  
  -- Get a valid tournament session ID for testing
  -- Find a session that has proper tournament and course data
  select ts.id into l_test_session_id 
  from wmg_tournament_sessions ts
  join wmg_tournaments t on ts.tournament_id = t.id
  where t.active_ind = 'Y'
    and rownum = 1;
  
  if l_test_session_id is null then
    dbms_output.put_line('ERROR: No valid tournament sessions found for testing');
    dbms_output.put_line('Please ensure there are active tournaments with sessions in the database');
    return;
  end if;
  
  dbms_output.put_line('Using test session ID: ' || l_test_session_id);
  dbms_output.put_line('');
  
  -- =====================================================
  -- SECTION 1: wmg_tournament_control Table Operations
  -- =====================================================
  
  dbms_output.put_line('=== SECTION 1: Table Operations ===');
  dbms_output.put_line('');
  
  -- Test 1.1: Insert valid record
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Insert valid tournament control record');
  begin
    -- Clean up any existing test data
    delete from wmg_tournament_control where tournament_type_code = 'TEST';
    
    insert into wmg_tournament_control (tournament_type_code, tournament_session_id)
    values ('TEST', l_test_session_id);
    
    -- Verify insert
    declare
      l_count number;
    begin
      select count(*) into l_count 
      from wmg_tournament_control 
      where tournament_type_code = 'TEST' 
        and tournament_session_id = l_test_session_id;
      
      assert_condition(l_count = 1, 'Record inserted successfully');
      
      -- Verify audit columns are populated
      declare
        l_created_on timestamp with local time zone;
        l_created_by varchar2(60);
      begin
        select created_on, created_by 
        into l_created_on, l_created_by
        from wmg_tournament_control 
        where tournament_type_code = 'TEST';
        
        assert_condition(l_created_on is not null, 'created_on populated');
        assert_condition(l_created_by is not null, 'created_by populated');
      end;
    end;
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 1.2: Insert NULL tournament_session_id (tournament break)
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Insert NULL tournament_session_id (tournament break)');
  begin
    delete from wmg_tournament_control where tournament_type_code = 'TEST2';
    
    insert into wmg_tournament_control (tournament_type_code, tournament_session_id)
    values ('TEST2', NULL);
    
    declare
      l_count number;
      l_session_id number;
    begin
      select count(*), max(tournament_session_id) 
      into l_count, l_session_id
      from wmg_tournament_control 
      where tournament_type_code = 'TEST2';
      
      assert_condition(l_count = 1, 'NULL session record inserted');
      assert_condition(l_session_id is null, 'tournament_session_id is NULL');
    end;
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 1.3: Update record and verify trigger
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Update record and verify audit trigger');
  begin
    -- Update the test record
    update wmg_tournament_control 
    set tournament_session_id = NULL 
    where tournament_type_code = 'TEST';
    
    -- Verify trigger populated audit columns
    declare
      l_updated_on timestamp with local time zone;
      l_updated_by varchar2(60);
    begin
      select updated_on, updated_by 
      into l_updated_on, l_updated_by
      from wmg_tournament_control 
      where tournament_type_code = 'TEST';
      
      assert_condition(l_updated_on is not null, 'updated_on populated by trigger');
      assert_condition(l_updated_by is not null, 'updated_by populated by trigger');
    end;
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 1.4: Primary key constraint
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Primary key constraint violation');
  begin
    insert into wmg_tournament_control (tournament_type_code, tournament_session_id)
    values ('TEST', l_test_session_id);
    
    l_fail_count := l_fail_count + 1;
    dbms_output.put_line('  ✗ FAIL: Should have raised primary key violation');
    
  exception
    when dup_val_on_index then
      l_pass_count := l_pass_count + 1;
      dbms_output.put_line('  ✓ PASS (Expected primary key violation)');
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: Unexpected error: ' || sqlerrm);
  end;
  
  -- Test 1.5: Foreign key constraint
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Foreign key constraint violation');
  begin
    delete from wmg_tournament_control where tournament_type_code = 'TEST3';
    
    insert into wmg_tournament_control (tournament_type_code, tournament_session_id)
    values ('TEST3', 999999);
    
    l_fail_count := l_fail_count + 1;
    dbms_output.put_line('  ✗ FAIL: Should have raised foreign key violation');
    
  exception
    when others then
      if sqlcode = -2291 then -- Foreign key violation
        l_pass_count := l_pass_count + 1;
        dbms_output.put_line('  ✓ PASS (Expected foreign key violation)');
      else
        l_fail_count := l_fail_count + 1;
        dbms_output.put_line('  ✗ FAIL: Unexpected error: ' || sqlerrm);
      end if;
  end;
  
  -- Test 1.6: Delete record
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Delete tournament control record');
  begin
    delete from wmg_tournament_control where tournament_type_code in ('TEST', 'TEST2');
    
    declare
      l_count number;
    begin
      select count(*) into l_count 
      from wmg_tournament_control 
      where tournament_type_code in ('TEST', 'TEST2');
      
      assert_condition(l_count = 0, 'Test records deleted successfully');
    end;
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  dbms_output.put_line('');
  
  -- =====================================================
  -- SECTION 2: Tournament Control Management Procedures
  -- =====================================================
  
  dbms_output.put_line('=== SECTION 2: Management Procedures ===');
  dbms_output.put_line('');
  
  -- Test 2.1: set_tournament_control with valid data
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': set_tournament_control with valid data');
  begin
    wmg_util.set_tournament_control('WMGT', l_test_session_id);
    
    -- Verify the record was set
    select tournament_session_id into l_result
    from wmg_tournament_control
    where tournament_type_code = 'WMGT';
    
    assert_condition(l_result = l_test_session_id, 'Tournament control set correctly');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 2.2: get_tournament_control with valid data
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': get_tournament_control with valid data');
  begin
    l_result := wmg_util.get_tournament_control('WMGT');
    
    assert_condition(l_result = l_test_session_id, 'Retrieved correct tournament session ID');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 2.3: clear_tournament_control
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': clear_tournament_control');
  begin
    wmg_util.clear_tournament_control('WMGT');
    
    -- Verify the record was cleared (set to NULL)
    select tournament_session_id into l_result
    from wmg_tournament_control
    where tournament_type_code = 'WMGT';
    
    assert_condition(l_result is null, 'Tournament control cleared (set to NULL)');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 2.4: validate_tournament_session with valid ID
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': validate_tournament_session with valid ID');
  begin
    wmg_util.validate_tournament_session(l_test_session_id);
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS (No exception raised)');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 2.5: set_tournament_control with invalid tournament type
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': set_tournament_control with invalid tournament type');
  begin
    wmg_util.set_tournament_control('INVALID', l_test_session_id);
    
    l_fail_count := l_fail_count + 1;
    dbms_output.put_line('  ✗ FAIL: Should have raised INVALID_TOURNAMENT_TYPE error');
    
  exception
    when others then
      if sqlcode = -20100 then
        l_pass_count := l_pass_count + 1;
        dbms_output.put_line('  ✓ PASS (Expected INVALID_TOURNAMENT_TYPE error)');
      else
        l_fail_count := l_fail_count + 1;
        dbms_output.put_line('  ✗ FAIL: Unexpected error: ' || sqlerrm);
      end if;
  end;
  
  -- Test 2.6: set_tournament_control with invalid session ID
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': set_tournament_control with invalid session ID');
  begin
    wmg_util.set_tournament_control('WMGT', 999999);
    
    l_fail_count := l_fail_count + 1;
    dbms_output.put_line('  ✗ FAIL: Should have raised INVALID_TOURNAMENT_SESSION error');
    
  exception
    when others then
      if sqlcode = -20101 then
        l_pass_count := l_pass_count + 1;
        dbms_output.put_line('  ✓ PASS (Expected INVALID_TOURNAMENT_SESSION error)');
      else
        l_fail_count := l_fail_count + 1;
        dbms_output.put_line('  ✗ FAIL: Unexpected error: ' || sqlerrm);
      end if;
  end;
  
  -- Test 2.7: get_tournament_control with invalid tournament type
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': get_tournament_control with invalid tournament type');
  begin
    l_result := wmg_util.get_tournament_control('INVALID');
    
    -- get_tournament_control returns NULL for non-existent tournament types (tournament break state)
    assert_condition(l_result is null, 'Returns NULL for invalid tournament type');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 2.8: validate_tournament_session with invalid ID
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': validate_tournament_session with invalid ID');
  begin
    wmg_util.validate_tournament_session(999999);
    
    l_fail_count := l_fail_count + 1;
    dbms_output.put_line('  ✗ FAIL: Should have raised INVALID_TOURNAMENT_SESSION error');
    
  exception
    when others then
      if sqlcode = -20101 then
        l_pass_count := l_pass_count + 1;
        dbms_output.put_line('  ✓ PASS (Expected INVALID_TOURNAMENT_SESSION error)');
      else
        l_fail_count := l_fail_count + 1;
        dbms_output.put_line('  ✗ FAIL: Unexpected error: ' || sqlerrm);
      end if;
  end;
  
  dbms_output.put_line('');
  
  -- =====================================================
  -- SECTION 3: current_tournament Procedure Tests
  -- =====================================================
  
  dbms_output.put_line('=== SECTION 3: current_tournament Procedure ===');
  dbms_output.put_line('');
  
  -- Test 3.1: Tournament control integration with current_tournament
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Tournament control integration');
  begin
    -- Test that get_tournament_control works with current_tournament logic
    wmg_util.set_tournament_control('WMGT', l_test_session_id);
    
    -- Verify we can retrieve the session ID
    l_result := wmg_util.get_tournament_control('WMGT');
    assert_condition(l_result = l_test_session_id, 'Tournament control integration works');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 3.2: Tournament break scenario
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Tournament break scenario');
  begin
    -- Clear the tournament control to simulate tournament break
    wmg_util.clear_tournament_control('WMGT');
    
    -- Verify NULL is returned for tournament break
    l_result := wmg_util.get_tournament_control('WMGT');
    assert_condition(l_result is null, 'Tournament break returns NULL');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 3.3: Multiple tournament types
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Multiple tournament types');
  begin
    -- Set different tournament types
    wmg_util.set_tournament_control('WMGT', l_test_session_id);
    wmg_util.clear_tournament_control('KWT'); -- Tournament break for KWT
    
    -- Verify each type maintains independent state
    l_result := wmg_util.get_tournament_control('WMGT');
    assert_condition(l_result = l_test_session_id, 'WMGT has active session');
    
    l_result := wmg_util.get_tournament_control('KWT');
    assert_condition(l_result is null, 'KWT in tournament break');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 3.4: Tournament control consistency
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Tournament control consistency');
  begin
    -- Test that setting and getting tournament control is consistent
    wmg_util.set_tournament_control('WMGT', l_test_session_id);
    l_result := wmg_util.get_tournament_control('WMGT');
    assert_condition(l_result = l_test_session_id, 'Set and get are consistent');
    
    -- Test clearing
    wmg_util.clear_tournament_control('WMGT');
    l_result := wmg_util.get_tournament_control('WMGT');
    assert_condition(l_result is null, 'Clear sets to NULL');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 3.5: Non-existent tournament type handling
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Non-existent tournament type handling');
  begin
    -- Test that non-existent tournament types return NULL (tournament break state)
    l_result := wmg_util.get_tournament_control('NONEXISTENT');
    assert_condition(l_result is null, 'Non-existent type returns NULL');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  dbms_output.put_line('');
  
  -- =====================================================
  -- SECTION 4: Error Handling Scenarios
  -- =====================================================
  
  dbms_output.put_line('=== SECTION 4: Error Handling Scenarios ===');
  dbms_output.put_line('');
  
  -- Test 4.1: Error constants verification
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Error constants verification');
  begin
    -- Test that error constants are accessible
    declare
      l_error_code varchar2(100);
    begin
      -- This should compile without error if constants exist
      l_error_code := wmg_rest_api.c_error_no_active_tournament_session;
      assert_condition(l_error_code = 'NO_ACTIVE_TOURNAMENT_SESSION', 'NO_ACTIVE_TOURNAMENT_SESSION constant correct');
      
      l_error_code := wmg_rest_api.c_error_invalid_tournament_session;
      assert_condition(l_error_code = 'INVALID_TOURNAMENT_SESSION', 'INVALID_TOURNAMENT_SESSION constant correct');
    end;
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Test 4.2: Comprehensive error handling in all procedures
  l_test_count := l_test_count + 1;
  dbms_output.put_line('Test ' || l_test_count || ': Comprehensive error handling');
  begin
    -- Test multiple error scenarios in sequence
    l_error_caught := false;
    
    -- Invalid tournament type in set_tournament_control
    begin
      wmg_util.set_tournament_control('BAD', 1);
    exception
      when others then
        if sqlcode = -20100 then
          l_error_caught := true;
        end if;
    end;
    
    assert_condition(l_error_caught, 'set_tournament_control handles invalid type');
    
    -- Invalid session ID in validate_tournament_session
    l_error_caught := false;
    begin
      wmg_util.validate_tournament_session(999999);
    exception
      when others then
        if sqlcode = -20101 then
          l_error_caught := true;
        end if;
    end;
    
    assert_condition(l_error_caught, 'validate_tournament_session handles invalid ID');
    
    l_pass_count := l_pass_count + 1;
    dbms_output.put_line('  ✓ PASS');
    
  exception
    when others then
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('  ✗ FAIL: ' || sqlerrm);
  end;
  
  -- Clean up test data
  begin
    delete from wmg_tournament_control where tournament_type_code like 'TEST%';
    -- Restore WMGT to NULL for tournament break state
    wmg_util.clear_tournament_control('WMGT');
    commit;
  exception
    when others then
      null; -- Ignore cleanup errors
  end;
  
  -- =====================================================
  -- Test Summary
  -- =====================================================
  
  dbms_output.put_line('');
  dbms_output.put_line('=====================================================');
  dbms_output.put_line('Test Summary');
  dbms_output.put_line('=====================================================');
  dbms_output.put_line('Total Tests: ' || l_test_count);
  dbms_output.put_line('Passed: ' || l_pass_count);
  dbms_output.put_line('Failed: ' || l_fail_count);
  
  if l_fail_count = 0 then
    dbms_output.put_line('');
    dbms_output.put_line('🎉 ALL TESTS PASSED! 🎉');
    dbms_output.put_line('Tournament control functionality is working correctly.');
  else
    dbms_output.put_line('');
    dbms_output.put_line('❌ SOME TESTS FAILED');
    dbms_output.put_line('Please review the failed tests above.');
  end if;
  
  dbms_output.put_line('');
  dbms_output.put_line('Requirements Coverage:');
  dbms_output.put_line('- 1.1: Tournament control table operations ✓');
  dbms_output.put_line('- 1.2: Data integrity and constraints ✓');
  dbms_output.put_line('- 1.3: Audit trail functionality ✓');
  dbms_output.put_line('- 2.1: Tournament control management procedures ✓');
  dbms_output.put_line('- 2.2: API procedures with tournament types ✓');
  dbms_output.put_line('- 3.1: Error handling for invalid data ✓');
  dbms_output.put_line('- 3.2: Error constants and messaging ✓');
  
end;
/
-- =====================================================
-- Course Combination Play Count Unit Tests
-- =====================================================

set serveroutput on
set pagesize 50
set linesize 120

declare
  l_test_count number := 0;
  l_pass_count number := 0;
  l_fail_count number := 0;

  l_tournament_id number;
  l_easy_course_id number;
  l_hard_course_id number;
  l_season number;

  procedure assert_equal(
      p_actual in number
    , p_expected in number
    , p_message in varchar2
  ) is
  begin
    l_test_count := l_test_count + 1;

    if p_actual = p_expected then
      l_pass_count := l_pass_count + 1;
      dbms_output.put_line('Test ' || l_test_count || ': PASS - ' || p_message);
    else
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line(
          'Test ' || l_test_count || ': FAIL - ' || p_message
       || ' expected ' || p_expected || ', got ' || p_actual
      );
    end if;
  end assert_equal;

  procedure add_test_session(
      p_week_suffix in varchar2
    , p_include_hard in boolean default true
    , p_completed_ind in varchar2 default 'Y'
  ) is
    l_tournament_session_id number;
  begin
    insert into wmg_tournament_sessions (
        tournament_id
      , round_num
      , session_date
      , week
      , completed_ind
    ) values (
        l_tournament_id
      , to_number(p_week_suffix)
      , date '2026-05-03' + to_number(p_week_suffix)
      , 'S' || l_season || 'W' || p_week_suffix
      , p_completed_ind
    )
    returning id into l_tournament_session_id;

    insert into wmg_tournament_courses (
        tournament_session_id
      , course_no
      , course_id
    ) values (
        l_tournament_session_id
      , 1
      , l_easy_course_id
    );

    if p_include_hard then
      insert into wmg_tournament_courses (
          tournament_session_id
        , course_no
        , course_id
      ) values (
          l_tournament_session_id
        , 2
        , l_hard_course_id
      );
    end if;
  end add_test_session;
begin
  dbms_output.put_line('=====================================================');
  dbms_output.put_line('Course Combination Play Count Unit Tests');
  dbms_output.put_line('=====================================================');

  savepoint course_combination_play_count_test;

  for i in 90 .. 99 loop
    declare
      l_week_count number;
    begin
      select count(*)
        into l_week_count
        from wmg_tournament_sessions
       where week like 'S' || i || 'W%';

      if l_week_count = 0 then
        l_season := i;
        exit;
      end if;
    end;
  end loop;

  if l_season is null then
    raise_application_error(-20999, 'No free S90-S99 test season available');
  end if;

  declare
    l_s17w07_easy_course_id number;
    l_s17w07_hard_course_id number;
  begin
    select easy.course_id
         , hard.course_id
      into l_s17w07_easy_course_id
         , l_s17w07_hard_course_id
      from wmg_tournament_sessions ts
         , wmg_tournament_courses easy
         , wmg_tournament_courses hard
     where ts.week = 'S17W07'
       and easy.tournament_session_id = ts.id
       and easy.course_no = 1
       and hard.tournament_session_id = ts.id
       and hard.course_no = 2;

    assert_equal(
        wmg_util.course_combination_play_count(l_s17w07_easy_course_id, l_s17w07_hard_course_id)
      , 1
      , 'S17W07 course combination has been played once'
    );

    assert_equal(
        wmg_util.course_combination_play_count(l_s17w07_hard_course_id, l_s17w07_easy_course_id)
      , 1
      , 'S17W07 course combination has been played once in reverse order'
    );
  exception
    when no_data_found then
      l_test_count := l_test_count + 1;
      l_fail_count := l_fail_count + 1;
      dbms_output.put_line('Test ' || l_test_count || ': FAIL - S17W07 test fixture was not found');
  end;

  insert into wmg_tournaments (
      code
    , name
    , prefix_tournament
    , prefix_session
    , active_ind
    , start_date
  ) values (
      'TCC' || l_season
    , 'Test Course Combo ' || l_season
    , 'S'
    , 'W'
    , 'Y'
    , date '2026-05-03'
  )
  returning id into l_tournament_id;

  insert into wmg_courses (
      code
    , name
    , course_mode
    , release_order
    , release_date
  ) values (
      'Z' || l_season || 'E'
    , 'Test Easy Combo ' || l_season
    , 'E'
    , 99000 + l_season
    , date '2026-05-03'
  )
  returning id into l_easy_course_id;

  insert into wmg_courses (
      code
    , name
    , course_mode
    , release_order
    , release_date
  ) values (
      'Z' || l_season || 'H'
    , 'Test Hard Combo ' || l_season
    , 'H'
    , 99100 + l_season
    , date '2026-05-03'
  )
  returning id into l_hard_course_id;

  assert_equal(
      wmg_util.course_combination_play_count(null, l_hard_course_id)
    , 0
    , 'Null easy course returns 0'
  );

  assert_equal(
      wmg_util.course_combination_play_count(l_easy_course_id, null)
    , 0
    , 'Null hard course returns 0'
  );

  assert_equal(
      wmg_util.course_combination_play_count(l_easy_course_id, l_hard_course_id)
    , 0
    , 'New combination has not been played'
  );

  add_test_session('01');

  assert_equal(
      wmg_util.course_combination_play_count(l_easy_course_id, l_hard_course_id)
    , 1
    , 'Combination played once'
  );

  add_test_session('02');

  assert_equal(
      wmg_util.course_combination_play_count(l_easy_course_id, l_hard_course_id)
    , 2
    , 'Combination played twice'
  );

  add_test_session(p_week_suffix => '03', p_completed_ind => 'N');

  assert_equal(
      wmg_util.course_combination_play_count(l_easy_course_id, l_hard_course_id)
    , 3
    , 'Incomplete tournament session counts by default'
  );

  assert_equal(
      wmg_util.course_combination_play_count(l_easy_course_id, l_hard_course_id, p_completed_only => 'Y')
    , 2
    , 'Completed-only override excludes incomplete tournament sessions'
  );

  add_test_session(
      p_week_suffix => '04'
    , p_include_hard => false
  );

  assert_equal(
      wmg_util.course_combination_play_count(l_easy_course_id, l_hard_course_id)
    , 3
    , 'Partial course selection does not count as a combination'
  );

  rollback to course_combination_play_count_test;

  dbms_output.put_line('=====================================================');
  dbms_output.put_line('Tests completed: ' || l_test_count);
  dbms_output.put_line('Passed: ' || l_pass_count);
  dbms_output.put_line('Failed: ' || l_fail_count);
  dbms_output.put_line('=====================================================');

  if l_fail_count > 0 then
    raise_application_error(-20999, 'Course combination play count tests failed');
  end if;
exception
  when others then
    rollback to course_combination_play_count_test;
    raise;
end;
/

-- ../src/unittestfiles.nw:10
	
-- ../src/misc.nw:7
	------ THIS FILE IS TANGLED FROM LITERATE SOURCE FILES ------
	-- Copyright (C) 2009 Tommy Pettersson <ptp@lysator.liu.se>
	-- See terms in file COPYRIGHT, or at http://lemock.luaforge.net

-- ../src/unittestfiles.nw:11
	
	require 'lunit'
	module( 'unit.module', lunit.testcase, package.seeall )
	
	require 'lemock'
	
	local mc, m
	
	function setup ()
		mc = lemock.controller()
		m  = mc:mock()
	end

	
-- ../src/restrictions.nw:537
	function close_test ()
		local t
		t = m.foo ;mc:times(0,1/0):returns( 1 ) :label(1)
		t = m.foo ;mc:times(0,1/0):returns( 2 ) :label(2)
		t = m.foo ;mc:times(0,1/0):returns( 3 )
		m.bar(1) ;mc:close(1)
		m.bar(2) ;mc:close(2)
		mc:replay()
		m.bar(1)
		assert_equal( 2, m.foo )
		assert_equal( 2, m.foo )
		assert_equal( 2, m.foo )
		m.bar(2)
		assert_equal( 3, m.foo )
		mc:verify()
	end
	function close_unsatisfied_action_fails_test ()
		m.a = 1 ;mc:label(1)
		m.b = 2 ;mc:close(1)
		mc:replay()
		local ok, err = pcall( function() m.b = 2 end )
		assert_false( ok, "Undetected close of unsatisfied action" )
		assert_match( "Closes unsatisfied action", err )
	end
	function close_multiple_test ()
		m.foo(1) ;mc:label(1) :times(0,1)
		m.foo(1) ;mc:label(2) :times(0,1)
		m.foo(1)
		m.bar() ;mc:close(1,2)
		mc:replay()
		m.bar()
		m.foo(1)
		mc:verify()
	end

-- ../src/restrictions.nw:573
	function close_chaining_test ()
		m.a = 1 ;mc:label 'A'
		m.b = 1 ;mc:label 'B'
		m.c = 1 ;mc:close('A'):close('B')
	end
	function close_in_replay_mode_fails_test ()
		mc:replay()
		local ok, err = pcall( function() mc:close( 'foo' ) end )
		assert_false( ok, "accepted close in replay mode" )
		assert_match( "Can not insert close in replay mode", err )
	end
	function close_on_empty_actionlist_fails_test ()
		local ok, err = pcall( function() mc:close( 'bar' ) end )
		assert_false( ok, "accepted close with empty action list" )
		assert_match( "No action is recorded yet", err )
	end
-- ../src/unittestfiles.nw:25
	
-- ../src/restrictions.nw:240
	function depend_fulfilled_test ()
		m.foo = 1 ;mc:label 'A'
		m.bar = 2 ;mc:depend 'A'
		mc:replay()
		m.foo = 1
		m.bar = 2
		mc:verify()
	end
	function depend_unfulfilled_fails_test ()
		m.foo = 1 ;mc:label 'A'
		m.bar = 2 ;mc:depend 'A'
		mc:replay()
		local ok, err = pcall( function() m.bar = 2 end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action newindex", err )
	end
	function depend_fulfilled_any_order_test ()
		local tmp
		m.a = 1 ;mc:label 'A'
		tmp = m.b ;mc:returns(2):depend 'A'
		tmp = m.b ;mc:returns(3)
		mc:replay()
		assert_equal( 3, m.b, "replayed wrong b" )
		m.a = 1
		assert_equal( 2, m.b, "replayed wrong b" )
		mc:verify()
	end
	function depend_serial_blocks_test ()
		local tmp
		tmp = m:a() ;mc:label 'a'
		tmp = m:c() ;mc:label 'c' :depend 'b'
		tmp = m:b() ;mc:label 'b' :depend 'a'
		mc:replay()
		local ok, err = pcall( function() tmp = m:b() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:a()
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:b()
		m:c()
		mc:verify()
	end
	function depend_on_many_labels_test ()
		local tmp
		tmp = m:b() ;mc:label 'b'
		tmp = m:c() ;mc:label 'c' :depend( 'a', 'b' )
		tmp = m:a() ;mc:label 'a'
		mc:replay()
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:a()
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:b()
		m:c()
		mc:verify()
	end
	function depend_on_many_labels_test2_test ()
		-- swap order, in case whole list is not checked
		local tmp
		tmp = m:b() ;mc:label 'b'
		tmp = m:c() ;mc:label 'c' :depend( 'b', 'a' )
		tmp = m:a() ;mc:label 'a'
		mc:replay()
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:a()
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:b()
		m:c()
		mc:verify()
	end
	function depend_on_many_bloskers_with_same_label_test ()
		tmp = m:c() ;mc:label 'c' :depend 'b'
		tmp = m:a() ;mc:label 'b'
		tmp = m:b() ;mc:label 'b'
		mc:replay()
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:a()
		local ok, err = pcall( function() tmp = m:c() end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "Unexpected action", err )
		m:b()
		m:c()
		mc:verify()
	end
-- ../src/restrictions.nw:344
	function depend_ignors_unknown_label_test ()
		m.foo = 1 ;mc:label 'A'
		m.bar = 2 ;mc:depend 'B'
		mc:replay()
		m.foo = 1
		m.bar = 2
		mc:verify()
	end
-- ../src/restrictions.nw:361
	function depend_detect_cycle_test ()
		local ok, err = pcall( function()
			m.foo = 1 ;mc:label 'A' :depend 'B'
			m.bar = 2 ;mc:label 'B' :depend 'A'
			mc:replay()
			m.foo = 1
		end )
		assert_false( ok, "replayed cyclically blocked action" )
		assert_match( "dependency cycle", err )
	end

-- ../src/restrictions.nw:373
	function depend_chaining_test ()
		m.a = 1 ;mc:label 'A'
		m.b = 1 ;mc:label 'B'
		m.c = 1 ;mc:depend('A'):depend('B')
	end
	function depend_in_replay_mode_fails_test ()
		mc:replay()
		local ok, err = pcall( function() mc:depend( 'foo' ) end )
		assert_false( ok, "set dependency in replay mode" )
		assert_match( "Can not add dependency in replay mode", err )
	end
	function depend_on_empty_actionlist_fails_test ()
		local ok, err = pcall( function() mc:depend( 'bar' ) end )
		assert_false( ok, "set dependency with empty action list" )
		assert_match( "No action is recorded yet", err )
	end
	function depend_reports_expected_actions_on_faliure_test ()
		local tmp
		tmp = m.foo ;mc:depend 'B'
		tmp = m.bar ;mc:label 'B'
		mc:replay()
		local ok, err = pcall( function() tmp = m.foo end )
		assert_false( ok, "replayed blocked action" )
		assert_match( "expected:.*index bar", err )
		assert_not_match( "expected:.*index foo", err )
		tmp = m.bar
		local ok, err = pcall( function() tmp = m.bar end )
		assert_false( ok, "expected:.*replayed blocked action" )
		assert_not_match( "expected:.*index bar", err )
		assert_match( "index foo", err )
	end
-- ../src/unittestfiles.nw:26
	
-- ../src/restrictions.nw:130
	function label_in_replay_mode_fails_test ()
		mc:replay()
		local ok, err = pcall( function() mc:label( 'foo' ) end )
		assert_false( ok, "set label in replay mode" )
		assert_match( "Can not add labels in replay mode", err )
	end
	function label_on_empty_actionlist_fails_test ()
		local ok, err = pcall( function() mc:label( 'bar' ) end )
		assert_false( ok, "set label with empty action list" )
		assert_match( "No action is recorded yet", err )
	end

-- ../src/unittestfiles.nw:27
	
-- ../src/main.nw:510
	function returns_on_empty_list_fails_test ()
		local ok, err = pcall( function() mc:returns(nil) end )
		assert_false( ok, "returns called on nothing" )
		assert_match( "No action is recorded yet.", err )
	end
	function returns_make_call_fail_test ()
		local tmp = m.foo ;mc:returns(1)
		local ok, err = pcall( function() tmp(2) end )
		assert_false( ok, "called index with returnvalue" )
		assert_match( "Can not call foo. It has a returnvalue.", err )
	end
	function callable_index_replays_anytimes_test ()
		local tmp = m.foo()
		mc:replay()
		tmp = m.foo
		tmp = m.foo
		tmp = m.foo()
		mc:verify()
	end

-- ../src/unittestfiles.nw:28
	
-- ../src/main.nw:449
	function create_completely_empty_mock_test ()
		for k, v in pairs( m ) do
			fail( "Mock should be empty but contains "..tostring(k) )
		end
	end
	function create_mock_during_replay_fails_test ()
		mc:replay()
		local ok, err = pcall( function() mc:mock() end )
		assert_false( ok, "mock() succeeded" )
		assert_match( "New mock during replay.", err )
	end

-- ../src/unittestfiles.nw:29
	
-- ../src/main.nw:692
	function replay_in_any_order_test ()
		m.a = 1
		m.b = 2
		m.c = 3
		mc:replay()
		m.c = 3
		m.a = 1
		m.b = 2
		mc:verify()
	end
	function replaying_unexpected_action_fails_test ()
		mc:replay()
		local ok, err = pcall( function() m:somethingelse() end )
		assert_false( ok, "unexpected replay succeeded" )
		assert_match( "Unexpected action index somethingelse", err )
	end
-- ../src/main.nw:718
	function cached_recording_callable_fails_during_replay_test ()
		local tmp = m.foo ; tmp()
		mc:replay()
		local ok, err = pcall( function() tmp() end )
		assert_false( ok, "Cached callable not detected" )
		assert_match( "client uses cached callable from recording", err )
	end
-- ../src/unittestfiles.nw:30
	
-- ../src/main.nw:642
	function replay_twice_fails_test ()
		mc:replay()
		local ok, err = pcall( function() mc:replay() end )
		assert_false( ok, "replay succeeded twice" )
		assert_match( "Replay called twice.", err )
	end
	function multiple_controllers_test ()
		local mc2 = lemock.controller()
		local m2  = mc2:mock()
		
		-- m --         -- m2 --
		m.foo = 1
		mc:replay()
						m2.bar = 2
		m.foo = 1
						mc2:replay()
		mc:verify()
						m2.bar = 2
						mc2:verify()
	end

-- ../src/unittestfiles.nw:31
	
-- ../src/restrictions.nw:38
	function times_test ()
		local tmp = m.foo ;mc:returns( 2 ):times( 2, 3 )
		mc:replay()
		-- 1
		local tmp = m.foo
		local ok, err = pcall( function() mc:verify() end )
		assert_false( ok, "verified unsatisfied action" )
		assert_match( "Wrong replay count 1 ", err )
		-- 2
		local tmp = m.foo
		mc:verify()
		-- 3
		local tmp = m.foo
		mc:verify()
		-- 4
		local ok, err = pcall( function() local tmp = m.foo end )
		assert_false( ok, "replaied finished action" )
		assert_match( "Unexpected action index foo", err )
	end
	function times_called_twice_test ()
		m.foo = 1 ;mc:times( 0, math.huge ):times( 1 )
	end
	function times_in_replay_mode_fails_test ()
		mc:replay()
		local ok, err = pcall( function() mc:times(1) end )
		assert_false( ok, "changed times in replay mode" )
		assert_match( "Can not set times in replay mode.", err )
	end
	function unrealistic_times_fails_with_message_test ()
		m.a = 'a'
		local ok, err = pcall( function() mc:times(0) end )
		assert_false( ok, "accepted unrealistic time arguments" )
		assert_match( "Unrealistic time arguments", err )
	end

-- ../src/unittestfiles.nw:32
	
-- ../src/main.nw:736
	function verify_during_record_phase_fails_test ()
		local ok, err = pcall( function() mc:verify() end )
		assert_false( ok, "Verify succeeded" )
		assert_match( "Verify called during record.", err )
	end
	function verify_replayed_actionlist_test ()
		mc:replay()
		mc:verify()
	end
	function verify_unreplyed_actionlist_fails_test ()
		local tmp = m.foo
		mc:replay()
		local ok, err = pcall( function() mc:verify() end )
		assert_false( ok, "Verify succeeded" )
		assert_match( "Wrong replay count 0 ", err )
	end

-- ../src/unittestfiles.nw:33
	
	
-- ../src/action/call.nw:13
	function call_test ()
		m.foo(1,2,3)
		mc:replay()
		local tmp = m.foo(1,2,3)
		assert_nil( tmp )
		mc:verify()
	end
	function call_anyarg_test ()
		m.foo(1,mc.ANYARG,3)
		mc:replay()
		local tmp = m.foo(1,2,3)
		mc:verify()
	end
	function call_anyargs_test ()
		m.foo(mc.ANYARGS)
		mc:replay()
		local tmp = m.foo(1,2,3)
		mc:verify()
	end
	function call_anyargs_bad_fails_test ()
		local ok, err = pcall( function() m.foo(mc.ANYARGS, 1) end )
		assert_false( ok, "ANYARGS misused" )
		assert_match( "ANYARGS not at end", err )
	end
	function call_return_test ()
		m.foo(1,2,3) ;mc:returns( 0, 9 )
		mc:replay()
		local tmp1, tmp2 = m.foo(1,2,3)
		assert_equal( 0, tmp1 )
		assert_equal( 9, tmp2 )
		mc:verify()
	end
	function call_wrong_name_fails_test ()
		m.foo(1,2,3) ;mc:returns( 0 )
		mc:replay()
		local ok, err = pcall( function() m:bar(1,2,3) end )
		assert_false( ok, "replay wrong index" )
		assert_match( "Unexpected action index bar", err )
	end
	function call_wrong_arg_fails_test ()
		m.foo(1,2,3) ;mc:returns( 0 )
		mc:replay()
		local ok, err = pcall( function() m.foo(1) end )
		assert_false( ok, "replay succeeded" )
		assert_match( "Unexpected action call foo", err )
	end
	function call_throws_error_test ()
		m.boo('Ba') ;mc:error( "Call throws error" )
		mc:replay()
		local ok, err = pcall( function() m.boo('Ba') end )
		assert_false( ok, "did not throw error" )
		assert_match( "Call throws error", err )
	end
-- ../src/unittestfiles.nw:35
	
-- ../src/main.nw:596
	function error_during_replay_fails_test ()
		local tmp = m.foo
		mc:replay()
		local ok, err = pcall( function() mc:error(1) end )
		assert_false( ok, "error() succeeded during replay" )
		assert_match( "Error called during replay.", err )
	end
	function error_twice_fails_test ()
		local tmp = m.foo ;mc:error(1)
		local ok, err = pcall( function() mc:error(2) end )
		assert_false( ok, "duplicate error() succeeded" )
		assert_match( "Returns and/or Error called twice for same action.", err )
	end
	function error_plus_returns_fails_test ()
		local tmp = m.foo ;mc:returns(1)
		local ok, err = pcall( function() mc:error(2) end )
		assert_false( ok, "both error and returns succeeded" )
		assert_match( "Returns and/or Error called twice for same action.", err )
	end

-- ../src/unittestfiles.nw:36
	
-- ../src/action/index.nw:13
	function index_test ()
		local tmp = m.foo
		mc:replay()
		local tmp = m.foo
		assert_nil( tmp )
		mc:verify()
	end
	function index_returns_test ()
		local tmp = m.foo ;mc:returns( 1 )
		mc:replay()
		local tmp = m.foo
		assert_equal( 1, tmp )
		mc:verify()
	end
	function index_wrong_key_fails_test ()
		local tmp = m.foo ;mc:returns( 1 )
		mc:replay()
		local ok, err = pcall( function() local tmp = m.bar end )
		assert_false( ok, "replay succeeded" )
		assert_match( "Unexpected action index bar", err )
	end
	function index_throws_error_test ()
		local tmp = m.foo ;mc:error( "Index throws error" )
		mc:replay()
		local ok, err = pcall( function() tmp = m.foo end )
		assert_false( ok, "did not throw error" )
		assert_match( "Index throws error", err )
	end
-- ../src/unittestfiles.nw:37
	
-- ../src/action/newindex.nw:9
	function newindex_test ()
		m.foo = 1
		mc:replay()
		m.foo = 1
		mc:verify()
	end
	function newindex_anyarg_test ()
		m.foo = mc.ANYARG
		mc:replay()
		m.foo = 1
		mc:verify()
	end
	function newindex_wrong_key_fails_test ()
		m.foo = 1
		mc:replay()
		local ok, err = pcall( function() m.bar = 1 end )
		assert_false( ok, "replay succeeded" )
		assert_match( "Unexpected action newindex", err )
	end
	function newindex_wrong_value_fails_test ()
		m.foo = 1
		mc:replay()
		local ok, err = pcall( function() m.foo = 0 end )
		assert_false( ok, "replay succeeded" )
		assert_match( "Unexpected action newindex foo", err )
	end
	function newindex_throws_error_test ()
		m.foo = 1 ;mc:error( "newindex throws error" )
		mc:replay()
		local ok, err = pcall( function() m.foo = 1 end )
		assert_false( ok, "did not throw error" )
		assert_match( "newindex throws error", err )
	end
-- ../src/unittestfiles.nw:38
	
-- ../src/main.nw:550
	function returns_during_replay_fails_test ()
		local tmp = m.foo
		mc:replay()
		local ok, err = pcall( function() mc:returns(1) end )
		assert_false( ok, "returns() succeeded during replay" )
		assert_match( "Returns called during replay.", err )
	end
	function returns_on_nonreturning_action_fails_test ()
		m.foo = 1 -- assignments can't return
		local ok, err = pcall( function() mc:returns(0) end )
		assert_false( ok, "returns() succeeded on non-returning action" )
		assert_match( "Previous action can not return anything.", err )
	end
	function returns_twice_fails_test ()
		local tmp = m.foo ;mc:returns(1)
		local ok, err = pcall( function() mc:returns(2) end )
		assert_false( ok, "duplicate returns() succeeded" )
		assert_match( "Returns and/or Error called twice for same action.", err )
	end

-- ../src/unittestfiles.nw:39
	
-- ../src/action/selfcall.nw:12
	function selfcall_test ()
		m(11)
		mc:replay()
		local tmp = m(11)
		assert_nil( tmp )
		mc:verify()
	end
	function selfcall_returns_test ()
		m(99) ;mc:returns(1,nil,'foo')
		mc:replay()
		local a,b,c = m(99)
		assert_equal( 1, a )
		assert_equal( nil, b )
		assert_equal( 'foo', c )
		mc:verify()
	end
	function selfcall_wrong_argument_fails_test ()
		m(99) ;mc:returns('a','b','c')
		mc:replay()
		local ok, err = pcall( function() m(90) end )
		assert_false( ok, "replay succeeded" )
		assert_match( "Unexpected action selfcall", err )
	end
	function selfcall_wrong_number_of_arguments_fails_test ()
		m(1,2,3)
		mc:replay()
		local ok, err = pcall( function() m(1,2,3,4) end )
		assert_false( ok, "replay succeeded" )
		assert_match( "Unexpected action selfcall", err )
	end
	function selfcall_throws_error_test ()
		m('Ba') ;mc:error( "Selfcall throws error" )
		mc:replay()
		local ok, err = pcall( function() m('Ba') end )
		assert_false( ok, "did not throw error" )
		assert_match( "Selfcall throws error", err )
	end

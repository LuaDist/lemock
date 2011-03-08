-- ../src/unittestfiles.nw:46
	
-- ../src/misc.nw:7
	------ THIS FILE IS TANGLED FROM LITERATE SOURCE FILES ------
	-- Copyright (C) 2009 Tommy Pettersson <ptp@lysator.liu.se>
	-- See terms in file COPYRIGHT, or at http://lemock.luaforge.net

-- ../src/unittestfiles.nw:47
	
	require 'lunit'
	module( 'unit.controller', lunit.testcase, package.seeall )
	
	local class, object, qtostring, sfmt, add_to_set, elements_of_set
	
-- ../src/helperfunctions.nw:12
	function object (class)
		return setmetatable( {}, class )
	end
	function class (parent)
		local c = object(parent)
		c.__index = c
		return c
	end
-- ../src/unittestfiles.nw:53
	
-- ../src/tostring.nw:23
	sfmt = string.format
	function qtostring (v)
		if type(v) == 'string' then
			return sfmt( '%q', v )
		else
			return tostring( v )
		end
	end
-- ../src/unittestfiles.nw:54
	
-- ../src/helperfunctions.nw:47
	function add_to_set (o, setname, element)
		if not o[setname] then
			o[setname] = {}
		end
		local l = o[setname]
		
		for i = 1, #l do
			if l[i] == element then return end
		end
		l[#l+1] = element
	end
	function elements_of_set (o, setname)
		local l = o[setname]
		local i = l and #l+1 or 0
		return function ()
			i = i - 1
			if i > 0 then return l[i] end
		end
	end
-- ../src/unittestfiles.nw:55
	
	
-- ../src/main.nw:373
	local mock_controller_map = setmetatable( {}, {__mode='k'} )
-- ../src/unittestfiles.nw:57
	
	local Controller, Action
	
-- ../src/class/controller.nw:6
	Controller = class()
	
	-- Exported methods
	
-- ../src/restrictions.nw:595
	function Controller:close (...)
		if not self.is_recording then
			error( "Can not insert close in replay mode.", 2 )
		end
		local action = self:get_last_action()
		for _, close in ipairs{ ... } do
			action:add_close( close )
		end
		return self -- for chaining
	end

-- ../src/class/controller.nw:10
	
-- ../src/restrictions.nw:410
	function Controller:depend (...)
		if not self.is_recording then
			error( "Can not add dependency in replay mode.", 2 )
		end
		local action = self:get_last_action()
		for _, dependency in ipairs{ ... } do
			action:add_depend( dependency )
		end
		return self -- for chaining
	end

-- ../src/class/controller.nw:11
	
-- ../src/main.nw:617
	function Controller:error (value)
		if not self.is_recording then
			error( "Error called during replay.", 2 )
		end
		local action = self:get_last_action()
		if action.has_returnvalue or action.throws_error then
			error( "Returns and/or Error called twice for same action.", 2 )
		end
		action.throws_error = true
		action.errorvalue = value
		return self -- for chaining
	end
-- ../src/class/controller.nw:12
	
-- ../src/restrictions.nw:158
	function Controller:label (...)
	if not self.is_recording then
		error( "Can not add labels in replay mode.", 2 )
	end
	local action = self:get_last_action()
	for _, label in ipairs{ ... } do
		action:add_label( label )
	end
	return self -- for chaining
	end
-- ../src/class/controller.nw:13
	
-- ../src/main.nw:462
	function Controller:mock ()
		if not self.is_recording then
			error( "New mock during replay.", 2 )
		end
		local m = object( Mock.record )
		mock_controller_map[m] = self
		return m
	end
-- ../src/class/controller.nw:14
	
-- ../src/main.nw:421
	function Controller:new ()
		local mc = object( self )
		mc.actionlist   = {}
		mc.is_recording = true
		return mc
	end
-- ../src/class/controller.nw:15
	
-- ../src/main.nw:671
	function Controller:replay ()
		if not self.is_recording then
			error( "Replay called twice.", 2 )
		end
		self.is_recording = false
		for m, mc in pairs( mock_controller_map ) do
			if mc == self then
				setmetatable( m, Mock.replay )
			end
		end
		self:update_dependencies()
		self:assert_no_dependency_cycles()
	end
-- ../src/class/controller.nw:16
	
-- ../src/main.nw:571
	function Controller:returns (...)
		if not self.is_recording then
			error( "Returns called during replay.", 2 )
		end
		local action = self:get_last_action()
		assert( not action.is_callable, "lemock internal error" )
		if not action.can_return then
			error( "Previous action can not return anything.", 2 )
		end
		if action.has_returnvalue or action.throws_error then
			error( "Returns and/or Error called twice for same action.", 2 )
		end
		action:set_returnvalue(...)
		return self -- for chaining
	end
-- ../src/class/controller.nw:17
	
-- ../src/restrictions.nw:74
	function Controller:times (min, max)
		if not self.is_recording then
			error( "Can not set times in replay mode.", 0 )
		end
		self:get_last_action():set_times( min, max )
		return self -- for chaining
	end
	-- convenience functions
	function Controller:anytimes()    return self:times( 0, math.huge ) end
	function Controller:atleastonce() return self:times( 1, math.huge ) end
-- ../src/class/controller.nw:18
	
-- ../src/main.nw:754
	function Controller:verify ()
		if self.is_recording then
			error( "Verify called during record.", 2 )
		end
		for a in self:actions() do
			a:assert_satisfied()
		end
	end
-- ../src/class/controller.nw:19
	
	-- Protected methods
	
-- ../src/main.nw:145
	function Controller:actions (q)
		local l = self.actionlist
		local i = 0
		return function ()
			i = i + 1
			return l[i]
		end				
	end
-- ../src/class/controller.nw:22
	
-- ../src/main.nw:56
	function Controller:add_action (a)
		assert( a ~= nil, "lemock internal error" ) -- breaks array property
		table.insert( self.actionlist, a )
	end
-- ../src/class/controller.nw:23
	
-- ../src/restrictions.nw:489
	function Controller:assert_no_dependency_cycles ()
		local function is_in_path (label, path)
			if not path then return false end -- is root
			for _, l in ipairs( path ) do
				if l == label then return true end
			end
			if path.prev then return is_in_path( label, path.prev ) end
			return false
		end
		local function can_block (action, node)
			for _, label in ipairs( node ) do
				if action:has_label( label ) then return true end
			end
			return false
		end
		local function step (action, path)
			local new_head
			for label in action:depends() do
				if is_in_path( label, path ) then
					error( "Detected dependency cycle", 0 )
				end
				-- only create table if needed to reduce garbage
				if not new_head then new_head = { prev=path } end
				new_head[#new_head+1] = label
			end
			return new_head
		end
		local function search_depth_first (path)
			for action in self:actions() do
				if can_block( action, path ) then
					local new_head = step( action, path )
					if new_head then
						search_depth_first( new_head )
					end
				end
			end
		end
		for action in self:actions() do
			local root = step( action, nil )
			if root then search_depth_first( root ) end
		end
	end
-- ../src/class/controller.nw:24
	
-- ../src/restrictions.nw:616
	function Controller:close_actions( ... ) -- takes iterator
		for label in ... do
			for candidate in self:actions() do
				if candidate:has_label( label ) then
					if not candidate:is_satisfied() then
						error( "Closes unsatisfied action: "..candidate:tostring(), 0 )
					end
					candidate.is_closed = true
				end
			end
		end
	end

-- ../src/class/controller.nw:25
	
-- ../src/main.nw:177
	function Controller:get_last_action ()
		local l = self.actionlist
		if #l == 0 then
			error( "No action is recorded yet.", 0 )
		end
		return l[#l]
	end
-- ../src/class/controller.nw:26
	
-- ../src/main.nw:88
	function Controller:lookup (actual)
		for action in self:actions() do
			if action:match( actual ) then
				return action
			end
		end
		
-- ../src/main.nw:111
	local expected = {}
	for _, a in ipairs( self.actionlist ) do
		if a:is_expected() and not a.is_callable then
			expected[#expected+1] = a:tostring()
		end
	end
	table.sort( expected )
	if #expected == 0 then
		expected[1] = "(Nothing)"
	end
-- ../src/main.nw:95
		error( sfmt( "Unexpected action %s, expected:\n%s\n"
		             , actual:tostring()
		             , table.concat(expected,'\n')
		       )
		       , 0
		)
	end
-- ../src/class/controller.nw:27
	
-- ../src/main.nw:531
	function Controller:make_callable (action)
		if action.has_returnvalue then
			error( "Can not call "..action.key..". It has a returnvalue.", 0 )
		end
		action.is_callable = true
		action.min_replays = 0
		action.max_replays = math.huge
	end
-- ../src/class/controller.nw:28
	
-- ../src/main.nw:421
	function Controller:new ()
		local mc = object( self )
		mc.actionlist   = {}
		mc.is_recording = true
		return mc
	end
-- ../src/class/controller.nw:29
	
-- ../src/main.nw:297
	function Controller:replay_action ( action )
		assert( action:is_expected(), "lemock internal error" )
		assert( action.replay_count < action.max_replays, "lemock internal error" )
		local was_satisfied = action:is_satisfied()
		action.replay_count = action.replay_count + 1
		if not was_satisfied and action.labellist and action:is_satisfied() then
			self:update_dependencies()
		end
		if action.closelist then
			self:close_actions( action:closes() )
		end
	end
-- ../src/class/controller.nw:30
	
-- ../src/restrictions.nw:457
	function Controller:update_dependencies ()
		local blocked = {}
		for action in self:actions() do
			for label in action:blocks() do
				blocked[label] = true
			end
		end
		local function is_blocked (action)
			for label in action:depends() do
				if blocked[label] then return true end
			end
			return false
		end
		for action in self:actions() do
			action.is_blocked = is_blocked( action )
		end
	end
-- ../src/unittestfiles.nw:60
	
-- ../src/class/action.nw:24
	Action = {}
	
	-- abstract
	
-- ../src/class/action.nw:41
	Action.generic = class()
	
	
-- ../src/restrictions.nw:607
	function Action.generic:add_close (label)
		add_to_set( self, 'closelist', label )
	end
-- ../src/class/action.nw:44
	
-- ../src/restrictions.nw:443
	function Action.generic:add_depend (d)
		add_to_set( self, 'dependlist', d )
	end

-- ../src/class/action.nw:45
	
-- ../src/restrictions.nw:207
	function Action.generic:add_label (label)
		add_to_set( self, 'labellist', label )
	end

-- ../src/class/action.nw:46
	
-- ../src/main.nw:338
	function Action.generic:assert_satisfied ()
		assert( self.replay_count <= self.max_replays, "lemock internal error" )
		if not (
-- ../src/main.nw:330
	self.min_replays <= self.replay_count

-- ../src/main.nw:340
                                  ) then
			error( sfmt( "Wrong replay count %d (expected %d..%d) for %s"
			             , self.replay_count
			             , self.min_replays, self.max_replays
			             , self:tostring()
			       )
			       , 0
			)
		end
	end
-- ../src/class/action.nw:47
	
-- ../src/restrictions.nw:220
	function Action.generic:blocks ()
		if self:is_satisfied() then
			return function () end
		end
		return elements_of_set( self, 'labellist' )
	end
-- ../src/class/action.nw:48
	
-- ../src/restrictions.nw:630
	function Action.generic:closes ()
		return elements_of_set( self, 'closelist' )
	end
-- ../src/class/action.nw:49
	
-- ../src/restrictions.nw:448
	function Action.generic:depends ()
		return elements_of_set( self, 'dependlist' )
	end
-- ../src/class/action.nw:50
	
-- ../src/restrictions.nw:212
	function Action.generic:has_label (l)
		for x in elements_of_set( self, 'labellist' ) do
			if x == l then return true end
		end
		return false
	end

-- ../src/class/action.nw:51
	
-- ../src/main.nw:247
	function Action.generic:is_expected ()
		return self.replay_count < self.max_replays
		   and not self.is_blocked
		   and not self.is_closed
	end

-- ../src/class/action.nw:52
	
-- ../src/main.nw:333
	function Action.generic:is_satisfied ()
		return 
-- ../src/main.nw:330
	self.min_replays <= self.replay_count

-- ../src/main.nw:335
	end

-- ../src/class/action.nw:53
	
-- ../src/main.nw:269
	function Action.generic:match (key)
		if getmetatable(self) ~= getmetatable(key)  then return false end
		if self.mock ~= key.mock                    then return false end
		return self:is_expected()
	end
-- ../src/class/action.nw:54
	
-- ../src/main.nw:219
	function Action.generic:new (mock)
		local a = object( self )
		a.mock         = mock
		a.replay_count = 0
		a.min_replays  = 1
		a.max_replays  = 1
		return a
	end
-- ../src/class/action.nw:55
	
-- ../src/restrictions.nw:102
	function Action.generic:set_times (a, b)
		min = a or 1
		max = b or min
		min, max = tonumber(min), tonumber(max)
		if (not min) or (not max) or (min >= math.huge)
		             or (min ~= min) or (max ~= max) -- NaN
		             or (min < 0) or (max <= 0) or (min > max) then
			error( sfmt( "Unrealistic time arguments (%s, %s)"
			           , qtostring( min )
			           , qtostring( max )
			           )
			     , 0
			     )
		end
		self.min_replays = min
		self.max_replays = max
	end


-- ../src/class/action.nw:28
	
-- ../src/class/action.nw:59
	Action.generic_call = class( Action.generic )
	
	Action.generic_call.can_return = true
	
-- ../src/action/generic_call.nw:76
	function Action.generic_call:get_returnvalue ()
		if self.has_returnvalue then
			return self.returnvalue:unpack()
		end
	end
-- ../src/class/action.nw:63
	
-- ../src/action/generic_call.nw:56
	function Action.generic_call:set_returnvalue (...)
		self.returnvalue = Argv:new(...)
		self.has_returnvalue = true
	end
-- ../src/class/action.nw:64
	
	
-- ../src/action/generic_call.nw:45
	function Action.generic_call:match (q)
		if not Action.generic.match( self, q )  then return false end
		if not self.argv:equal( q.argv )        then return false end
		return true
	end
-- ../src/class/action.nw:66
	
-- ../src/action/generic_call.nw:32
	function Action.generic_call:new (m, ...)
		local a = Action.generic.new( self, m )
		a.argv   = Argv:new(...)
		return a
	end
-- ../src/class/action.nw:29
	
	-- concrete
	
-- ../src/class/action.nw:93
	Action.call = class( Action.generic_call )
	
	
-- ../src/action/call.nw:118
	function Action.call:match (q)
		if not Action.generic_call.match( self, q )  then return false end
		if self.key ~= q.key                         then return false end
		return true
	end
-- ../src/class/action.nw:96
	
-- ../src/action/call.nw:82
	function Action.call:new (m, key, ...)
		local a = Action.generic_call.new( self, m, ... )
		a.key = key
		return a
	end
-- ../src/class/action.nw:97
	
-- ../src/tostring.nw:101
	function Action.call:tostring ()
		if self.has_returnvalue then
			return sfmt( "call %s(%s) => %s"
			             , tostring(self.key)
			             , self.argv:tostring()
			             , self.returnvalue:tostring()
			       )
		else
			return sfmt( "call %s(%s)"
			             , tostring(self.key)
			             , self.argv:tostring()
			       )
		end
	end


-- ../src/class/action.nw:32
	
-- ../src/class/action.nw:81
	Action.index = class( Action.generic )
	
	Action.index.can_return = true
	
-- ../src/action/index.nw:134
	function Action.index:get_returnvalue ()
		return self.returnvalue
	end
-- ../src/class/action.nw:85
	
-- ../src/action/index.nw:85
	function Action.index:set_returnvalue (v)
		self.returnvalue = v
		self.has_returnvalue = true
	end
-- ../src/class/action.nw:86
	
	
-- ../src/action/index.nw:123
	function Action.index:match (q)
		if not Action.generic.match( self, q )  then return false end
		if self.key ~= q.key                    then return false end
		return true
	end
-- ../src/class/action.nw:88
	
-- ../src/action/index.nw:67
	function Action.index:new (m, key)
		local a = Action.generic.new( self, m )
		a.key = key
		return a
	end
-- ../src/class/action.nw:89
	
-- ../src/tostring.nw:70
	function Action.index:tostring ()
		local key = 'index '..tostring( self.key )
		if self.has_returnvalue then
			return sfmt( "index %s => %s"
			             , tostring( self.key )
			             , qtostring( self.returnvalue )
			       )
		elseif self.is_callable then
			return sfmt( "index %s()"
			             , tostring( self.key )
			       )
		else
			return sfmt( "index %s"
			             , tostring( self.key )
			       )
		end
	end


-- ../src/class/action.nw:33
	
-- ../src/class/action.nw:73
	Action.newindex = class( Action.generic )
	
	
-- ../src/action/newindex.nw:102
	function Action.newindex:match (q)
		if not Action.generic.match( self, q )  then return false end
		if self.key ~= q.key                    then return false end
		if not value_equal( self.val, q.val )
		   and self.val ~= Argv.ANYARG
		   and q.val    ~= Argv.ANYARG          then return false end
		return true
	end
-- ../src/class/action.nw:76
	
-- ../src/action/newindex.nw:54
	function Action.newindex:new (m, key, val)
		local a = Action.generic.new( self, m )
		a.key    = key
		a.val    = val
		return a
	end
-- ../src/class/action.nw:77
	
-- ../src/tostring.nw:45
	function Action.newindex:tostring ()
		return sfmt( "newindex %s = %s"
		             , tostring(self.key)
		             , qtostring(self.val)
		       )
	end


-- ../src/class/action.nw:34
	
-- ../src/class/action.nw:101
	Action.selfcall = class( Action.generic_call )
	
	
-- ../src/action/selfcall.nw:93
	function Action.selfcall:match (q)
		return Action.generic_call.match( self, q )
	end
-- ../src/class/action.nw:104
	
-- ../src/action/selfcall.nw:61
	function Action.selfcall:new (m, ...)
		local a = Action.generic_call.new( self, m, ... )
		return a
	end
-- ../src/class/action.nw:105
	
-- ../src/tostring.nw:129
	function Action.selfcall:tostring ()
		if self.has_returnvalue then
			return sfmt( "selfcall (%s) => %s"
			             , self.argv:tostring()
			             , self.returnvalue:tostring()
			       )
		else
			return sfmt( "selfcall (%s)"
			             , self.argv:tostring()
			       )
		end
	end
-- ../src/unittestfiles.nw:61
	
	local A = Action.generic
	Action = nil -- only allow generic action
	function A:tostring () return '<dummy>' end
	
	local mc
	
	function setup ()
		mc = Controller:new()
	end
	
	
-- ../src/main.nw:125
	function actions_dont_iterate_empty_list_test ()
		for a in mc:actions() do
			fail( "iterates on empty list" )
		end
	end
	function actions_iterate_over_entire_list_exactly_once_test ()
		local l = { {},{},{} }
		for _, a in ipairs( l ) do
			mc:add_action( a )
		end
		for a in mc:actions() do
			assert_nil( a.check )
			a.check = true
		end
		for _, a in ipairs( l ) do
			assert_true( a.check )
		end
	end

-- ../src/unittestfiles.nw:73
	
-- ../src/main.nw:48
	function add_action_at_the_end_test ()
		mc:add_action( 7 )
		mc:add_action( mc )
		assert_equal( 7, mc.actionlist[1] )
		assert_equal( mc, mc.actionlist[2] )
	end

-- ../src/unittestfiles.nw:74
	
-- ../src/main.nw:162
	function get_last_action_returns_last_element_test ()
		local l = { 'a', 'foo', 17 }
		for i = 1, #l do
			mc:add_action( l[i] )
			local res = mc:get_last_action()
			assert_equal( l[i], res )
		end
	end
	function get_last_action_fails_on_empty_list_test ()
		local ok, err = pcall( function() mc:get_last_action() end )
		assert_false( ok, "Found last action in empty list" )
		assert_match( "No action is recorded yet", err )
	end

-- ../src/unittestfiles.nw:75
	
-- ../src/restrictions.nw:143
	function label_test ()
		mc:add_action( A:new() )
		mc:label( 'a', 'b' ):label( 'c', 'b' )
		local a = mc:get_last_action()
		local seen = {}
		for l in a:blocks() do
			seen[l] = true
		end
		assert_true( seen['a'] )
		assert_true( seen['b'] )
		assert_true( seen['c'] )
		assert_nil(  seen['d'] )
	end

-- ../src/unittestfiles.nw:76
	
-- ../src/main.nw:71
	function lookup_returns_first_matching_action_test ()
		local Fake_action
		
-- ../src/misc.nw:12
	Fake_action = class()
	function Fake_action:new (x)
		local a = object(Fake_action)
		a.x = x
		return a
	end
	function Fake_action:match (q)
		return self.x < q.x
	end
	function Fake_action:is_expected ()
		return true
	end
	function Fake_action:tostring ()
		return '<faked action>'
	end
	function Fake_action:blocks ()
		return function () end
	end
	Fake_action.depends = Fake_action.blocks
-- ../src/main.nw:74
		local a1 = Fake_action:new(1)
		local a2 = Fake_action:new(2)
		local a3 = Fake_action:new(1)
		local ok, err = pcall( function() mc:lookup( a1 ) end )
		assert_false( ok, "match in empty list" )
		assert_match( "Unexpected action <faked action>", err )
		mc:add_action( a1 ) mc:add_action( a2 ) mc:add_action( a3 )
		local ok, err = pcall( function() mc:lookup( a1 ) end )
		assert_false( ok, "should not match any action" )
		assert_match( "Unexpected action <faked action>", err )
		assert_equal( a1, mc:lookup( a2 ), "did not find first match" )
	end

-- ../src/unittestfiles.nw:77
	
-- ../src/main.nw:664
	function replay_test ()
		assert_true( mc.is_recording )
		mc:replay()
		assert_false( mc.is_recording )
	end

-- ../src/unittestfiles.nw:78
	
-- ../src/main.nw:285
	function replay_action_test ()
		local a = A:new()
		mc:add_action( a )
		assert_true( a:is_expected() )
		assert_false( a:is_satisfied() )
		mc:replay_action( a )
		assert_false( a:is_expected() )
		assert_true( a:is_satisfied() )
		assert_equal( 1, a.replay_count )
	end


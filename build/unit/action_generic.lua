-- ../src/unittestfiles.nw:108
	
-- ../src/misc.nw:7
	------ THIS FILE IS TANGLED FROM LITERATE SOURCE FILES ------
	-- Copyright (C) 2009 Tommy Pettersson <ptp@lysator.liu.se>
	-- See terms in file COPYRIGHT, or at http://lemock.luaforge.net

-- ../src/unittestfiles.nw:109
	
	require 'lunit'
	module( 'unit.action_generic', lunit.testcase, package.seeall )
	
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
-- ../src/unittestfiles.nw:115
	
-- ../src/tostring.nw:23
	sfmt = string.format
	function qtostring (v)
		if type(v) == 'string' then
			return sfmt( '%q', v )
		else
			return tostring( v )
		end
	end
-- ../src/unittestfiles.nw:116
	
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
-- ../src/unittestfiles.nw:117
	
	local Action, Argv
	
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
-- ../src/unittestfiles.nw:120
	
-- ../src/class/argv.nw:6
	Argv = class()
	
	
-- ../src/argv.nw:119
	Argv.ANYARGS = newproxy()  local ANYARGS = Argv.ANYARGS
	Argv.ANYARG  = newproxy()  local ANYARG  = Argv.ANYARG
	function Argv:equal (other)
		local a1, n1 = self.v,  self.len
		local a2, n2 = other.v, other.len
		if n1-1 <= n2 and a1[n1] == ANYARGS then
			n1 = n1-1
			n2 = n1
		elseif n2-1 <= n1 and a2[n2] == ANYARGS then
			n2 = n2-1
			n1 = n2
		end
		if n1 ~= n2 then
			return false
		end
		for i = 1, n1 do
			local v1, v2 = a1[i], a2[i]
			if not value_equal(v1,v2) and v1 ~= ANYARG and v2 ~= ANYARG then
				return false
			end
		end
		return true
	end
-- ../src/class/argv.nw:9
	
-- ../src/argv.nw:46
	function Argv:new (...)
		local av = object( self )
		av.v = {...}
		av.len = select('#',...)
		for i = 1, av.len - 1 do
			if av.v[i] == Argv.ANYARGS then
				error( "ANYARGS not at end.", 0 )
			end
		end
		return av
	end
-- ../src/class/argv.nw:10
	
-- ../src/tostring.nw:163
	function Argv:tostring ()
		local res = {}
		local function w (v)
			res[#res+1] = qtostring( v )
		end
		local av, ac = self.v, self.len
		for i = 1, ac do
			if av[i] == Argv.ANYARG then
				res[#res+1] = 'ANYARG'
			elseif av[i] == Argv.ANYARGS then
				res[#res+1] = 'ANYARGS'
			else
				w( av[i] )
			end
			if i < ac then
				res[#res+1] = ',' -- can not use qtostring in w()
			end
		end
		return table.concat( res )
	end
-- ../src/class/argv.nw:11
	
-- ../src/argv.nw:156
	function Argv:unpack ()
		return unpack( self.v, 1, self.len )
	end
-- ../src/unittestfiles.nw:121
	
	local A = Action.generic
	Action = nil -- only allow generic action
	function A:tostring () return "<generic action>" end
	
	local a
	
	function setup ()
		a = A:new()
	end
	
	
-- ../src/restrictions.nw:422
	function add_depend_test ()
		local ls = { 0, 'foo', 1/0, a, {} }
		local seen = {}
		for _, l in ipairs( ls ) do
			seen[l] = 0
			a:add_depend( l )
		end
		for l in a:depends() do
			seen[l] = seen[l] + 1
		end
		for _, l in ipairs( ls ) do
			assert_equal( 1, seen[l], "Mismatch for "..qtostring(l) )
		end
	end
	function dependencies_dont_iterate_on_empty_list_test ()
		for _ in a:depends() do
			fail( "unexpected dependency" )
		end
	end

-- ../src/unittestfiles.nw:133
	
-- ../src/restrictions.nw:178
	function label_test ()
		local ls = { 1/0, 0, false, {}, a, "foo", true }
		for i = 1, #ls do
			assert_false( a:has_label( ls[i] ))
		end
		for i = 1, #ls do
			a:add_label( ls[i] )
			for j = 1 , #ls do
				if j <= i then
					assert_true( a:has_label( ls[j] ))
				else
					assert_false( a:has_label( ls[j] ))
				end
			end
		end
	end
	function add_label_twice_test ()
		local l = 'foo'
		a:add_label( l )
		a:add_label( l )
		local cnt = 0
		for x in a:blocks() do
			assert_equal( l, x )
			cnt = cnt + 1
		end
		assert_equal( 1, cnt )
	end

-- ../src/unittestfiles.nw:134
	
-- ../src/main.nw:242
	function expect_unreplayed_action_test ()
		assert_true( a:is_expected() )
	end

-- ../src/unittestfiles.nw:135
	
-- ../src/main.nw:320
	function unreplayed_action_is_not_satisfied_test ()
		assert_false( a:is_satisfied() )
	end
	function assert_satisfied_unreplayed_action_fails_test ()
		local ok, err = pcall( function() a:assert_satisfied() end )
		assert_false( ok, "unreplayed action was satisfied" )
		assert_match( "Wrong replay count 0", err )
	end

-- ../src/unittestfiles.nw:136
	
-- ../src/main.nw:254
	function match_unreplayed_test ()
		assert_true( a:match( a ))
	end
	function match_rejects_replayed_action_test ()
		a.replay_count = 1
		assert_false( a:match( a ))
	end
	function match_rejects_wrong_action_type_test ()
		-- Fake different type
		local B = class( A )
		local b = B:new()
		assert_false( a:match( b ))
	end

-- ../src/unittestfiles.nw:137
	
-- ../src/main.nw:212
	function new_action_has_right_default_values_test ()
		assert_equal( 0, a.replay_count )
		assert_equal( 1, a.min_replays )
		assert_equal( 1, a.max_replays )
	end

-- ../src/unittestfiles.nw:138
	
-- ../src/restrictions.nw:90
	function set_and_get_times_test ()
	end
	function unrealistic_times_fails_test ()
		local ps = { {'foo'}, {8,'bar'}, {-1}, {3,2}, {1/0}, {0/0}, {0,0} }
		for _, p in ipairs( ps ) do
			local ok, err = pcall( function() a:set_times( unpack(p) ) end )
			assert_false( ok, "unrealistic times "..table.concat(p,", ") )
			assert_match( "Unrealistic time arguments ", err )
		end
	end


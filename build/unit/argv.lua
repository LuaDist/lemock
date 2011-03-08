-- ../src/unittestfiles.nw:85
	
-- ../src/misc.nw:7
	------ THIS FILE IS TANGLED FROM LITERATE SOURCE FILES ------
	-- Copyright (C) 2009 Tommy Pettersson <ptp@lysator.liu.se>
	-- See terms in file COPYRIGHT, or at http://lemock.luaforge.net

-- ../src/unittestfiles.nw:86
	
	require 'lunit'
	module( 'unit.argv', lunit.testcase, package.seeall )
	
	local class, object, value_equal, sfmt, qtostring
	
-- ../src/helperfunctions.nw:12
	function object (class)
		return setmetatable( {}, class )
	end
	function class (parent)
		local c = object(parent)
		c.__index = c
		return c
	end
-- ../src/unittestfiles.nw:92
	
-- ../src/helperfunctions.nw:29
	function value_equal (a, b)
		if a == b then return true end
		if a ~= a and b ~= b then return true end -- NaN == NaN
		return false
	end
-- ../src/unittestfiles.nw:93
	
-- ../src/tostring.nw:23
	sfmt = string.format
	function qtostring (v)
		if type(v) == 'string' then
			return sfmt( '%q', v )
		else
			return tostring( v )
		end
	end
-- ../src/unittestfiles.nw:94
	
	local Argv
	
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
-- ../src/unittestfiles.nw:97
	
	
-- ../src/argv.nw:63
	local l = {}
	local function p (...) l[#l+1] = { n=select('#',...), ... } end
	p() p(nil) p(nil,nil) p(false) p({}) p(false,nil,{},nil) p(nil,p)
	p(true) p(0.1,'','a') p(1/0,nil,0/0) p(0/0) p(0/0, true) p(0/0, false)
	function equal_test ()
		local a1, a2, f, op
		for i = 1, #l do
			ai = Argv:new( unpack( l[i], 1, l[i].n ))
			for j = 1, #l do
				aj = Argv:new( unpack( l[j], 1, l[j].n ))
				if i == j then
					f, op = assert_true,  ') ~= ('
				else
					f, op = assert_false, ') == ('
				end
				f( ai:equal(aj), '('..ai:tostring()..op..aj:tostring()..')' )
			end
		end
	end
	function equal_anyargs_test ()
		local a, b = {}, {}
		a[1] = Argv:new( Argv.ANYARGS )
		a[2] = Argv:new( 6, Argv.ANYARGS )
		a[3] = Argv:new( 6, 5, Argv.ANYARGS )
		for i = 1, #l do
			b[1] = Argv:new( unpack( l[i], 1, l[i].n ))
			b[2] = Argv:new( 6, unpack( l[i], 1, l[i].n ))
			b[3] = Argv:new( 6, 5, unpack( l[i], 1, l[i].n ))
			for j = 1, 3 do
				local astr = '('..a[j]:tostring()..')'
				local bstr = '('..b[j]:tostring()..')'
				assert_true( a[j]:equal(b[j]), astr..' ~= '..bstr )
				assert_true( b[j]:equal(a[j]), bstr..' ~= '..astr )
			end
		end
	end
	function equal_anyarg_test ()
		local l = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
		local a1 = Argv:new( unpack(l) )
		for i = 1, 9 do
			l[i] = Argv.ANYARG
			local a2 = Argv:new( unpack(l) )
			assert_true( a1:equal(a2) )
			assert_true( a2:equal(a1) )
			l[i] = i
		end
	end
-- ../src/unittestfiles.nw:99
	
-- ../src/argv.nw:27
	function new_test ()
		Argv:new( Argv.ANYARGS )
		Argv:new( 1, Argv.ANYARGS )
		Argv:new( 1, 2, Argv.ANYARGS )
	end
	function new_anyargs_with_extra_arguments_fails_test ()
		local l = {}
		l['ANYARGS,1']         = { Argv.ANYARGS, 1 }
		l['ANYARGS,ANYARGS'  ] = { Argv.ANYARGS, Argv.ANYARGS }
		l['1,ANYARGS,1']       = { 1, Argv.ANYARGS, 1 }
		l['1,ANYARGS,ANYARGS'] = { 1, Argv.ANYARGS, Argv.ANYARGS }
		for msg, args in pairs( l ) do
			local ok, err = pcall( function() Argv:new( unpack(args) ) end )
			assert_false( ok, "Bad ANYARGS accepted for "..msg )
			assert_match( "ANYARGS not at end", err )
		end
	end

-- ../src/unittestfiles.nw:100
	
-- ../src/tostring.nw:151
	function tostring_test ()
		assert_equal( '',              Argv:new()              :tostring() )
		assert_equal( '""',            Argv:new('')            :tostring() )
		assert_equal( 'nil,nil',       Argv:new(nil,nil)       :tostring() )
		assert_equal( '"false",false', Argv:new('false',false) :tostring() )
		assert_equal( '1,2,3',         Argv:new(1,2,3)         :tostring() )
		assert_equal( '1,ANYARG,3',    Argv:new(1,Argv.ANYARG,3):tostring() )
		assert_equal( 'ANYARGS',       Argv:new(Argv.ANYARGS)  :tostring() )
		assert_equal( '7,0,ANYARGS',   Argv:new(7,0,Argv.ANYARGS):tostring() )
	end

-- ../src/unittestfiles.nw:101
	
-- ../src/argv.nw:148
	function unpack_test ()
		local a, b, c = Argv:new( false, nil, 7 ):unpack()
		assert_equal( false, a )
		assert_equal( nil,   b )
		assert_equal( 7,     c )
	end


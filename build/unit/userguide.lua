-- ../src/doc/userguide/unittests.nw:7
	
-- ../src/misc.nw:7
	------ THIS FILE IS TANGLED FROM LITERATE SOURCE FILES ------
	-- Copyright (C) 2009 Tommy Pettersson <ptp@lysator.liu.se>
	-- See terms in file COPYRIGHT, or at http://lemock.luaforge.net

-- ../src/doc/userguide/unittests.nw:8
	
	require 'lunit'
	module( 'unit.userguide', lunit.testcase, package.seeall )
	
	
-- ../src/doc/userguide/section_actions.nw:32
	function actions_test ()
		
-- ../src/doc/userguide/section_actions.nw:20
require 'lemock'
local mc = lemock.controller()
local m = mc:mock()

m.x = 17    -- assignment
r = m.x     -- indexing
m.x(1,2,3)  -- method call
m:x(1,2,3)  -- method call
m(1,2,3)    -- self call
-- ../src/doc/userguide/section_actions.nw:34
	end
-- ../src/doc/userguide/unittests.nw:13
	
-- ../src/doc/userguide/section_anyargs.nw:42
	function example_anyargs_test ()
		package.loaded.foo = nil
		package.preload.foo = function ()
			foo = {}
			function foo.fetch_data (con)
				local res = con:poll()
				while not res do
					con:sleep( 10 )
					res = con:poll()
				end
				con.lasttime = os.time()
				return tonumber( res )
			end
		end
		
-- ../src/doc/userguide/section_anyargs.nw:24
require 'lemock'
local mc = lemock.controller()
local con = mc:mock()

con:poll()           ;mc :returns(nil)
con:sleep(mc.ANYARG)
con:poll()           ;mc :returns('123.45')
con.lasttime = mc.ANYARG

mc:replay()
require 'foo'
local res = foo.fetch_data(con)
assert( math.abs(res-123.45) < 0.0005 )

mc:verify()
-- ../src/doc/userguide/section_anyargs.nw:57
	end
-- ../src/doc/userguide/unittests.nw:14
	
-- ../src/doc/userguide/section_close.nw:53
	function close_test ()
		package.loaded.foo = nil
		package.preload.foo = function ()
			foo = {}
			function foo.dump (xio, name, len)
				local f = xio.open( name, 'r' )
				f:read( len )
				f:close()
			end
		end
		
-- ../src/doc/userguide/section_close.nw:31
require 'lemock'
local mc = lemock.controller()
local myio = mc:mock()
local fs   = mc:mock()

myio.open('abc', 'r') ;mc :returns(fs)
mc :label('open')

fs:read(mc.ANYARG) ;mc :returns('data')
mc :atleastonce() :label('read') :depend('open')

fs:close() ;mc :returns(true)
mc :depend('open') :close('read')

mc:replay()
require 'foo'
foo.dump(myio, 'abc', 128)

mc:verify()
-- ../src/doc/userguide/section_close.nw:64
	end
-- ../src/doc/userguide/unittests.nw:15
	
-- ../src/doc/userguide/section_label_depend.nw:57
	function example_depend_test ()
		package.loaded.foo = nil
		package.preload.foo = function ()
			foo = {}
			function foo.draw_square (sq)
				sq:botright() sq:topright() sq:rightedge()
				sq:botleft()  sq:topleft()  sq:leftedge()
				sq:topedge() sq:botedge()
				sq:fill()
			end
		end
		
-- ../src/doc/userguide/section_label_depend.nw:35
require 'lemock'
local mc = lemock.controller()
local square = mc:mock()

square:topleft()   ;mc :label('tl')
square:topright()  ;mc :label('tr')
square:botleft()   ;mc :label('bl')
square:botright()  ;mc :label('br')
square:leftedge()  ;mc :label('edge') :depend('tl', 'bl')
square:rightedge() ;mc :label('edge') :depend('tr', 'br')
square:topedge()   ;mc :label('edge') :depend('tl', 'tr')
square:botedge()   ;mc :label('edge') :depend('bl', 'br')
square:fill()      ;mc                :depend('edge')

mc:replay()
require 'foo'
foo.draw_square( square )

mc:verify()
-- ../src/doc/userguide/section_label_depend.nw:69
	end
-- ../src/doc/userguide/unittests.nw:16
	
-- ../src/doc/userguide/chapter_tricks.nw:65
	function overloading_test ()
		
-- ../src/doc/userguide/chapter_tricks.nw:39
require 'lemock'
local mc = lemock.controller()
local m = mc:mock()

do
local function add (a, b)
    if type(a) == 'number' then
        return m.add_number(a, b)
    else
        return m.add_string(a, b)
    end
end
rawset( m, 'add', add ) -- not recorded
end -- do

m.add_number(1, 2)         ;mc :returns(3)
m.add_string('foo', 'bar') ;mc :returns('foobar')

mc:replay()
assert_equal( 3, m.add(1, 2) )
assert_equal( 'foobar', m.add('foo', 'bar') )

mc:verify()
-- ../src/doc/userguide/chapter_tricks.nw:67
	end
-- ../src/doc/userguide/unittests.nw:17
	
-- ../src/doc/userguide/section_returns_error.nw:36
	function returns_error_test ()
		
-- ../src/doc/userguide/section_returns_error.nw:27
require 'lemock'
local mc = lemock.controller()
local m = mc:mock()

m:foo(17)  ;mc :returns(nil, "index out of range")
m:bar(-1)  ;mc :error("invalid index")
-- ../src/doc/userguide/section_returns_error.nw:38
	end
-- ../src/doc/userguide/unittests.nw:18
	
-- ../src/doc/userguide/chapter_introduction.nw:71
	function example_simple_test ()
		package.loaded.foo = nil
		package.preload.foo = function ()
			foo = {}
			q = require 'luasql.sqlite3'
			function foo.insert_data()
				local env = q()
				local con = env:connect( '/data/base' )
				local ok, err = pcall( con.execute, con, 'insert foo bar' )
				con:close()
				env:close()
				return ok
			end
			return foo
		end
		
-- ../src/doc/userguide/chapter_introduction.nw:40
-- Setup
require 'lemock'
local mc = lemock.controller()
local sqlite3 = mc:mock()
local env     = mc:mock()
local con     = mc:mock()
package.loaded.luasql = nil
package.preload['luasql.sqlite3'] = function ()
    luasql = {}
    luasql.sqlite3 = sqlite3
    return sqlite3
end

-- Record
sqlite3()                 ;mc :returns(env)
env:connect('/data/base') ;mc :returns(con)
con:execute(mc.ANYARGS)   ;mc :error('LuaSQL: no such table')
con:close()
env:close()

-- Replay
mc:replay()
require 'foo'
local res = foo.insert_data(17)
assert(res==false)

--Verify
mc:verify()
-- ../src/doc/userguide/chapter_introduction.nw:87
	end
-- ../src/doc/userguide/unittests.nw:19
	
-- ../src/doc/userguide/section_times.nw:52
	function example_times_test ()
		package.loaded.foo = nil
		package.preload.foo = function ()
			foo = {}
			function foo.mk_watcher ( con )
				local o = {}
				function o:set ( key, val )
					con:update( key, val )
				end
				return o
			end
		end
		
-- ../src/doc/userguide/section_times.nw:36
require 'lemock'
local mc = lemock.controller()
local con = mc:mock()

con:log(mc.ANYARGS) ;mc                :anytimes()
con:update('x',3)   ;mc :returns(true) :atleastonce()

mc:replay()
require 'foo'
local watcher = foo.mk_watcher( con )
watcher:set( 'x', 3 )

mc:verify()
-- ../src/doc/userguide/section_times.nw:65
	end

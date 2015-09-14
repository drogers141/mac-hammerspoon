-- unit tests following simple old-school lua convention I think
-- prints to stdout - works well with current repl, io.write() doesn't

local util = dofile(package.searchpath("util", package.path))
local winutil = dofile(package.searchpath("winutil", package.path))

local t1 = {x = 0, y = 0, w = 0, h = 0}
local t2 = {w = 600, h = 400}
local t3 = {x = 100, y = 100}

local t4 = {x=100, y=100, w=400, h=300}
local t5 = {x=-100, y=100, w=400, h=300}

-- nested tables for checking equals()
local nt1 = { win1={id=1, frame={x=0, y=0, w=0, h=0}},
              win2={id=2, frame={x=100, y=50, w=600, h=400}}}
local nt2 = { win1={id=1, frame={x=0, y=0, w=0, h=0}},
              win2={id=2, frame={x=100, y=50, w=600, h=400}}}

local nt3 = { win1={id=1, frame={x=0, y=0, w=100, h=100}},
              win2={id=2, frame={x=100, y=50, w=600, h=400}}}
local nt4 = { win1={id=1, frame={x=0, y=0, w=100, h=100}},
              win2={id=2, frame={x=100, y=50, w=600, h=400}},
              andnow="something totally different"}

print("Running tests")
print("testing equals")
assert(util.equals(1,1))
assert(not util.equals(1,"1"))
assert(not util.equals(1, 2))

--assert(util.add(1,2) == 3)
assert(not util.equals(t1,t2))
assert(not util.equals(t1,t3))
assert(util.equals(nt1, nt2))
assert(not util.equals(nt1, nt3))
assert(not util.equals(nt3, nt4))


print("testing merge")
assert(util.equals(util.merge(t1, t2), {x=0, y=0, w=600, h=400}))
assert(util.equals(util.merge(t1, t3), {x=100, y=100, w=0, h=0}))
assert(util.equals(util.merge(t2, t3), {x=100, y=100, w=600, h=400}))

print("testing reverse")
assert(util.equals(util.reverse({1, 2, 3, 4, 5}), {5, 4, 3, 2, 1}))
assert(util.equals(util.reverse({}), {}))

print("testing win move and resize")
assert(util.equals(winutil.move_rect(t4, {x=-200, y=0}), t5))
assert(util.equals(winutil.move_rect(t4, {x=-0, y=0}), t4))

assert(util.equals(winutil.resize_rect(t4, {x=-200, y=0}),
                                  {x=100, y=100, w=200, h=300}))
assert(util.equals(winutil.resize_rect(t4, {x=100, y=100}),
                                  {x=100, y=100, w=500, h=400}))
-- check can't create negative
assert(util.equals(winutil.resize_rect(t4, {x=-1000, y=100}), t4))
assert(util.equals(winutil.resize_rect(t4, {x=0, y=-1000}), t4))

print("testing win throw")
local screen_r = {x=0, y=22, w=1920, h=1095}
local win_r = {x=200, y=100, w=600, h=400}

assert(util.equals(winutil.throw_rect(win_r, screen_r, "left"),
                  hs.geometry({x=0, y=100, w=600, h=400})))
assert(util.equals(winutil.throw_rect(win_r, screen_r, "right"),
                  hs.geometry({x=1320, y=100, w=600, h=400})))
assert(util.equals(winutil.throw_rect(win_r, screen_r, "up"),
                  hs.geometry({x=200, y=22, w=600, h=400})))
assert(util.equals(winutil.throw_rect(win_r, screen_r, "down"),
                  hs.geometry({x=200, y=717, w=600, h=400})))

print("testing win expand_fill_rect")
local screen_r = {x=0, y=22, w=1920, h=1095}
local win_r = {x=200, y=100, w=600, h=400}

assert(util.equals(winutil.expand_fill_rect(win_r, screen_r, "left"),
                  hs.geometry({x=0, y=100, w=800, h=400})))
assert(util.equals(winutil.expand_fill_rect(win_r, screen_r, "right"),
                  hs.geometry({x=200, y=100, w=1720, h=400})))
assert(util.equals(winutil.expand_fill_rect(win_r, screen_r, "up"),
                  hs.geometry({x=200, y=22, w=600, h=478})))
assert(util.equals(winutil.expand_fill_rect(win_r, screen_r, "down"),
                  hs.geometry({x=200, y=100, w=600, h=1017})))

print("ok")

-- Operations on windows that make use of lower level utils
-- among the functions here are those intended to be bound to keys

winops = {}

local winutil = dofile(package.searchpath("winutil", package.path))
local fn = hs.fnutils
-----------------------------------------------------------
-- Window Movement and Resizing
-----------------------------------------------------------

local function move_win(mvec)
  local w = hs.window.focusedWindow()
  winutil.move_win(w, mvec)
end

local function resize_win(mvec)
  local w = hs.window.focusedWindow()
  winutil.resize_win(w, mvec)
end

-- move window right 5 percent of screen
winops.move_win_right_5 = fn.partial(move_win, {x=5, y=0})

--function winops.move_win_right_5()
--  move_win({x=5, y=0})
--end

-- move window left 5 percent of screen
winops.move_win_left_5 = fn.partial(move_win, {x=-5, y=0})

-- move window up 5 percent of screen
winops.move_win_up_5 = fn.partial(move_win, {x=0, y=-5})

-- move window down 5 percent of screen
winops.move_win_down_5 = fn.partial(move_win, {x=0, y=5})

-- resize window right 5 percent of screen
winops.resize_win_right_5 = fn.partial(resize_win, {x=5, y=0})

-- resize window left 5 percent of screen
winops.resize_win_left_5 = fn.partial(resize_win, {x=-5, y=0})

-- resize window up 5 percent of screen
winops.resize_win_up_5 = fn.partial(resize_win, {x=0, y=-5})

-- resize window down 5 percent of screen
winops.resize_win_down_5 = fn.partial(resize_win, {x=0, y=5})


local function throw_win(direction)
  local win = hs.window.focusedWindow()
  winutil.throw_win(win, direction)
end

-- throw window to right side of screen
winops.throw_right = fn.partial(throw_win, "right")

-- throw window to left side of screen
winops.throw_left = fn.partial(throw_win, "left")

-- throw window to top of screen
winops.throw_up = fn.partial(throw_win, "up")

-- throw window to bottom of screen
winops.throw_down = fn.partial(throw_win, "down")

local function expand_fill_win(direction)
  local win = hs.window.focusedWindow()
  winutil.expand_fill_win(win, direction)
end

-- expand window to right side of screen
winops.expand_fill_right = fn.partial(expand_fill_win, "right")

-- expand window to left side of screen
winops.expand_fill_left = fn.partial(expand_fill_win, "left")

-- expand window to top of screen
winops.expand_fill_up = fn.partial(expand_fill_win, "up")

-- expand window to bottom of screen
winops.expand_fill_down = fn.partial(expand_fill_win, "down")

return winops

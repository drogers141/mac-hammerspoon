-- window related functionality
-- moving, data, etc

--local util = require "util"
local util = dofile(package.searchpath("util", package.path))

win = {}

----------------------------------------------------------------------
-- Rectangle operations - all take and return rectangles (no mutation)
-- ie - same as hydra's frames {x, y, w, h}
----------------------------------------------------------------------

-- move a rect by adding an {x, y} vector to it
-- r - rect to move
-- m - {x, y} - movement vector - +x moves right, -x moves left
--    +y moves down, -y moves up
win.move_rect = function(r, m)
  return {x = r.x + m.x, y = r.y + m.y, w = r.w, h = r.h}
end

-- resize a rect by moving the right and/or bottom edge
-- attempting to resize to a negative width or height is a no-op
--    and r is returned
-- r - rect to resize
-- delta - {x, y} - vector to resize by - +x grows window to right,
--    -x shrinks window on right, +y grows window downward
--    -y shrinks window by raising bottom
win.resize_rect = function(r, delta)
  local result = {x = r.x, y = r.y, w = r.w + delta.x, h = r.h + delta.y}
  if result.w <= 0 or result.h <= 0 then
    return r
  else
    return result
  end
end

-- throw a rect in one direction to the inside border of a bounding rect
-- can throw a rect left, right, up, or down and it will stick to the edge
-- of the surrounding rect where it hits - general case is to move a window
-- all the way to the edge of a screen in one direction while maintaining
-- its size and location on the axis in the other direction
-- however, you can have a window that is somewhat past the edge of a screen
-- and throw it in the same direction to quickly put it back fully on the screen
-- r - rect to throw
-- outside_r - "outside" or "enclosing" rect that the rect gets thrown to
--    quotes are for case explained above - doesn't have to be actually enclosing
-- direction - string - one of ["left", "right", "up", "down"]
--    bad direction or outside_r cause assertion failure
win.throw_rect = function(r, outside_r, direction)
  local outside_right = outside_r.x + outside_r.w
  local outside_bottom = outside_r.y + outside_r.h
  assert(outside_right > 0 and outside_bottom > 0)

  ret = nil
  if direction == "left" then
    ret = util.merge(r, {x = outside_r.x})
  elseif direction == "right" then
    ret = util.merge(r, {x = outside_right-r.w})
  elseif direction == "up" then
    ret = util.merge(r, {y = outside_r.y})
  elseif direction == "down" then
    ret = util.merge(r, {y = outside_bottom-r.h})
  else
    assert(false, "bad direction: " .. direction)
  end

  return ret
end

-- like throw_rect but for resizing
-- expand a rect in one direction all the way to meet the inside border of the
-- bounding rect
-- unlike resize rect - since only expanding - can fill in all 4 directions
-- r - rect to throw
-- outside_r - bounding rect that the rect gets filled to
--    note that as long as the resulting rect has positive width and height
--    expand_fill can behave similarly to the cases mentioned in throw_win
--    commentary
-- direction - string - one of ["left", "right", "up", "down"]
--    bad direction or outside_r cause assertion failure
--    causing the resulting rect to have non-positive width or height
--    causes an assertion failure
function win.expand_fill_rect(r, outside_r, direction)
  local outside_right = outside_r.x + outside_r.w
  local outside_bottom = outside_r.y + outside_r.h
  local r_right = r.x + r.w
  local r_bottom = r.y + r.h
  assert(outside_right > 0 and outside_bottom > 0)

  ret = nil
  if direction == "left" then
    ret = util.merge(r, {x = outside_r.x,
                          w = r_right - outside_r.x})
  elseif direction == "right" then
    ret = util.merge(r, {w = outside_right - r.x})
  elseif direction == "up" then
    ret = util.merge(r, {y = outside_r.y,
                          h = r_bottom - outside_r.y})
  elseif direction == "down" then
      ret = util.merge(r, {h = outside_bottom - r.y})
  else
    assert(false, "bad direction: " .. direction)
  end
  assert(ret.w > 0 and ret.h > 0, "resized rect not cool by Euclid")

  return ret
end


----------------------------------------------------------------------
-- Window operations - mutate window frame state
----------------------------------------------------------------------

local function screen_size(w)
  local s_rect = w:screen():frame()
  return {w = s_rect['w'], h = s_rect['h']}
end

-- move a window by adding an {x, y} vector to it
-- by default x and y are percentage of screen width or height, respectively
-- w - window to move
-- m - {x, y} - movement vector - +x moves right, -x moves left
--    +y moves down, -y moves up
--    eg m = {x = 5, y = 0} -> moves window 5% of screen width to right
-- use-pix - if this is set to a truthy value, x and y are interpreted
--    as pixels - so above would move the window 5 pixels to the right
win.move_win = function(w, m, use_pix)
  local x, y = m['x'], m['y']
  if not use_pix then
    local sz = screen_size(w)
    x, y = x * sz['w']/100, y * sz['h']/100
  end
  --print ('x:', x, 'y:', y)
  local frame = win.move_rect(w:frame(), {x=x, y=y})
  w:setFrame(frame)
end

-- resize a window by adding an {x, y} vector to it by moving the right and/or bottom edge
--    attempting to resize to a negative width or height is a no-op
-- by default x and y are percentage of screen width or height, respectively
-- w - window to resize
-- m - {x, y} - resize vector - +x grows right edge, -x shrinks right edge
--    +y resizes down, -y resizes up
--    eg m = {x = 5, y = 0} -> grows window 5% of screen width to right
-- use-pix - if this is set to a truthy value, x and y are interpreted
--    as pixels - so above would grow the window 5 pixels to the right
win.resize_win = function(w, m, use_pix)
  local x, y = m['x'], m['y']
  if not use_pix then
    local sz = screen_size(w)
    x, y = x * sz['w']/100, y * sz['h']/100
  end
  --print ('x:', x, 'y:', y)
  local frame = win.resize_rect(w:frame(), {x=x, y=y})
  w:setFrame(frame)
end

-- throw a window to stick to the edge of its screen
-- see throw_rect comments for more
-- NOTE: Uses frame_without_dock_or_menu() as the outside rect to throw to
-- direction - string - one of ["left", "right", "up", "down"]
--    bad direction causes assertion failure
win.throw_win = function(w, direction)
  local wr = w:frame()
  local sr = w:screen():frame()
  local frame = win.throw_rect(wr, sr, direction)
  w:setFrame(frame)
end

-- expand a window in one direction to the edge of its screen
-- see expand_fill_rect comments for more
-- NOTE: Uses frame_without_dock_or_menu() as the outside rect to expand to
-- direction - string - one of ["left", "right", "up", "down"]
--    bad direction causes assertion failure
--    causing a window with non-positive width or height to result
--    also causes assertion failure
win.expand_fill_win = function(w, direction)
  local wr = w:frame()
  local sr = w:screen():frame()
  local frame = win.expand_fill_rect(wr, sr, direction)
  w:setFrame(frame)
end

return win

-- General language and low level application utilities
-- see test.lua if questions

util = {}

-------------------------------------------------------------------------------
-- TABLE UTILS
-- In general assume table is a dictionary data structure for these
-------------------------------------------------------------------------------

-- util.merge(t1, t2, ..) -> table
-- Params are tables
-- Returns a copy of the merging of all tables taken from left to right
-- ie - adds keys and values in each new table to the merge
-- and overwrites any keys with new values if there are equal keys
util.merge = function(...)
  local merged = {}
  for i, t in ipairs{...} do
    for k, v in pairs(t) do
      merged[k] = v
    end
  end
  return merged
end

-- tables have equal values for equal keys
-- recursive to handle nested tables
-- but pretty naive - only for tables that are values
-- see tests for expected examples
util.equals = function(t1, t2)
  if type(t1) ~= type(t2) then
    return false
  elseif type(t1) ~= "table" then
    return t1 == t2
  end
  for k,v in pairs(t1) do
    if not util.equals(t1[k], t2[k]) then
      return false
    end
  end
  for k,v in pairs(t2) do
    if not util.equals(t1[k], t2[k]) then
      return false
    end
  end
  return true
end

-- returns reverse copy of l
-- which is a table that is a list
-- does not mutate l
util.reverse = function(l)
  local rev = {}
  for i, v in pairs(l) do
    table.insert(rev, 1, v)
  end
  return rev
end

-- returns set of the keys for a table
-- t - table assumed to be a dictionary
function util.keys(t)
  local keyset = {}
  local i = 0

  for k, v in pairs(t) do
    i = i + 1
    keyset[i]=k
  end
  return keyset
end

-- *** str and print are for more limited usage

-- one line string repr of simple key value table
-- ie rects or sizes - no nested stuff
function util.str(t)
  local s = ""
  for k, v in pairs(t) do
    s = s .. k .. "=" .. v .. ", "
  end
  if s and string.len(s) > 2 then
    s = "{" .. string.sub(s, 1, string.len(s)-2) .. "}"
    return s
  end
end

-- print table to stdout in one line
-- t - table - assume you can easily print keys and values
util.print = function(r)
  print(util.str(r))
end


-------------------------------------------------------------------------------
-- OS INTERACTION UTILS
-- logging, directory stuff, audio, etc
-------------------------------------------------------------------------------

-- UPDATE: for macOS Sierra
-- new unified logging system breaks syslog
-- rather than play with the new system for my stuff will replicate
-- system logging in ~/log
util.logfile = "/Users/drogers/log/hammerspoon.log"

-- log a string to util.logfile
-- params
-- s - string to log
-- t - optional tag - defaults to "[dr-hammerspoon]"
util.syslog = function(s, t)
  local tag = t or "[dr-hammerspoon]"
  local out = assert(io.open(util.logfile,'a'))
  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  out:write(timestamp.." "..tag.." "..s.."\n")
  out:close()
end

-- log string s to file f in append mode
util.log = function(s, f)
  local out = assert(io.open(f,'a'))
  out:write(s)
  out:close()
end

-- returns table of absolute paths of files under dirpath
-- as returned by ls if dirpath is a directory
-- otherwise returns nil
function util.dir(dirpath)
  -- remove possible trailing slash
  if string.sub(dirpath, string.len(dirpath),string.len(dirpath)) == "/" then
    dirpath = string.sub(dirpath, 1, string.len(dirpath) - 1)
  end
  local cmd = '[[ -d "' .. dirpath .. '" ]] && ls "' .. dirpath .. '"'
  print(cmd)
  local f = assert(io.popen(cmd))
  local ret = {}
  for l in f:lines() do
    ret[#ret+1] = dirpath .. "/" .. l
  end
  if #ret == 0 then
    ret = nil
  end
  return ret
end

-- increment or decrement default audio output device volume
-- delta - positive or negative - percentage to raise or lower volume
--function util.volume_adjust(delta)
--  local ad = audiodevice.defaultoutputdevice()
--  local maybe_new_vol = ad:volume() + delta
--  local new_vol = math.max(0, math.min(100, maybe_new_vol))
--  ad:setvolume(new_vol)
--end

-- noarg calls for key binding
-- increment or decrement volume by 3 percent
--util.volume_up = fnutils.partial(util.volume_adjust, 3)
--util.volume_down = fnutils.partial(util.volume_adjust, -3)


-------------------------------------------------------------------------------
-- WINDOW AND SCREEN UTILS
-------------------------------------------------------------------------------

-- "visible" windows in mru order
-- note this replaces window.orderedwindows()
-- currently need to filter out windows that are not "standard" in some apps
-- e.g. - if an iTerm terminal is in focus, 2 title-less windows
-- with the same frame as the screen will be displayed
util.orderedwindows = function()
  return hs.fnutils.filter(hs.window.orderedWindows(),
                            function(w) return w:isStandard() end)
end

-- get the frame rect from a window or a screen object as a table that can be
-- serialized and recreate a rect - ie dogfooded
util.get_frame_rect = function(o)
  return {x=o:frame().x, y=o:frame().y,
          w=o:frame().w, h=o:frame().h}
end


-- table for a window userdata object
--    id, application title, frame, window title
util.windowtable = function(w)
  return {id=w:id(), apptitle=w:application():title(),
            frame=util.get_frame_rect(w), title=w:title()}
end

-- table for a screen userdata object - frame,
--    frames with and without dock and menu
util.screentable = function(s)
  return {frame=util.get_frame_rect(s), fullFrame=s:fullFrame().table}
end

-- get a window from current ordered standard windows by id
-- id - number
util.windowbyid = function(id)
  for i, w in pairs(util.orderedwindows()) do
    if w:id() == id then
      return w
    end
  end
end

-- identify screen based on resolution
-- arbitrarily deciding on id here
-- so need to add any new screens
util.screens = {
  -- laptop
  s1 = {h = 900, w = 1440, x = 0, y = 0},
  -- Dell 26 inch
  s2= {h = 1200, w = 1920, x = 0, y = 0},
  -- work - Nixeus 27 inch
  s3 = {h = 1440, w = 2560, x = 0, y = 0}
}

-- rect - hs.geometry.rect
-- returns a screen_id string if found, or nil
util.get_screen_id = function(rect)
  for i, r in pairs(util.screens) do
    if rect:equals(r) then
      return i
    end
  end
end

---------------------------------------------------------------
-- OTHER
---------------------------------------------------------------

-- returns list of lines in multiline string s
-- splits on \n, removes \n from lines
function util.splitlines(s)
  local retlist = {}
  for l in string.gmatch(s, "[^\n]+") do
    retlist[#retlist+1] = l
  end
  return retlist
end

-- width is determined by longest line in text
--function util.textgrid(title, text)
--  local win = textgrid.create()
----  win:protect()
--
--  local textlines = util.splitlines(text)
--  local lenmap = fnutils.map(textlines, string.len)
--  local maxlen = math.max(table.unpack(lenmap))
--  local size = {w = math.max(40, maxlen + 2),
--                h = math.max(10, #textlines + 2)}
--
--  local pos = 1 -- i.e. line currently at top of log textgrid
--
--  local fg = "00FF00"
--  local bg = "222222"
--
--  win:settitle(title)
--  win:resize(size)
--
--  win:setbg(bg)
--  win:setfg(fg)
--  win:clear()
--
--  for linenum = pos, math.min(pos + size.h, #textlines) do
--    local line = textlines[linenum]
--    for i = 1, math.min(#line, size.w) do
--      local c = line:sub(i,i)
--      win:setchar(c, i, linenum - pos + 1)
--    end
--  end
--
--  win:show()
--  win:focus()
--
--  return win
--end


return util


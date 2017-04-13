-- Spaces support adapter
-- Since there is no Spaces, ie virtual desktops, support anymore in Sierra
--
-- The only thing we need at this point is an interface identifying the current
-- space.  This hack relies on the convention of always having an iterm
-- terminal with the number of the Desktop (Space) as its number.

local util = dofile(package.searchpath("util", package.path))

spaces = {}

-- Returns current Space, aka Desktop
-- Logs error and returns -1 if it can't get the space id
-- otherwise returns id in [1..n], where there are n Desktops/Spaces set up
function spaces.current_space()
  local iterm_wins = hs.fnutils.filter(util.orderedwindows(), function(w)
                            return w:application():name() == "iTerm2" end)
  return hs.fnutils.filter(iterm_wins, function(w) return w:title() end)
end

function iterm_id_from_title(title)
  local s = string.match(title, "^(%d+).*")
  local id = -1
  if s ~= nil and tonumber(s) ~= nil then
    id = tonumber(s)
  end
  return id
end

function id_from_iterm_titles(titles)
  local ids = filter(titles, function(t) return iterm_id_from_title ~= -1 end)
  local id = -1
  return "finish implementing"
end

function spaces.test()
  local titles = {"5. drogers@drogers-mbp: ~/my-git/bin-scripts (bash)",
                  "1. drogers@drogers-mbp: ~ (bash)",
                  "Programming in Lua : 3.6",
                  "Activity Monitor (All Processes)"}
  return hs.fnutils.map(titles, iterm_id)
end


return spaces


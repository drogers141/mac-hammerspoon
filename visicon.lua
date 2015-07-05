-- Visibility Context
-- Abstraction for handling state I care about
-- Add docs

local util = dofile(package.searchpath("util", package.path))

-- **** SPACES FUNCTIONALITY - INTERNAL/EPHEMERAL ***
local spaces = require("hs._asm.undocumented.spaces")

visicon = {}

visicon.snapshot_dir = '/Users/drogers/.hammerspoon/snapshots'


-- terse time format good for file names
-- timestamp - secs since epoch
local function format_from_timestamp(timestamp)
  return os.date('%Y-%m-%d_%H.%M.%S', timestamp)
end

-- returns table of the current visible windows context
function visicon.state()
  local state = {}
  -- windows in mru order
  local ow = util.orderedwindows()
  local wins = hs.fnutils.map(ow, util.windowtable)
  if wins then
    state['windows'] = wins
    state['screen'] = util.screentable(ow[1]:screen())
    state['desktop'] = math.floor(spaces.currentSpace())
    -- seconds since epoch
    local now = os.time()
    state['timestamp'] = now
    -- formatted datetime - for easy reading
    state['datetime'] = os.date('%c', now)
  end
  return state
end

-- for each visibility context there is a queue
-- 2 screens and 4 desktops -> 8 vcqs
-- screens are identified by resolution
-- each queue will be kept in memory, between a min and max
-- size - the queues hold visicon states as elements
-- relies on ability to always easily determine what desktop
-- is current as well - this seems not to be a problem
-- the queues are just lua tables maintained as arrays
-- with the most recent visicon state at the end of the array
-- ie vsq[#vsq]
-- the queue allows random access for resurrecting a former state
-- which will reposition any windows with the same ids as the previous
-- state had - and have some policy for new windows created after
-- once there is a new state, that is added to the end of the list
-- resizing - when q is longer than max length elements are removed
-- from the front of the q
local vc_queues = {}
MAX_Q_LEN = 50

-- modifies queue by removing front elements until it is of length <= maxlen
-- does no error checking
function visicon.trim_queue(queue, maxlen)
  while #queue > maxlen do
    table.remove(queue, 1)
  end
end

-- returns formatted multiline string with each queue name and length
-- adds asterisk to highlight current vc qname if there is one
function visicon.global_queue_status()
  local qname = visicon.get_current_vc_queue_name()
  local lines = {}
  if #util.keys(vc_queues) == 0 then
    lines[#lines+1] = "{}"
  else
    for i, v in pairs(vc_queues) do
      if qname and i == qname then
        lines[#lines+1] = i .. ": " .. #v .. " *"
      else
        lines[#lines+1] = i .. ": " .. #v
      end
    end
  end
  table.sort(lines)
  table.insert(lines, 1, "vc_queues: ")
  return (table.concat(lines,"\n"))
end

-- Store a json snapshot of the global vc_queues structure
-- holding all of the visicon queues
-- file - optional - save to file - default saves to snapshot log
function visicon.global_snapshot(file)
  local state_str = hs.json.encode(vc_queues)
  local out = file or nil
  if not out then
    out = visicon.snapshot_dir .. '/' .. os.date('%Y-%m-%d_%H.%M.%S') .. ".json"
  end
  util.log(state_str .. "\n", out)
  util.syslog("Saved vc queues to snapshot in file: " .. out)
end

-- Initialize global vc_queues structure from json snapshot
-- snapshot_file - optional - snapshot json file to restore from
--    default restores from most recent snapshot in
--    visicon.snapshot_dir if there is one
--    success or failure logged to syslog
function visicon.restore_queues_from_snapshot(snapshot_file)
  local jsonfile = snapshot_file or nil
  if not jsonfile then
    -- json snapshot files in snapshot_dir sort by date-time
    -- so last is most recent
    snapshots = util.dir(visicon.snapshot_dir)
    table.sort(snapshots)
    jsonfile = #snapshots > 0 and snapshots[#snapshots]
  end

  if jsonfile then
    local f = assert(io.open(jsonfile, 'r'))
    local jsonstr = f:read("*a")
    f:close()
    if jsonstr then
      local vc_qs = hs.json.decode(jsonstr)
      if vc_qs then
        vc_queues = vc_qs
        util.syslog("Restored vc queues from file: " .. jsonfile)
        for i, v in pairs(vc_queues) do
          visicon.trim_queue(v, MAX_Q_LEN)
        end
        util.syslog("Trimmed vc queues")
      else
        util.syslog("Got json string from file: " .. jsonfile ..
                    ", but no vc queues")
      end
    else
      util.syslog("Opened vc queue file: " .. jsonfile .. ", but no contents")
    end
  else
    util.syslog("No vc queue snapshot file available")
  end
end

-- returns name of the queue for the current visibility context
-- nil if not - should log that if it happens and see
-- if we need to change up
function visicon.get_current_vc_queue_name()
  local screen_id = util.get_screen_id(hs.screen.mainScreen():fullFrame())
  local desktop_id = math.floor(spaces.currentSpace())
  if screen_id and desktop_id then
    return screen_id .. 'd' .. desktop_id
  end
end

function visicon.get_vcq_structure()
  return vc_queues
end

function visicon.get_current_vc_queue()
  local qname = visicon.get_current_vc_queue_name()
  if vc_queues[qname] then
    util.syslog("visicon: qname=" .. qname .. ", length=" .. #vc_queues[qname])
  end
  return vc_queues[qname]
end

-- returns flat list of all windows of an app in visicon queue in historical order
-- q - reference to a visicon queue
-- apptitle - value of the window['apptitle'] for a window in a visicon
-- returns - list of windows which are tables with keys: apptitle, frame, id, title
function visicon.all_win_history_by_app(q, apptitle)
  -- list of windows of same app in each visicon and timestamp
  local wins_by_vc = {}
  hs.fnutils.each(q, function(vc)
      local wins = hs.fnutils.filter(vc['windows'], function(e) return e['apptitle'] == apptitle end)
      if #wins > 0 then
        for i = 1, #wins do
          wins_by_vc[#wins_by_vc+1] = wins[i]
        end
      end
    end)
  return wins_by_vc
end

-- returns a table of all unique frame geometries for windows of a specific app
-- in historical order
-- q - reference to a visicon queue
-- apptitle - value of the window['apptitle'] for a window in a visicon
-- return - list of frames - each frame is table with keys: x, y, w, h
function visicon.win_frame_history_by_app(q, apptitle)
  local all_wins = visicon.all_win_history_by_app(q, apptitle)
  local frames = {}
  for i,v in pairs(all_wins) do
    if not hs.fnutils.find(frames, function(e) return util.equals(e, v['frame']) end) then
      frames[#frames+1] = v['frame']
    end
  end
  return frames
end

-- add current visicon state to the appropriate queue
-- create queue if it doesn't exist
-- raises assertion errors if it can't get a queue
function visicon.add_current_vc_state()
  local state = visicon.state()
  local qname = assert(visicon.get_current_vc_queue_name())
  local q = visicon.get_current_vc_queue()
  if q then
    q[#q+1] = state
    visicon.trim_queue(q, MAX_Q_LEN)
  else
    vc_queues[qname] = {state}
  end
  util.syslog("saved vc state to memory: queue=" .. qname .. ", length=" .. #vc_queues[qname])
end

-- set current vc to state by setting each window in vc to
-- geometry for first window in state encountered that has the same
-- application
-- any windows without applications in state are unchanged
-- returns list of ids of windows that were set
-- ids_to_ignore - optional - list of window ids to ignore
function visicon.set_to_state_by_app(state, ids_to_ignore)
  local wins_set = {}
  local logstr = {"Windows set by app:"}
  local wins_to_check = nil
  if ids_to_ignore then
    wins_to_check = hs.fnutils.filter(util.orderedwindows(), function(w)
                        return not hs.fnutils.contains(ids_to_ignore, w:id())
                        end)
  else
    wins_to_check = util.orderedwindows()
  end
  for i, w in pairs(wins_to_check) do
    for j, s in pairs(state['windows']) do
      if s.apptitle == w:application():title() then
        logstr[#logstr+1] = w:id() .. " (" .. w:application():title() .. ")"
        w:setFrame(s.frame)
        wins_set[#wins_set+1] = w:id()
        break
      end
    end
  end
  util.syslog(table.concat(logstr, "  "))
  return wins_set
end

-- set current vc to state by matching window ids in vc to those in state
-- any windows with ids not found in state are unchanged
-- returns list of ids of windows that were set
function visicon.set_to_state_by_id(state)
  local wins_set = {}
  local logstr = {"Windows set by id:"}
  for i, w in pairs(util.orderedwindows()) do
    for j, s in pairs(state['windows']) do
      if s.id == w:id() then
        logstr[#logstr+1] = w:id()
        w:setFrame(s.frame)
        wins_set[#wins_set+1] = w:id()
      end
    end
  end
  util.syslog(table.concat(logstr, "  "))
  return wins_set
end

-- set current vc to state
-- note that this does not then add the new vc context to the current queue
-- first look by app, then by id - this means that wins with id
-- matching one in state are set twice - but always the id match
-- is preferred for the final geometry reset
function visicon.set_to_state(state)
  local wins_str = table.concat(hs.fnutils.map(util.orderedwindows(),
                                    function(w) return w:id() end), ", ")
  local state_str = table.concat(hs.fnutils.map(state['windows'],
                                    function(w) return w.id end), ", ")
  util.syslog("Setting visicon ".. visicon.get_current_vc_queue_name() ..
              " to state .." ..
              "\nWindows in Context: " .. wins_str ..
              "\nWindows in State: " .. state_str)
  local wins_by_id = visicon.set_to_state_by_id(state)
  visicon.set_to_state_by_app(state, wins_by_id)
end

-- find the queue for this visicon and set all the windows
-- as they were in the last state saved if there is one
-- alerts if there is no saved state
function visicon.restore_to_last_state()
  local vc_q = visicon.get_current_vc_queue()
  if not vc_q then
    util.syslog("restore_to_last_state: No queue for this visicon.")
  else
    local prev_state = vc_q[#vc_q]
    if not prev_state then
      util.syslog("restore_to_last_state: No state in queue: " ..
                    visicon.get_current_vc_queue_name())
    else
      visicon.set_to_state(prev_state)
    end
  end
end


return visicon

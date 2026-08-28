local leader = { "cmd", "ctrl" }


-- cycle through windows in the current space
local wf = hs.window.filter.new():setCurrentSpace(true)

local function cycle(dir)
  local wins = wf:getWindows(hs.window.filter.sortByCreated)
  if #wins == 0 then return end

  local cur, idx = hs.window.focusedWindow(), 1
  if cur then
    for i, w in ipairs(wins) do
      if w:id() == cur:id() then idx = i break end
    end
  end

  wins[(idx - 1 + dir) % #wins + 1]:focus()
end

hs.hotkey.bind({"alt"}, "`", function() cycle(1) end)         -- next
hs.hotkey.bind({"alt", "shift"}, "`", function() cycle(-1) end) -- previous

-- Window management
hs.window.animationDuration = 0

local function moveFocused(unit)
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(unit) end
end

hs.hotkey.bind(leader, "h", function() moveFocused({ 0, 0, 0.5, 1 }) end)
hs.hotkey.bind(leader, "l", function() moveFocused({ 0.5, 0, 0.5, 1 }) end)
hs.hotkey.bind(leader, "return", function() moveFocused({ 0, 0, 1, 1 }) end)

-- Reload: leader+R, and automatically on any .lua change in the config dir
hs.hotkey.bind(leader, "r", hs.reload)

local watcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end)
watcher:start()

hs.alert.show("Hammerspoon config loaded")

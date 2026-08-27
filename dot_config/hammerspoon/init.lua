local leader = { "cmd", "ctrl" }

hs.hotkey.bind(leader, "m", function()
   hs.alert.show("Hello, Hammerspoon!")
   hs.notify.new({title="Hammerspoon", informativeText="Hello World"}):send()
end
)

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

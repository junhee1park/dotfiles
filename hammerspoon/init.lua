local function moveWindowToFocusedSpace(application, applicationName)
  local app = hs.application.find(application, true)

  if app == nil then
    hs.application.launchOrFocus(applicationName or application)
  elseif app:isFrontmost() then
    app:hide()
  else
    local mainWindow = app:mainWindow()
    if mainWindow ~= nil then
      -- Re-get the window reference to ensure it's current
      mainWindow = app:mainWindow()
      if mainWindow then
        -- Get current space before any operations
        local currentSpace = hs.spaces.focusedSpace()
        -- Move window to the space we were on
        hs.spaces.moveWindowToSpace(mainWindow, currentSpace)
        -- Focus the window after moving
        mainWindow:focus()
      end
    else
      hs.application.launchOrFocus(applicationName or application)
    end
  end
end

hs.hotkey.bind({ "cmd", "ctrl" }, "b", function()
  moveWindowToFocusedSpace("Dia")
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "t", function()
  moveWindowToFocusedSpace("Rex Beta")
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "n", function()
  moveWindowToFocusedSpace("Obsidian")
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "c", function()
  moveWindowToFocusedSpace("Notion Calendar")
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "a", function()
  moveWindowToFocusedSpace("Things", "Things3")
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "j", function()
  moveWindowToFocusedSpace("Claude")
end)

-- for work
hs.hotkey.bind({ "cmd", "ctrl" }, "i", function()
  moveWindowToFocusedSpace("Linear")
end)
hs.hotkey.bind({ "cmd", "ctrl" }, "s", function()
  moveWindowToFocusedSpace("Slack")
end)

local function centerWindowWithSize(width, height)
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  local screen = win:screen()
  local screenFrame = screen:frame()

  -- Shrink to 90% if larger than the screen
  local adjustedWidth
  local adjustedHeight

  if width > screenFrame.w then
    adjustedWidth = screenFrame.w * 0.9
  else
    adjustedWidth = width
  end

  if height > screenFrame.h then
    adjustedHeight = screenFrame.h * 0.9
  else
    adjustedHeight = height
  end

  -- Compute the centered position
  local x = screenFrame.x + (screenFrame.w - adjustedWidth) / 2
  local y = screenFrame.y + (screenFrame.h - adjustedHeight) / 2

  -- Apply size and position
  win:setFrame({ x = x, y = y, w = adjustedWidth, h = adjustedHeight }, 0)
end

hs.hotkey.bind({ "alt", "ctrl" }, "c", function()
  centerWindowWithSize(1800, 1200)
end)

-- Lay out the focused window based on the display's aspect ratio
-- (GAP padding on the sides and bottom, flush against the top):
--   Ultrawide (21:9+) → 80% width, centered
--   Otherwise (built-in, 16:9 external) → maximize
local GAP = 4
local ULTRAWIDE_RATIO = 2.0

local function framesMatch(a, b)
  return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1
end

local function layoutWindow(win)
  if not win then
    return
  end
  local screen = win:screen()
  if not screen then
    return
  end
  local f = screen:frame()
  local fullFrame = { x = f.x + GAP, y = f.y, w = f.w - 2 * GAP, h = f.h - GAP }
  local standardFrame

  if f.w / f.h > ULTRAWIDE_RATIO then
    local w = f.w * 0.8
    standardFrame = { x = f.x + (f.w - w) / 2, y = f.y, w = w, h = f.h - GAP }
  else
    standardFrame = fullFrame
  end

  win:setFrame(framesMatch(win:frame(), standardFrame) and fullFrame or standardFrame, 0)
end

-- Toggle between the standard layout and the gap-padded full screen frame.
-- Overrides Rectangle's default Maximize on the same chord.
hs.hotkey.bind({ "alt", "ctrl" }, "return", function()
  layoutWindow(hs.window.focusedWindow())
end)

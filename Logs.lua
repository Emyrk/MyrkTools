local AceGUI = LibStub("AceGUI-3.0")

MyrkLogDB = {}
MyrkLogs = {
  maxLines = 100,
  logBuffer = {}
}

local LEVEL_COLORS = {
  DBG = "|cffaaaaaa", -- grey
  INF = "|cff8888ff", -- bluish
  WRN = "|cffffff00", -- yellow
  ERR = "|cffff0000", -- red
}
local COLOR_END = "|r"

function MyrkLogs:Initialize()
  MyrkLogs:CreateLogWindow()
  MyrkLogs:Info("MyrkLogs Initialized")
end

function MyrkLogs:CreateLogWindow()
  if self.logWindow then
    self.logWindow:Show()
    return
  end

  local f = AceGUI:Create("Frame")
  f:SetTitle("Myrk Log")
  f:SetStatusText("Lines: 0")
  f:SetLayout("Fill")
  f:SetWidth(600)
  f:SetHeight(400)
  f:SetCallback("OnClose", function(widget)
    AceGUI:Release(widget)
    self.logWindow = nil
    self.logEdit = nil
  end)

  local edit = AceGUI:Create("MultiLineEditBox")
  edit:SetLabel(nil)
  edit:DisableButton(true) -- hide "Okay" button
  edit:SetNumLines(20)
  edit:SetMaxLetters(0)    -- unlimited
  edit:SetFullWidth(true)
  edit:SetFullHeight(true)
  edit:SetDisabled(true) -- makes it read-only
  f:AddChild(edit)

  self.logWindow = f
  self.logEdit = edit
  self:RefreshLogText()
end

MyrkLogs.debounce = {
  lastText = nil,  -- last DEBUG message text
  repeatCount = 0, -- how many extra times we've seen it (beyond the first line we logged)
  lastTime = 0,
}


function MyrkLogs:RefreshLogText()
  if not self.logEdit then return end
  self.logEdit:SetDisabled(false)
  self.logEdit:SetText(table.concat(MyrkLogs.logBuffer, "\n") ..
    self:DebounceText())
  -- scroll to bottom
  local eb = self.logEdit.editBox
  eb:HighlightText(0, 0)
  -- eb:SetCursorPosition(eb:GetNumLetters())
  self.logEdit:SetDisabled(true)

  if self.logWindow then
    self.logWindow:SetStatusText(string.format("Lines: %s", (table.getn(MyrkLogs.logBuffer))))
  end
end

function MyrkLogs:DebounceText()
  local d = self.debounce
  if d.repeatCount == 0 then
    return ""
  end

  return string.format("\n%s              -->(x%d)", date("%H:%M:%S", d.lastTime), d.repeatCount)
end

-- Core log function with level
function MyrkLogs:Log(level, msg)
  local d = self.debounce
  if d.repeatCount > 0 then
    local repeated = date("%H:%M:%S", d.lastTime) ..
        " [" .. "DBG" .. "] " .. LEVEL_COLORS["DBG"] .. "---> log repeated x" .. tostring(d.repeatCount) .. COLOR_END
    table.insert(MyrkLogs.logBuffer, repeated)
  end

  local now = GetTime()
  d.lastText = msg
  d.repeatCount = 0
  d.lastTime = now

  local color = LEVEL_COLORS[level] or ""
  local line = date("%H:%M:%S") .. " [" .. level .. "] " .. color .. tostring(msg) .. COLOR_END
  table.insert(MyrkLogs.logBuffer, line)
  local lineCount = table.getn(MyrkLogs.logBuffer)
  if lineCount > self.maxLines then
    table.remove(MyrkLogs.logBuffer, self.maxLines - lineCount)
  end
  self:RefreshLogText()
end

-- Convenience wrappers
function MyrkLogs:Debug(msg)
  local text = tostring(msg)

  self:Log("DBG", msg)
end

function MyrkLogs:Debug(msg)
  local text = tostring(msg)
  local now = GetTime()
  local d = self.debounce

  -- If it's the same message within the window, just bump the counter and update the timer
  if d.lastText and d.lastText == text then
    d.repeatCount = d.repeatCount + 1
    d.lastTime = now
    self:RefreshLogText()
    return
  end

  -- Log the new DEBUG message immediately, and start watching for rapid repeats
  self:Log("DBG", text)
end

function MyrkLogs:Info(msg)
  self:Log("INF", msg)
end

function MyrkLogs:Warn(msg)
  self:Log("WRN", msg)
end

function MyrkLogs:Error(msg)
  self:Log("ERR", msg)
end

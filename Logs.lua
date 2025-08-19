local AceGUI = LibStub("AceGUI-3.0")

MyrkLogDB = {}
MyrkLogs = {
  maxLines = 500,
  logBuffer = {}
}

function MyrkLogs:Initialize()
  MyrkLogs:CreateLogWindow()
  MyrkLogs:Log("MyrkLogs Initialized")
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

function MyrkLogs:RefreshLogText()
  if not self.logEdit then return end
  self.logEdit:SetDisabled(false)
  self.logEdit:SetText(table.concat(MyrkLogs.logBuffer, "\n"))
  -- scroll to bottom
  local eb = self.logEdit.editBox
  eb:HighlightText(0, 0)
  -- eb:SetCursorPosition(eb:GetNumLetters())
  self.logEdit:SetDisabled(true)

  if self.logWindow then
    -- self.logWindow:SetStatusText(("Lines: %s"):format((table.getn(MyrkLogs.logBuffer))))
    self.logWindow:SetStatusText("Logs for the personal addon")
  end
end

function MyrkLogs:Log(msg)
  local line = date("%H:%M:%S") .. "  " .. tostring(msg)
  table.insert(MyrkLogs.logBuffer, line)
  if table.getn(MyrkLogs.logBuffer) > self.maxLines then
    table.remove(MyrkLogs.logBuffer, 1)
  end
  self:RefreshLogText()
end

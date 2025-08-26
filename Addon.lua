MyrkAddon = LibStub("AceAddon-3.0"):NewAddon("MyrkAddon", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")

local initialized = false
function MyrkAddon:OnInitialize()
  if initialized then return end
  initialized = true
  MyrkPriest:Initialize()
  MyrkAddon:RegisterChatCommand("myrk", "Console")

  -- Buggy
  -- self:RegisterComm(MyrkLogs.addonPrefix, "OnCommReceived")
  DEFAULT_CHAT_FRAME:AddMessage("|cff8888ff[MyrkTools]|r Initialized ")
end

function MyrkAddon:Console(input)
  -- normalize input: trim and lowercase the first word
  input = input or ""

  if input == "" or input == "help" then
    self:ShowHelp()
    return
  end

  if input == "logs" or input == "logs reset" then
    if input == "logs reset" then
      -- Reset the logs
      MyrkLogs:Reset()
      self:Print("Logs have been reset.")
    end

    -- `/myrk logs` -> open your log window
    if MyrkLogs and MyrkLogs.CreateLogWindow then
      MyrkLogs:CreateLogWindow()
    else
      self:Print("Logs module not loaded.")
    end
    return
  end

  -- unknown subcommand
  self:Print(string.format("Unknown command: '%s'", input))
  self:ShowHelp()
end

function MyrkAddon:ShowHelp()
  -- AceConsole-3.0 gives you :Print; fallback below if needed
  self:Print("MyrkAddon commands:")
  self:Print("  /myrk logs     - open the log window")
  self:Print("  /myrk help     - show this help")
end
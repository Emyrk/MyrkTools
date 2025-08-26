MyrkAddon = LibStub("AceAddon-3.0"):NewAddon("MyrkAddon", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")

local initialized = false
function MyrkAddon:OnInitialize()
  if initialized then return end
  initialized = true
  MyrkTools:Initialize()
  MyrkPriest:Initialize()
  MyrkAddon:RegisterChatCommand("myrk", "Console")

  -- Buggy
  -- self:RegisterComm(MyrkLogs.addonPrefix, "OnCommReceived")
  DEFAULT_CHAT_FRAME:AddMessage("|cff8888ff[MyrkTools]|r Initialized ")
end
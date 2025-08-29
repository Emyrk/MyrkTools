MyrkAddon = LibStub("AceAddon-3.0"):NewAddon("MyrkAddon", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")

local initialized = false
function MyrkAddon:OnInitialize()
  if initialized then return end
  initialized = true
  MyrkAddon:RegisterChatCommand("myrk", "Console")

  -- Buggy
  -- self:RegisterComm(MyrkLogs.addonPrefix, "OnCommReceived")
  DEFAULT_CHAT_FRAME:AddMessage("|cff8888ff[MyrkTools]|r Initialized")
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

  -- Tank management commands
  if string.match(input, "^tank") then
    self:HandleTankCommand(input)
    return
  end

  -- unknown subcommand
  self:Print(string.format("Unknown command: '%s'", input))
  self:ShowHelp()
end

function MyrkAddon:HandleTankCommand(input)
  local partyMonitor = self:GetModule("MyrkPartyMonitor")
  if not partyMonitor then
    self:Print("PartyMonitor module not loaded.")
    return
  end

  -- Parse tank subcommands
  local command, playerName = string.match(input, "^tank%s+(%S+)%s*(.*)$")
  
  if not command then
    self:Print("Usage: /myrk tank <add|remove|list> [player]")
    return
  end
  
  command = string.lower(command)
  
  if command == "add" then
    if not playerName or playerName == "" then
      self:Print("Usage: /myrk tank add <player>")
      return
    end
    
    local success = partyMonitor:SetRole(playerName, "Tank")
    if success then
      self:Print(string.format("Added %s as Tank", playerName))
    end
    
  elseif command == "remove" or command == "del" then
    if not playerName or playerName == "" then
      self:Print("Usage: /myrk tank remove <player>")
      return
    end
    
    partyMonitor:ClearRole(playerName)
    self:Print(string.format("Removed tank role from %s", playerName))
    
  elseif command == "list" then
    local tanks = partyMonitor:GetTanks()
    if #tanks == 0 then
      self:Print("No tanks configured")
    else
      self:Print("Current tanks:")
      for _, tank in ipairs(tanks) do
        self:Print(string.format("  %s", tank.name))
      end
    end
    
  else
    self:Print(string.format("Unknown tank command: %s", command))
    self:Print("Available: add, remove, list")
  end
end

function MyrkAddon:ShowHelp()
  -- AceConsole-3.0 gives you :Print; fallback below if needed
  self:Print("MyrkAddon commands:")
  self:Print("  /myrk logs           - open the log window")
  self:Print("  /myrk tank add <name> - add a player as tank")
  self:Print("  /myrk tank remove <name> - remove tank role from player")
  self:Print("  /myrk tank list      - list all tanks")
  self:Print("  /myrk help           - show this help")
end
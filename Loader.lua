local now = GetTime();
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkTools]|r Loaded " .. now)

local initialized = false

function MyrkAddon:OnInitialize()
  if initialized then return end
  initialized = true
  MyrkTools:Initialize()
  MyrkLogs:Initialize()
  MyrkPriest:Initialize()
  MyrkAddon:RegisterChatCommand("myrk", "Console")

  self:RegisterComm(MyrkLogs.addonPrefix, "OnCommReceived")
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkTools]|r Initialized " .. now)
end

function MyrkAddon:OnEnable()
  -- Register events
  self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdatePartyMembers")
  self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdatePartyMembers")
end

function MyrkAddon:UpdatePartyMembers()
  -- This can be used for UI updates if needed
  -- The actual communication is handled by AceComm automatically
end

local playerName = UnitName("player")
function MyrkAddon:OnCommReceived(prefix, message, distribution, sender)
    if not MyrkLogs.syncEnabled then return end
  if sender == playerName then
    return
  end

  local level = string.sub(message, 1, 3)
  local msg = string.sub(message, 4)
  
  -- Parse the message (format: "level|timestamp|msg")
  MyrkLogs:Log(level, "[" .. sender .. "]" .. msg, false)
end

function MyrkAddon:Console(input)
  -- normalize input: trim and lowercase the first word
  input = input or ""

  if input == "" or input == "help" then
    self:ShowHelp()
    return
  end

  if input == "logs" then
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

-- function MyrkTools:Test()
--   SendChatMessage("Test", SELF)
--   DEFAULT_CHAT_FRAME:AddMessage("Debug!")
-- end


-- frame:SetScript("OnEvent", function()
--   local eventInfo = { CombatLogGetCurrentEventInfo() }
--   local eventType = eventInfo[2]

--   if eventType == "UNIT_DIED" then
--     local destGUID = eventInfo[8]
--     local destName = eventInfo[9]

--     MyrkTools.killCount = MyrkTools.killCount + 1;
--     DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Mob died:|r " .. (destName or "Unknown") .. " , Total kills: " .. MyrkTools.killCount)
--   end
-- end)

-- -- An afk macro for a rogue to pull and kill mobs automatically.
-- function MyrkTools:RogueAFK()
--   local combat = UnitAffectingCombat("player")
--   local h=UnitHealth("player")
--   local m=UnitHealthMax("player")

--   -- If the player is dead, there is nothing to do. Maybe logout?
--   if UnitIsDeadOrGhost("player") then
--     RogueAFKDead(); -- Handle dead state
--     return
--   end

--   MyrkTools.dead = false;

--   -- Do nothing if the player is not ready for combat
--   if h/m < 0.9 and not combat then
--     if not buffed("Stealth") then
--       CastSpellByName("Stealth")
--     end
--     return
--   end

--   if combat then
--     RogueCombat() -- Handle combat logic
--     return;
--   else
--     RoguePull() -- Handle pulling logic
--   end
-- end


-- function RogueAFKDead()
--   if(MyrkTools.dead) then -- Not tested
--     if(now - MyrkTools.deadTime > 300) then
--       DEFAULT_CHAT_FRAME:AddMessage("You are dead for too long, logging out." .. now)
--       Logout()
--     end
--     return;
--   end


--   MyrkTools.dead = true;
--   MyrkTools.deadTime = GetTime();
-- end


-- MyrkTools.pullTick = 0;
-- function RoguePull()
--   if(math.fmod(MyrkTools.pullTick, 5) == 0) then
--     ClearTarget() -- Try a new target
--   end
--   TargetNearestEnemy()
--   CastSpellByName("Shoot Bow")
--   MyrkTools.pullTick = MyrkTools.pullTick + 1;
-- end

-- function RogueCombat()
--   local h=UnitHealth("player")
--   local m=UnitHealthMax("player")

--   if UnitExists("target") and UnitCanAttack("player", "target") and UnitName("targettarget") ~= UnitName("player") then
--     ClearTarget()
--   end

--   -- If we have no target, find one
--   if not UnitExists("target") then
--     TargetNearestEnemy()
--   end

--   if h/m < 0.5 then
--     CastSpellByName("Evasion")
--     return;
--   end

--   local c=GetComboPoints()
--   if c==5 then
--     CastSpellByName("Eviscerate")
--   elseif CheckInteractDistance("target",3) then
--     CastSpellByName("Sinister Strike")
--   else
--     CastSpellByName("Shoot Bow")
--   end
-- end

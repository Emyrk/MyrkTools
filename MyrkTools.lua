DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkTools]|r Loaded " .. now)
local now = GetTime();

MyrkTools = {
  dead = false,
  deadTime = 0,
  killCount = 0,
}

function MyrkTools:Test()
  SendChatMessage("Test", SELF)
  DEFAULT_CHAT_FRAME:AddMessage("Debug!")
end


frame:SetScript("OnEvent", function()
  local eventInfo = { CombatLogGetCurrentEventInfo() }
  local eventType = eventInfo[2]

  if eventType == "UNIT_DIED" then
    local destGUID = eventInfo[8]
    local destName = eventInfo[9]

    MyrkTools.killCount = MyrkTools.killCount + 1;
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Mob died:|r " .. (destName or "Unknown") .. " , Total kills: " .. MyrkTools.killCount)
  end
end)

-- An afk macro for a rogue to pull and kill mobs automatically.
function MyrkTools:RogueAFK()
  local combat = UnitAffectingCombat("player")
  local h=UnitHealth("player")
  local m=UnitHealthMax("player")

  -- If the player is dead, there is nothing to do. Maybe logout?
  if UnitIsDeadOrGhost("player") then
    RogueAFKDead(); -- Handle dead state
    return
  end

  MyrkTools.dead = false;

  -- Do nothing if the player is not ready for combat
  if h/m < 0.9 and not combat then
    if not buffed("Stealth") then
      CastSpellByName("Stealth") 
    end
    return
  end

  if combat then
    RogueCombat() -- Handle combat logic
    return;
  else
    RoguePull() -- Handle pulling logic
  end
end


function RogueAFKDead() 
  if(MyrkTools.dead) then -- Not tested
    if(now - MyrkTools.deadTime > 300) then
      DEFAULT_CHAT_FRAME:AddMessage("You are dead for too long, logging out." .. now)
      Logout()
    end
    return;
  end


  MyrkTools.dead = true;
  MyrkTools.deadTime = GetTime();
end


MyrkTools.pullTick = 0;
function RoguePull()
  if(math.fmod(MyrkTools.pullTick, 5) == 0) then
    ClearTarget() -- Try a new target
  end
  TargetNearestEnemy() 
  CastSpellByName("Shoot Bow")
  MyrkTools.pullTick = MyrkTools.pullTick + 1;
end

function RogueCombat() 
  local h=UnitHealth("player")
  local m=UnitHealthMax("player")

  if UnitExists("target") and UnitCanAttack("player", "target") and UnitName("targettarget") ~= UnitName("player") then
    ClearTarget()
  end

  -- If we have no target, find one
  if not UnitExists("target") then
    TargetNearestEnemy()
  end

  if h/m < 0.5 then
    CastSpellByName("Evasion")
    return;
  end

  local c=GetComboPoints()
  if c==5 then
    CastSpellByName("Eviscerate")
  elseif CheckInteractDistance("target",3) then
    CastSpellByName("Sinister Strike")
  else
    CastSpellByName("Shoot Bow")
  end
end
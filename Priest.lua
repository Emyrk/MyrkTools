MyrkPriest = {
  WandSlot = 0,
  IsPriest = false
}

MyrkPriest.manaThreshold = 0.95

function MyrkPriest:Initialize()
  local localizedClass, englishClass = UnitClass("player")
  if englishClass ~= "PRIEST" then
    return
  end
  MyrkPriest.IsPriest = true

  -- We need to find the wand on our action bars to detect if we are wanding already.
  for slot = 1, 120 do
    local _, _, id = GetActionText(slot)
    if id == 5019 then
      MyrkPriest.WandSlot = slot
      DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkTools]|r Wand slot found = " .. slot)
      break
    end
  end
  --

  -- MyrkAddon:RegisterChatCommand("mm", "SafeQuickHeal")
end

-- Priest is the function to automate priest functionality.
-- It will decide when to heal or attack based on various conditions.
function MyrkPriest:Priest()
  if not MyrkPriest.IsPriest then
    MyrkPriest:Info("Not a priest, aborting priest behavior")
    return
  end

  -- Always attempt to throw a heal first.
  -- If someone in the party needs healing, this will keep them alive!
  -- TODO: Hots? Power Word Shield?
  --   1. When moving, cast HOTs instead of trying to cast a channeled ability
  --   2. When should we Power Word Shield?
  local busy, resp = QHExport.BusyQuickHeal()
  if busy then
    MyrkPriest:Debug("Quick healing is busy")
    return
  end

  if resp and resp.targeting and resp.targeting.castable ~= nil and not resp.targeting.castable then
    local hotBusy, _ = QHExport.BusyQuickHOT()
    if hotBusy then
      MyrkPriest:Info("Quick hot healing")
      return
    end
  end

  local targetName, _ = UnitName("target")
  local targetHealth = UnitHealth("target") / UnitHealthMax("target")
  local targetInfo = "Target = ??"
  if targetName ~= "" and targetName ~= nil and targetHealth ~= nil then
    targetInfo = string.format("Target: %s|%.0f%%", targetName, targetHealth * 100)
  end

  if not InCombat() then
    MyrkPriest:Debug(string.format("Not in combat, will not attack"))
    return
  end

  -- Healing has been covered, so now consider offensive abilities.
  if not HostileTarget() then
    -- Do not even try to attack non-hostile targets.
    MyrkPriest:Debug(string.format("%s is not a hostile target, skipping attack", targetInfo))
    return
  end

  -- TODO: Dots?
  local m = UnitMana("player") / UnitManaMax("player");
  if m > MyrkPriest.manaThreshold then
    local smiting = MyrkPriest:Smite()
    if smiting then
      return
    end
  end

  local wanding = MyrkPriest:Wand()
  if wanding then
    MyrkPriest:Info(string.format("Wanding %s", targetInfo))
    return
  end
end

-- Smite will only cast if we have enough mana reserved for healing.
function MyrkPriest:Smite()
  CastSpellByName("Smite");
  return false
end

-- Wand will use our wand as the offensive ability.
function MyrkPriest:Wand()
  if Wanding() then
    -- If we are already shooting, do not cast "Shoot" again.
    -- It would cancel the auto-shot.
    MyrkPriest:Debug("Already shooting", 1, 1, 0)
    return true
  end

  -- This starts the auto-shooting
  CastSpellByName("Shoot");
  MyrkPriest:Debug("Shoot", 1, 1, 0)
  return true
end

function Wanding()
  if MyrkPriest.WandSlot == 0 then
    -- If wand is not on the bars, that is an issue.
    -- TODO: Throw an error.
    return false
  end

  if IsAutoRepeatAction(MyrkPriest.WandSlot) == 1 then
    return true
  end

  return false
end

-- Convenience wrappers
function MyrkPriest:Debug(msg)
  MyrkLogs:Debug(string.format("PST: %s", msg))
end

function MyrkPriest:Info(msg)
  MyrkLogs:Info(string.format("PST: %s", msg))
end

function MyrkPriest:Warn(msg)
  MyrkLogs:Warn(string.format("PST: %s", msg))
end

function MyrkPriest:Error(msg)
  MyrkLogs:Error(string.format("PST: %s", msg))
end

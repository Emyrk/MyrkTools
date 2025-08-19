MyrkPriest = {
  WandSlot = 0,
  IsPriest = false
}

MyrkPriest.manaThreshold = 0.60

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
    AutoMyrk:Info("Not a priest", 1, 1, 0)
    return
  end

  -- Always attempt to throw a heal first.
  -- If someone in the party needs healing, this will keep them alive!
  -- TODO: Hots? Power Word Shield?
  --   1. When moving, cast HOTs instead of trying to cast a channeled ability
  --   2. When should we Power Word Shield?
  local busy = QHExport.BusyQuickHeal()
  if busy then
    AutoMyrk:Info("Quickheal", 1, 1, 0)
    return
  end

  if not InCombat() then
    AutoMyrk:Info("Not in combat", 1, 1, 0)
    return
  end

  -- Healing has been covered, so now consider offensive abilities.
  if not HostileTarget() then
    -- Do not even try to attack non-hostile targets.
    AutoMyrk:Info("Not a hostile target ", 1, 1, 0)
    return
  end

  local wanding = MyrkPriest:Wand()
  if wanding then
    return
  end

  -- TODO: Dots?
  local smiting = MyrkPriest:Smite()
  if smiting then
    return
  end
end

-- Smite will only cast if we have enough mana reserved for healing.
function MyrkPriest:Smite()
  local m = UnitMana("player") / UnitManaMax("player");
  if m > MyrkPriest.manaThreshold then
    CastSpellByName("Smite");
    AutoMyrk:Info("Smite ", 1, 1, 0)
    return true
  end

  CastSpellByName("Shoot");
  AutoMyrk:Info("Not enough mana ", 1, 1, 0)
  return false
end

-- Wand will use our wand as the offensive ability.
function MyrkPriest:Wand()
  if Wanding() then
    -- If we are already shooting, do not cast "Shoot" again.
    -- It would cancel the auto-shot.
    AutoMyrk:Info("Already shooting", 1, 1, 0)
    return true
  end

  -- This starts the auto-shooting
  CastSpellByName("Shoot");
  AutoMyrk:Info("Shoot", 1, 1, 0)
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

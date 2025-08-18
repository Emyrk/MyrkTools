MyrkPriest = {
  WandSlot = 0
}

MyrkPriest.manaThreshold = 0.60

function MyrkPriest:PriestOffense()
  local busy = QHExport.BusyQuickHeal()
  if busy then
    AutoMyrk:Warn("Quickheal", 1, 1, 0)
    return
  end

  if not HostileTarget() then
    AutoMyrk:Warn("Not a hostile target ", 1, 1, 0)
    -- UIErrorsFrame:AddMessage("Not a hostile target.",1,0.2,0.2); 
    return
  end

  -- Start Attack if low on mana/shoot
  -- If moving cast hot

  local attacking = MyrkPriest:Attack()
  if attacking then
    return
  end
end

function MyrkPriest:Attack()
  local m=UnitMana("player")/UnitManaMax("player");
  if m>MyrkPriest.manaThreshold then 
    -- CastSpellByName("Smite"); 
     CastSpellByName("Shoot"); 
    AutoMyrk:Warn("Smite ", 1, 1, 0)
    return true
  else 
    CastSpellByName("Shoot"); 
    AutoMyrk:Warn("Not enough mana ", 1, 1, 0)
    return false
  end
  return false
end


function MyrkPriest:QuickHeal()
  if SlashCmdList.QUICKHEAL then
    return SlashCmdList.QUICKHEAL("")
  end
  return false
end

function MyrkPriest:Wand()
  if MyrkPriest.WandSlot == 0 then
    return false
  end
  if IsAutoRepeatAction(MyrkPriest.WandSlot) then
    print("Already shooting")
    return true
  end
  CastSpellByName("Shoot"); 
  return true
end

function MyrkPriest:Initialize()
  for slot = 1, 120 do
    local _, _, id = GetActionText(slot)
    if id == 5019 then
      MyrkPriest.WandSlot = slot
      DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkTools]|r Wand slot found = " .. slot)
      break
    end
  end
end
MyrkPriest = {
}

MyrkPriest.manaThreshold = 0.60

function MyrkPriest:PriestOffense()
  local busy = QHExport.BusyQuickHeal()
  if busy then
    AutoMyrk:Warn("Quickheal busy " .. BoolToString(busy), 1, 1, 0)
    return
  end

  if not HostileTarget() then
    AutoMyrk:Warn("Not a hostile target ", 1, 1, 0)
    -- UIErrorsFrame:AddMessage("Not a hostile target.",1,0.2,0.2); 
    return
  end

  -- Start Attack if low on mana/shoot
  -- If moving cast hot

  local m=UnitMana("player")/UnitManaMax("player");
  if m>MyrkPriest.manaThreshold then 
    CastSpellByName("Smite"); 
    AutoMyrk:Warn("Smite ", 1, 1, 0)
  else 
    AutoMyrk:Warn("Not enough mana ", 1, 1, 0)
  end
end


function MyrkPriest:QuickHeal()
  if SlashCmdList.QUICKHEAL then
    return SlashCmdList.QUICKHEAL("")
  end
  return false
end
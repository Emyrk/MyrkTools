function InitPriestTable()
  local localizedClass, englishClass = UnitClass("player")
  if englishClass ~= "PRIEST" then
    return
  end

  

end

function LoadSpellRanks(spellName)
  local ranks = {}
  local i = 1

  while true do
    local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then
      break
    end

    if name == spellName then
      local info = TheoryCraft_GetSpellDataByName(spellName, i)
      table.insert(ranks, info)
    end
    i = i + 1
  end

  return ranks
end

PriestHeals = {}
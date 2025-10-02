-- spellname string
-- spellrank number
-- spellnumber number
-- manacost number
-- TODO: Make these local
local ShamanHeals = {}
local ShamanSingleHeals = {}

function GetShamanSingleHeals()
  return ShamanSingleHeals
end

local initializedShamanTable = false
function InitShamanTable(force)
  if initializedShamanTable and not force then
    return ShamanHeals, ShamanSingleHeals
  end
  initializedShamanTable = true

  ShamanHeals = {}
  ShamanSingleHeals = {}

  local localizedClass, englishClass = UnitClass("player")
  if englishClass ~= "SHAMAN" then
    Logs.Error("InitShamanTable called for non-shaman class " .. tostring(englishClass))
    return
  end

  local spells = {
    "Healing Wave",
  }

  for _, spellName in ipairs(spells) do
    ShamanHeals[spellName] = LoadSpellRanks(spellName)
  end

  local singleHeals = {
    "Healing Wave",
  }

  -- For each spell in the single heals, load all the ranks into ShamanSingleHeals
  for _, spellName in ipairs(singleHeals) do
    for _, spellRank in ipairs(ShamanHeals[spellName]) do
      table.insert(ShamanSingleHeals, spellRank)
    end
  end

  table.sort(ShamanSingleHeals, function(a, b) 
    return a.averagehealnocrit < b.averagehealnocrit
  end)
  
  -- for _, spell in ipairs(ShamanSingleHeals) do
  --   Logs.Debug(spell.spellname .. " rank " .. tostring(spell.spellrank) .. " heal " .. tostring(math.floor(spell.averagehealnocrit)))
  -- end
  return ShamanHeals, ShamanSingleHeals
end

function PrintShamanTable()
  InitShamanTable()
  for spellName, ranks in pairs(ShamanHeals) do
    Logs.Debug("Spell: " .. spellName)
    for _, rank in ipairs(ranks) do
      Logs.Debug(string.format("  Rank %d: id=%d mana=%d heal=%d", rank.spellrank, rank.spellnumber, rank.manacost, math.floor(rank.averagehealnocrit)))
    end
  end

  Logs.Debug("Single heals:")
  for _, spell in ipairs(ShamanSingleHeals) do
    Logs.Debug(spell.spellname .. " rank " .. tostring(spell.spellrank) .. " heal " .. tostring(math.floor(spell.averagehealnocrit)) .. "with mana " .. tostring(spell.manacost))
  end
end

---@param pct number Health percentage threshold to consider
---@param ttd number|nil Time to death threshold in seconds, or nil to ignore
---@param prevent function|nil Function(engine, player) that returns true if we should prevent this heal
---@param incDmgTime number|nil Time in seconds to consider incoming damage when calculating heal amount
function ShamanDynamicHeal(pct, ttd, prevent, incDmgTime)
  return function(engine, player)
    InitShamanTable()

    if not engine.ctx.channelHeal then
      return nil -- Cannot channel, so nothing to do
    end
  
    local playerPct = player:GetHealthPercent()
    if playerPct > pct then
      return nil -- Player ok, no heal needed
    end

    local playerTTD = player:CalculateTimeToDeath()
    if ttd ~= nil and playerTTD > ttd then
      return nil -- Player not in immediate danger
    end

    if prevent and prevent(engine, player) then
      return nil -- Prevented by custom logic
    end

    local hp_needed = player:HPNeeded(incDmgTime or 0)
    return BestShamanSingleHeal(player.id, UnitMana("player"), hp_needed)
  end
end


BestShamanSingleHeal = BestSingleHeal(InitShamanTable)
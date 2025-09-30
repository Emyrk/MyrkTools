-- spellname string
-- spellrank number
-- spellnumber number
-- manacost number
-- TODO: Make these local
local PriestSpells = {}
local PriestSingleHeals = {}

function GetPriestSingleHeals()
  return PriestSingleHeals
end

local initializedPriestTable = false
function InitPriestTable(force)
  if initializedPriestTable and not force then
    return
  end
  initializedPriestTable = true

  PriestSpells = {}
  PriestSingleHeals = {}
  
  local localizedClass, englishClass = UnitClass("player")
  if englishClass ~= "PRIEST" then
    Logs.Error("InitPriestTable called for non-priest class " .. tostring(englishClass))
    return
  end

  local spells = {
    "Lesser Heal",
    "Flash Heal",
    "Heal",
    "Prayer of Healing",
    "Renew",
  }

  for _, spellName in ipairs(spells) do
    PriestSpells[spellName] = LoadSpellRanks(spellName)
  end

  local singleHeals = {
    "Lesser Heal",
    "Heal",
  }

  -- For each spell in the single heals, load all the ranks into PriestSingleHeals
  for _, spellName in ipairs(singleHeals) do
    for _, spellRank in ipairs(PriestSpells[spellName]) do
      table.insert(PriestSingleHeals, spellRank)
    end
  end

  table.sort(PriestSingleHeals, function(a, b) 
    return a.averagehealnocrit < b.averagehealnocrit
  end)

  -- for _, spell in ipairs(PriestSingleHeals) do
  --   Logs.Debug(spell.spellname .. " rank " .. tostring(spell.spellrank) .. " heal " .. tostring(math.floor(spell.averagehealnocrit)))
  -- end
end

function PrintPriestTable()
  InitPriestTable()
  for spellName, ranks in pairs(PriestSpells) do
    Logs.Debug("Spell: " .. spellName)
    for _, rank in ipairs(ranks) do
      Logs.Debug(string.format("  Rank %d: id=%d mana=%d heal=%d", rank.spellrank, rank.spellnumber, rank.manacost, math.floor(rank.averagehealnocrit)))
    end
  end

  Logs.Debug("Single heals:")
  for _, spell in ipairs(PriestSingleHeals) do
    Logs.Debug(spell.spellname .. " rank " .. tostring(spell.spellrank) .. " heal " .. tostring(math.floor(spell.averagehealnocrit)) .. "with mana " .. tostring(spell.manacost))
  end
end

function LoadSpellRanks(spellName)
  local ranks = {}
  local i = 1

  while true do
    local info = TheoryCraft_GetSpellDataByName(spellName, i)
    if info == nil then
      break
    end

    if info.spellname == nil then
      break
    end
    table.insert(ranks, info)
    i = i + 1
  end

  return ranks
end

---@param pct number Health percentage threshold to consider
---@param ttd number|nil Time to death threshold in seconds, or nil to ignore
---@param prevent function|nil Function(engine, player) that returns true if we should prevent this heal
---@param incDmgTime number|nil Time in seconds to consider incoming damage when calculating heal amount
function PriestDynamicHeal(pct, ttd, prevent, incDmgTime)
  return function(engine, player)
    InitPriestTable()

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
    return BestPriestSingleHeal(player.id, UnitMana("player"), hp_needed)
  end
end

---@param table table List of healing spells sorted by averagehealnocrit ascending
---@param reloadTable function(force:boolean) Function to initialize the table if needed
---@return function(pid: string, mana: number, hp_needed: number): Action|nil
function BestSingleHeal(table, reloadTable)
  return function(pid, mana, hp_needed)
    reloadTable(false)
    local healingSpell = nil
    for _, spell in ipairs(table) do
      healingSpell = spell

      if not spell.manacost then
        -- Debug log this error
        reloadTable(true)
        Logs.Error(string.format("SingleHeals=%d", table.getn(table)))
        Logs.Error("No manacost for spell " .. tostring(spell.spellname) .. " rank " .. tostring(spell.spellrank))
        healingSpell = nil
        break
      end
      if (spell.manacost or 0) > mana then
        -- Can't afford this spell, will use a lower rank
        break
      end

      if spell.averagehealnocrit >= hp_needed then
        break
      end
    end

    if healingSpell == nil then
      return nil -- No heal found
    end

    return Action:Heal(
      SpellIndex[healingSpell.spellname][healingSpell.spellrank],
      pid,
      -- "dynamic heal",
      string.format("dynamic %s %d", healingSpell.spellname, healingSpell.spellrank)
    )
  end 
end

BestPriestSingleHeal = BestSingleHeal(PriestSingleHeals, InitPriestTable)
---@class SpellData
---@field spellname string
---@field spellrank number
---@field spellnumber number
---@field manacost number

---@class HealTable
---@field Spells table<string, table<number, SpellData>> spellName -> rank -> spellData
---@field SingleHeals table<HealSpell>
---@field FastHeals table<HealSpell> Flash heal and other quicker casts
---@field SpellIndex table<string, table<number, number>> spellName -> rank -> spellID
HealTable = MyrkAddon:NewModule("MyrkHealTable", "AceEvent-3.0")
HealTable.loaded = false

function HealTable:OnEnable()
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkHealTable]|r Loaded")

  -- spellname string
  -- spellrank number
  -- spellnumber number
  -- manacost number
  -- TODO: Make these local
  self.Spells = {}
  self.SingleHeals = {}
  self.SpellIndex = {}
  self.FastHeals = {}
end

--- @return number|nil spellID
function HealTable:RankID(spellName, rank)
  self:Load(false)
  local ranks = self.SpellIndex[spellName]
  if ranks == nil or ranks[rank] == nil then
    return nil
  end
  return ranks[rank]
end


--- @return SpellData|nil
function HealTable:MaxRankID(spellName)
  self:Load(false)
  local ranks = self.SpellIndex[spellName]
  if ranks == nil or table.getn(ranks) == 0 then
    return nil, nil
  end
  return ranks[table.getn(ranks)], table.getn(ranks)
end

function HealTable:RankData(spellName, rank)
  self:Load(false)
  local ranks = self.Spells[spellName]
  if ranks == nil or ranks[rank] == nil then
    return nil
  end
  return ranks[rank]
end


--- @return SpellData|nil
function HealTable:MaxRankData(spellName)
  self:Load(false)
  local ranks = self.Spells[spellName]
  if ranks == nil or table.getn(ranks) == 0 then
    return nil
  end
  return ranks[table.getn(ranks)]
end

function HealTable:Load(force)
  if self.loaded and not force then
    return 
  end

  self:Unload() -- Clear any existing data

  local spells = {}
  local single = {}
  local fast = {}

  local localizedClass, englishClass = UnitClass("player")
  if englishClass == "PRIEST" then
    spells = {
      "Flash Heal",
      "Heal",
      "Greater Heal",
      "Prayer of Healing",
      "Renew",
      "Power Word: Shield",
      "Smite",
      "Mind Blast",
      "Fade",
      "Psychic Scream",
      "Champion's Grace",
      "Inner Focus",
    }

    single = {
      "Greater Heal",
      "Heal",
    }

    fast = {
      "Flash Heal",
    }
  elseif englishClass == "SHAMAN" then
    spells = {
      "Healing Wave",
      "Lesser Healing Wave",
    }

    single = {
      "Healing Wave",
      -- "Lesser Healing Wave",
    }

    fast = {
      "Lesser Healing Wave",
    }

  else
    spells = {}
    single = {}
    fast = {}
  end

  local all, index, partial, quick = self:ReloadSpells(spells, single, fast)
  self.Spells = all
  self.SpellIndex = index
  self.SingleHeals = partial
  self.FastHeals = quick
  self.loaded = true
  Logs.Debug(string.format("Reloaded %d Single heals", table.getn(partial)))
end

function HealTable:Unload()
  self.Spells = {}
  self.SingleHeals = {}
  self.SpellIndex = {}
  self.FastHeals = {}
  self.loaded = false
end

function HealTable:ReloadSpells(all, single, fast)
  local spells = {}
  local index = {}
  for _, spellName in ipairs(all) do
    spells[spellName] = LoadSpellRanks(spellName)
    index[spellName] = GetSpellIDs(spellName)
  end

  local singles = {}
  for _, spellName in ipairs(single) do
    for _, spellRank in ipairs(spells[spellName]) do
      table.insert(singles, spellRank)
    end
  end

  table.sort(singles, function(a, b) 
    return a.averageheal < b.averageheal
  end)

  local quickList = {}
  for _, spellName in ipairs(fast) do
    for _, spellRank in ipairs(spells[spellName]) do
      table.insert(quickList, spellRank)
    end
  end

  table.sort(quickList, function(a, b) 
    return a.averageheal < b.averageheal
  end)
  
  return spells, index, singles, quickList
end

function HealTable:Print()
  self:Load(false)
  for spellName, ranks in pairs(self.Spells) do
    Logs.Debug("Spell: " .. spellName)
    for _, rank in ipairs(ranks) do
      if rank.manacost == nil then
        Logs.Error("No manacost for spell " .. tostring(spellName) .. " rank " .. tostring(rank.spellrank))
      else
        Logs.Debug(string.format("  Rank %d: id=%d mana=%d heal=%d", rank.spellrank, rank.spellnumber, rank.manacost, math.floor(rank.averageheal or 0)))
      end
    end
  end

  Logs.Debug("Single heals:")
  for _, spell in ipairs(self.SingleHeals) do
    Logs.Debug(spell.spellname .. " rank " .. tostring(spell.spellrank) .. " heal " .. tostring(math.floor(spell.averageheal)) .. "with mana " .. tostring(spell.manacost))
  end
end
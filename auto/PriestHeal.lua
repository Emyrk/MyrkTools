-- spellname string
-- spellrank number
-- spellnumber number
-- manacost number

function LoadSpellRanks(spellName)
  local ranks = {}
  local i = 1

  while true do
    local tcinfo = TheoryCraft_GetSpellDataByName(spellName, i)
    if tcinfo == nil then
      break
    end

    if tcinfo.spellname == nil then
      break
    end
    table.insert(ranks, {
      spellname = tcinfo.spellname,
      spellrank = tcinfo.spellrank,
      manacost = tcinfo.manacost,
      spellnumber = tcinfo.spellnumber,
      averagehealnocrit = tcinfo.averagehealnocrit
    })
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
    if not engine.ctx.channelHeal then
      return nil -- Cannot channel, so nothing to do
    end

    if not player.castable then
      return nil -- Cannot cast on this player
    end

    if not player.healable then
      return nil -- Cannot cast on this player
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

---@return function(pid: string, mana: number, hp_needed: number): Action|nil
function BestSingleHeal()
  return function(pid, mana, hp_needed)
    HealTable:Load(false)

    local healingSpell = nil
    for _, spell in ipairs(HealTable.SingleHeals) do
      healingSpell = spell

      if not spell.manacost then
        -- Debug log this error
        HealTable:Load(true)
        Logs.Error(string.format("SingleHeals=%d", table.getn(HealTable.SingleHeals)))
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
      HealTable.SpellIndex[healingSpell.spellname][healingSpell.spellrank],
      pid,
      -- "dynamic heal",
      string.format("dynamic %s %d", healingSpell.spellname, healingSpell.spellrank)
    )
  end 
end

BestPriestSingleHeal = BestSingleHeal()
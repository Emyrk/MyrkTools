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
      tcinfo = ManualLookup(spellName, i)
    end

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

---@param ptype string "player", "tank", or "party"
---@param pct number Health percentage threshold to consider
---@param ttd number|nil Time to death threshold in seconds, or nil to ignore
---@param prevent function|nil Function(engine, player) that returns true if we should prevent this heal
---@param incDmgTime number|nil Time in seconds to consider incoming damage when calculating heal amount
function PriestDynamicHeal(ptype, pct, ttd, prevent, incDmgTime)
  return PerPlayer(ptype, function(engine, player)
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

    DebugExecution(string.format("PriestDynamicHeal: considering heal for %s pct=%.2f ttd=%.2f", player.id, playerPct, playerTTD))
    local hp_needed = player:HPNeeded(incDmgTime or 0)
    return BestSingleHeal(player.id, UnitMana("player"), hp_needed)
  end)
end

---@return Action|nil
function BestSingleHeal(pid, mana, hp_needed)
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


function PriestChampion()
  local step = PerPlayer("party", function(engine, player)
    if not player.castable then
      return nil
    end

    if not player.healable then
      return nil
    end

    if not engine:hasBuff(player.id, "Spell_Holy_ProclaimChampion_02") then
      return nil
    end

    if engine:hasBuff(player.id, "Spell_Holy_ChampionsGrace") then
      return nil
    end

    return Action:Cast(
      HealTable:MaxRankID("Champion's Grace"),
      player.id,
      "priest_champions_grace"
    )
  end)

  return function(engine) 
    -- Not enough mana
    if UnitMana("player") < 250 then
      return nil
    end

    return engine:evaluateStep(step)
  end
end


function CastInnerFocus(engine)
  local spellID = HealTable:MaxRankID("Inner Focus")
  local _, duration = GetSpellCooldown(spellID, BOOKTYPE_SPELL)
  if duration ~= 0 then
    return nil -- Spell is on cooldown
  end

  CastSpell(spellID, BOOKTYPE_SPELL)
  return nil
end

function CastBestSingleHealMouseover()
  if Auto.engine:IsGlobalCasting() or Auto.engine:IsMonitoredCasting() then
    return nil
  end

  local ok, id = UnitExists("mouseover")
  if not ok then
    -- Cast on self
    id = "player"
  end

  if not UnitIsHealable(id) then  
    return nil
  end

  local mana = UnitMana("player")
  local hp = UnitHealth(id)
  local hpmax = UnitHealthMax(id)
  local hp_needed = hpmax - hp
  local recentDmg = DamageComm.UnitGetIncomingDamage(UnitName(id)) or 0
  print("Incoming damage for " .. UnitName(id) .. ": " .. tostring(recentDmg))

  local incDamage = recentDmg / 2 -- Over 2.5s

  local action = BestSingleHeal(id, mana, hp_needed + incDamage)
  if action == nil then
    return nil
  end

  Auto.engine:ExecuteHeal(action)
end
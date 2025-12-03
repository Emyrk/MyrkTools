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
    return BestSingleHeal(player.id, UnitMana("player"), hp_needed, false)
  end)
end

---@return table|nil The selected healing spell with spellname, spellrank, manacost, averagehealnocrit
function GetBestSingleHealSpell(pid, mana, hp_needed, fast)
  HealTable:Load(false)

  local healingSpell = nil
  local list = HealTable.SingleHeals
  if fast then
    list = HealTable.FastHeals
  end

  for _, spell in ipairs(list) do
    healingSpell = spell

    if not spell.manacost then
      -- Debug log this error
      HealTable:Load(true)
      Logs.Error(string.format("SingleHeals=%d", table.getn(list)))
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

  return healingSpell
end

---@return Action|nil
function BestSingleHeal(pid, mana, hp_needed, fast)
  local healingSpell = GetBestSingleHealSpell(pid, mana, hp_needed, fast)

  if healingSpell == nil then
    return nil -- No heal found
  end

  return Action:Heal(
    HealTable.SpellIndex[healingSpell.spellname][healingSpell.spellrank],
    pid,
    -- "dynamic heal",
    string.format("fast=%s, dynamic %s %d", tostring(fast), healingSpell.spellname, healingSpell.spellrank)
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

    if engine:hasBuff(player.id, function(icon, id) 
      return id == 45563 or id == 45564 or id == 45565 or id == 45570
    end) then
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

function CastBestSingleHealTarget(id, fast)
  if Auto.engine:IsGlobalCasting() or Auto.engine:IsMonitoredCasting() then
    return nil
  end

  local ok, guid = UnitExists(id)
  if not ok then
    UIErrorsFrame:AddMessage(string.format("%s does not exists", tostring(id)), 1, 0, 0)
    return nil
  end

  if not UnitIsHealable(guid) then  
    local name = UnitName(guid) or tostring(guid)
    UIErrorsFrame:AddMessage(string.format("%s is not healable", name), 1, 0, 0)
    return nil
  end

  local mana = UnitMana("player")
  local hp = UnitHealth(guid)
  local hpmax = UnitHealthMax(guid)
  local hp_needed = hpmax - hp
  local recentDmg = DamageComm.UnitGetIncomingDamage(UnitName(guid)) or 0
  -- print("Incoming damage for " .. UnitName(guid) .. ": " .. tostring(recentDmg))

  local incDamage = recentDmg / 2 -- Over 2.5s

  -- Get the spell info for the popup
  local healingSpell = GetBestSingleHealSpell(guid, mana, hp_needed + incDamage, fast)
  if healingSpell == nil then
    return nil
  end

  local action = Action:Heal(
    HealTable.SpellIndex[healingSpell.spellname][healingSpell.spellrank],
    guid,
    -- "dynamic heal",
    string.format("fast=%s, dynamic %s %d", tostring(fast), healingSpell.spellname, healingSpell.spellrank)
  )
  if healingSpell and HealPopup then
    HealPopup:Show(
      UnitName(guid),
      healingSpell.spellname,
      healingSpell.spellrank,
      healingSpell.averagehealnocrit,
      recentDmg,
      hp_needed
    )
  end

  Auto.engine:ExecuteHeal(action)
end
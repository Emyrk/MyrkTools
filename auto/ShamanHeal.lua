-- function PrintShamanTable()
--   InitShamanTable()
--   for spellName, ranks in pairs(ShamanHeals) do
--     Logs.Debug("Spell: " .. spellName)
--     for _, rank in ipairs(ranks) do
--       Logs.Debug(string.format("  Rank %d: id=%d mana=%d heal=%d", rank.spellrank, rank.spellnumber, rank.manacost, math.floor(rank.averagehealnocrit)))
--     end
--   end

--   Logs.Debug("Single heals:")
--   for _, spell in ipairs(ShamanSingleHeals) do
--     Logs.Debug(spell.spellname .. " rank " .. tostring(spell.spellrank) .. " heal " .. tostring(math.floor(spell.averagehealnocrit)) .. "with mana " .. tostring(spell.manacost))
--   end
-- end

---@param ptype string "player", "tank", or "party"
---@param pct number Health percentage threshold to consider
---@param ttd number|nil Time to death threshold in seconds, or nil to ignore
---@param prevent function|nil Function(engine, player) that returns true if we should prevent this heal
---@param incDmgTime number|nil Time in seconds to consider incoming damage when calculating heal amount
function ShamanDynamicHeal(ptype, pct, ttd, prevent, incDmgTime)
  return PerPlayer(ptype, function(engine, player)
    if not player.castable then
      return nil -- Cannot cast on this player
    end

    if not player.healable then
      return nil -- Cannot cast on this player
    end

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
    local action = BestSingleHeal(player.id, UnitMana("player"), hp_needed)
    return action
  end)
end
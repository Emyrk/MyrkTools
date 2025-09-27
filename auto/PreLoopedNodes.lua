function PowerWordShield(pct, ttd)
   return HealSpell:new({
        spellName = "Power Word: Shield",
        instant = true,
        pct = pct,
        spellRank = 4,
        minimumMana = 175,
        prevent = function(engine, player)
            local cant = engine:hasBuff(player.id, "Spell_Holy_PowerWordShield") or
                   engine:hasDebuff(player.id, "AshesToAshes")
            if cant then
                return true
            end

            if ttd then
                return player:CalculateTimeToDeath() > ttd;
            end

            return false
        end
    })
end

-- Emergency flash heal for specific target type
---@param pct number Health percentage threshold to consider
---@param ttd number Time to death threshold in seconds
function FlashHeal(pct, ttd)
   return HealSpell:new({
        spellName = "Flash Heal",
        instant = false,
        smartRank = true,
        incDmgTime = 2,
        minimumMana = 125,
        pct = pct,
        prevent = function(engine, player)
            return player:CalculateTimeToDeath() > ttd;
        end
    })
end
---@param ptype string "player", "tank", or "party"
---@param pct any
---@param ttd any
function PowerWordShield(ptype, pct, ttd)
   return HealSpell:new({
        playerType = ptype,
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
---@param ttd number|nil Time to death threshold in seconds
function FlashHeal(ptype, pct, ttd)
   return HealSpell:new({
        playerType = ptype,
        spellName = "Flash Heal",
        instant = false,
        smartRank = true,
        incDmgTime = 2,
        minimumMana = 125,
        pct = pct,
        prevent = function(engine, player)
            if ttd == nil then
                return false
            end
            return player:CalculateTimeToDeath() > ttd;
        end
    })
end

-- SpiritFlashHeal assumes all healing is free.
function SpiritFlashHeal(engine)
    if not engine:hasBuff("player", "Spell_Holy_GreaterHeal") then
        return nil -- No free healing, ignore
    end

    local action = nil
    engine:ForEach("party", function(player)
        if not player.castable or not player.healable then
            return false
        end

        local spellID = HealTable:MaxRankID("Flash Heal") 
        action = Action:Heal(spellID, player.id, "spam free flash heals")
        return true
    end)

    return action
end
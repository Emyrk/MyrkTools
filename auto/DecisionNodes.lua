-- DecisionNodes.lua
-- Individual decision node functions for the healing decision tree

-- Busy will allow whatever action was previously decided on to finish before
-- continuing. So if the previous decision is to cast a spell, this will
-- wait for that cast to finish.
function Busy()
    return function(engine)
        if engine.busy then
            return Action:Busy("engine is busy")
        end

        -- TODO: Spell monitoring setup for busy tracking. Match QuickHeal

    end
end

function IsDead(engine)
    if UnitIsDead("player") then
        return Action:Busy("player is dead")
    end
    return nil
end

function PlayerIsDrinking(engine)
    if IsDrinking() then
        return Action:Busy("player is drinking")
    end
    return nil
end

function Mounted()
    return function(engine)
        if engine:hasBuff("player", "inv_pet_speedy") then
            return Action:Busy("player is mounted")
        end
        return nil
    end
end


-- function CancelOverHeal()
--     return function(engine)
--         if not engine.busy then
--             return nil
--         end

--         -- Detect overheal somehow and do 'SpellStopCasting()'
--         return nil
--     end
-- end

-- Quick exit if already casting
function AlreadyCasting(engine)
    if engine:isAlreadyCasting() then
        local currentCast = engine:GetCurrentCast()
        local reason = "already_casting"
        
        if currentCast then
            reason = string.format("already_casting_%s_to_%s", 
                currentCast.spell or "unknown", 
                currentCast.target or "unknown")
        end
        
        return Action:Busy(reason)
    end
    return nil
end

function RefreshPartyState(engine)
    if not engine.partyMonitor then
        return nil
    end
    
    engine.partyMonitor:UpdatePartyMembers()
    return nil -- This is a state modifier, not an action
end
function CastableHeal(channel, instant)

    local castable = function(engine)
        if not engine.partyMonitor then
            return Action:Error("No party monitor")
        end
        
        CastSpellByName(channel) -- Lesser Heal
        engine.ctx.channelHeal = true
        engine.ctx.instantHeal = true


        if not SpellIsTargeting() then
            engine.ctx.instantHeal = true
            engine.ctx.channelHeal = false
            CastSpellByName(instant)

            if not SpellIsTargeting() then
                engine.ctx.instantHeal = false
                SpellStopTargeting()
                return Action:Error("SpellIsTargeting failed")
            end
        end

        -- Annotate party members with who is castable 
        ---@param player AllyPlayer
        engine.partyMonitor:ForEach(function(player)
            local healable = UnitIsHealable(player.id)
            player.healable = healable -- set player state
            if not healable then
                -- End of player state, nothing more to do
                return
            end

            if SpellCanTargetUnit(player.id) then
                player.castable = true
            else
                player.castable = false
            end
            
        end)

        SpellStopTargeting();
        return nil
    end
    return RetainTarget(WithAutoSelfCastOff(castable))
end

-- Emergency shield for specific target type
function EmergencyShield(targetType, pct, ttd)
   return HealSpell:new({
        spellName = "Power Word: Shield",
        targetType = targetType,
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
---@param targetType string "player", "tank", "party"
---@param pct number Health percentage threshold to consider
---@param ttd number Time to death threshold in seconds
function EmergencyFlashHeal(targetType, pct, ttd)
   return HealSpell:new({
        spellName = "Flash Heal",
        targetType = targetType,
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

---@param targetType string "player", "tank", "party"
---@param pct number Health percentage threshold to consider
function LesserHeal(targetType, pct)
   return HealSpell:new({
        spellName = "Lesser Heal",
        targetType = targetType,
        instant = false,
        smartRank = true,
        incDmgTime = 0,
        minimumMana = 25,
        pct = pct,
        prevent = function(engine, player)
            -- Don't use lesser heal if we need a bigger heal
            if player:HPNeeded(3) > 150 then
                return true
            end
            return false
        end
    })
end

---@param targetType string "player", "tank", "party"
---@param pct number Health percentage threshold to consider
function Priest_Heal(targetType, pct)
   return HealSpell:new({
        spellName = "Heal",
        targetType = targetType,
        instant = false,
        smartRank = true,
        incDmgTime = 2.25,
        minimumMana = 135,
        pct = pct,
        prevent = function(engine, player)
            return false
        end
    })
end


function Renew(targetType, pct)
   return HealSpell:new({
        spellName = "Renew",
        targetType = targetType,
        instant = true,
        pct = pct,
        prevent = function(engine, unitId)
            return engine:hasBuff(unitId, "Renew")
        end
    })
end


-- Only execute if not in an instance
function NotInstance(actionFunc)
    return function(engine)
        if IsInInstance() then
            return nil -- Skip if in instance
        end
        
        return actionFunc(engine)
    end
end

function NotCombat(actionFunc)
    return function(engine)
        if InCombat() then
            return nil -- Skip if in combat
        end
        
        return actionFunc(engine)
    end
end

-- Smite action for when nothing else to do
function Smite()
    return function(engine)
        -- Only smite if we have a hostile target
        if UnitExists("target") and UnitCanAttack("player", "target") then
            return {
                action = "cast",
                spell = "Smite",
                target = "target",
                reason = "idle_smite"
            }
        end
        return nil
    end
end

function EvaluateSteps(engine, ...)
    local nodes = arg
    for _, node in ipairs(nodes) do
        local result = engine:evaluateStep(node)
        if result then
            return result -- First successful decision wins
        end
    end
    return nil -- No decision made
end

-- Setup/Teardown wrapper for decision nodes
-- Executes setup before evaluating nodes, teardown after (regardless of success/failure)
function WithSetup(setupFunc, teardownFunc, ...)
    local nodes = arg
    
    return function(engine)
        local setupResult = nil
        
        -- Execute setup function
        if setupFunc then
            setupResult = setupFunc(engine)
        end
        
        -- Evaluate the wrapped decision nodes
        local result = EvaluateSteps(engine, unpack(nodes))
        -- for _, node in ipairs(nodes) do
        --     result = engine:evaluateStep(node)
        --     if result then
        --         break -- First successful decision wins
        --     end
        -- end
        
        -- Always execute teardown, passing setup result for context
        if teardownFunc then
            teardownFunc(engine, setupResult)
        end
        
        return result
    end
end

-- Helper function to create CVar setup/teardown functions
function CVarSetup(cvarName, newValue, oldValue)
    return function(engine)
        if not oldValue then
            oldValue = GetCVar(cvarName)
        end
        SetCVar(cvarName, newValue)
        return {cvar = cvarName, oldValue = oldValue}
    end
end

function CVarTeardown()
    return function(engine, setupResult)
        if setupResult and setupResult.cvar and setupResult.oldValue then
            SetCVar(setupResult.cvar, setupResult.oldValue)
        end
    end
end

-- Convenience function for autoSelfCast management
function WithAutoSelfCastOff(...)
    local nodes = arg
    return WithSetup(
        CVarSetup("autoSelfCast", 0, 1),
        CVarTeardown(),
        unpack(nodes)
    )
end

-- Generic CVar wrapper
function WithCVar(cvarName, value, ...)
    local nodes = arg
    return WithSetup(
        CVarSetup(cvarName, value),
        CVarTeardown(),
        unpack(nodes)
    )
end

function RetainTarget(...)
    local nodes = arg
    return WithSetup(
        function(engine)
            if UnitIsHealable('target') then
                ClearTarget();
                return true
            end

            return false
        end,
        function(engine, cleared)
            if cleared then
                TargetLastTarget();
            end
        end,
        unpack(nodes)
    )
end
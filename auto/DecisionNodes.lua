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
            
        end, "time_to_death")

        SpellStopTargeting();
        return nil
    end
    return RetainTarget(WithAutoSelfCastOff(castable))
end

-- Emergency shield for specific target type
function EmergencyShield(targetType, pct)
   return HealSpell:new({
        spellName = "Power Word: Shield",
        targetType = targetType,
        instant = true,
        pct = pct,
        prevent = function(engine, unitId)
            return engine:hasBuff(unitId, "Spell_Holy_PowerWordShield") or
                   engine:hasDebuff(unitId, "AshesToAshes")
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

-- -- Self preservation at threshold
-- function SelfPreservation(threshold)
--     return function(engine)
--         local healthPct = engine:getHealthPercent("player")
--         if healthPct < (threshold / 100) then
--             -- Use Flash Heal for emergency self-healing
--             return {
--                 action = "cast",
--                 spell = "Flash Heal",
--                 target = "player",
--                 reason = "self_preservation"
--             }
--         end
--         return nil
--     end
-- end

-- -- Emergency flash heal with time prediction
-- function EmergencyFlash(timeThreshold, targetType)
--     return function(engine)
--         local targets = {}
        
--         if targetType == "tank" then
--             targets = engine:resolveTanks() -- Now returns all tanks
--         elseif targetType == "tanks" then
--             targets = engine:resolveTanks()
--         elseif targetType == "healers" then
--             targets = engine:resolveHealers()
--         elseif targetType == "dps" then
--             targets = engine:resolveDPS()
--         elseif targetType == "party" then
--             targets = engine:resolveParty()
--         end
        
--         for _, unitId in ipairs(targets) do
--             if engine:willDieIn(unitId, timeThreshold) then
--                 return {
--                     action = "cast",
--                     spell = "Flash Heal",
--                     target = unitId,
--                     reason = "emergency_flash"
--                 }
--             end
--         end
        
--         return nil
--     end
-- end

-- -- Emergency heal with time prediction (slower but more efficient)
-- function EmergencyHeal(timeThreshold, targetType)
--     return function(engine)
--         local targets = {}
        
--         if targetType == "tank" then
--             targets = engine:resolveTanks() -- Now returns all tanks
--         elseif targetType == "tanks" then
--             targets = engine:resolveTanks()
--         elseif targetType == "healers" then
--             targets = engine:resolveHealers()
--         elseif targetType == "dps" then
--             targets = engine:resolveDPS()
--         elseif targetType == "party" then
--             targets = engine:resolveParty()
--         end
        
--         for _, unitId in ipairs(targets) do
--             if engine:willDieIn(unitId, timeThreshold) then
--                 return {
--                     action = "cast",
--                     spell = "Heal", -- Or "Greater Heal" depending on need
--                     target = unitId,
--                     reason = "emergency_heal"
--                 }
--             end
--         end
        
--         return nil
--     end
-- end

-- -- Regular healing at health threshold
-- function Heal(threshold, targetType)
--     return function(engine)
--         local targets = {}
        
--         if targetType == "tank" then
--             targets = engine:resolveTanks() -- Now returns all tanks
--         elseif targetType == "tanks" then
--             targets = engine:resolveTanks()
--         elseif targetType == "healers" then
--             targets = engine:resolveHealers()
--         elseif targetType == "dps" then
--             targets = engine:resolveDPS()
--         elseif targetType == "party" then
--             targets = engine:resolveParty()
--         end
        
--         for _, unitId in ipairs(targets) do
--             local healthPct = engine:getHealthPercent(unitId)
--             if healthPct < (threshold / 100) then
--                 return {
--                     action = "cast",
--                     spell = "Heal",
--                     target = unitId,
--                     reason = "regular_heal"
--                 }
--             end
--         end
        
--         return nil
--     end
-- end

-- -- Priority-based healing (heals lowest health first)
-- function PriorityHeal(threshold, targetType)
--     return function(engine)
--         local targets = {}
        
--         if targetType == "tank" then
--             targets = engine:resolveTanks() -- Now returns all tanks
--         elseif targetType == "tanks" then
--             targets = engine:resolveTanks()
--         elseif targetType == "healers" then
--             targets = engine:resolveHealers()
--         elseif targetType == "dps" then
--             targets = engine:resolveDPS()
--         elseif targetType == "party" then
--             targets = engine:resolveParty()
--         end
        
--         local lowestHealth = 1.0
--         local lowestTarget = nil
        
--         for _, unitId in ipairs(targets) do
--             local healthPct = engine:getHealthPercent(unitId)
--             if healthPct < (threshold / 100) and healthPct < lowestHealth then
--                 lowestHealth = healthPct
--                 lowestTarget = unitId
--             end
--         end
        
--         if lowestTarget then
--             return {
--                 action = "cast",
--                 spell = "Heal",
--                 target = lowestTarget,
--                 reason = "priority_heal"
--             }
--         end
        
--         return nil
--     end
-- end

-- Only execute if not in an instance
function NotInstance(actionFunc)
    return function(engine)
        if IsInInstance() then
            return nil -- Skip if in instance
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

-- Wand action for when nothing else to do
function Wand()
    return function(engine)
        -- Only wand if we have a hostile target
        if UnitExists("target") and UnitCanAttack("player", "target") then
            return {
                action = "cast",
                spell = "Shoot", -- Wand attack
                target = "target",
                reason = "idle_wand"
            }
        end
        return nil
    end
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
        local result = nil
        for _, node in ipairs(nodes) do
            result = engine:evaluateStep(node)
            if result then
                break -- First successful decision wins
            end
        end
        
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
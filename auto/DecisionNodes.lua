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

function CancelOverHeal()
    return function(engine)
        if not engine.busy then
            return nil
        end

        -- Detect overheal somehow and do 'SpellStopCasting()'
        return nil
    end
end

-- Quick exit if already casting
function AlreadyCasting()
    return function(engine)
        if engine:isAlreadyCasting() then
            local currentCast = engine:GetCurrentCast()
            local reason = "already_casting"
            
            if currentCast then
                reason = string.format("already_casting_%s_to_%s", 
                    currentCast.spell or "unknown", 
                    currentCast.target or "unknown")
            end
            
            return { action = "skip", reason = reason }
        end
        return nil
    end
end

-- Annotate party members with spell reachability
-- This is a state modifier, not an action
function Castable(...)
    -- local spells = {...}
    return function(engine)
        -- TODO: Check spell range, mana cost, etc. for each party member
        -- For now, this is a placeholder that always succeeds
        -- In a full implementation, this would mark which party members
        -- are in range for each spell and store in party state
        return nil -- This is a state modifier, not an action
    end
end

-- Emergency shield for specific target type
function EmergencyShield(targetType)
    return function(engine)
        local targets = {}
        
        if targetType == "player" then
            targets = {"player"}
        elseif targetType == "tank" then
            targets = engine:resolveTanks() -- Now returns all tanks
        elseif targetType == "tanks" then
            targets = engine:resolveTanks()
        elseif targetType == "healers" then
            targets = engine:resolveHealers()
        elseif targetType == "dps" then
            targets = engine:resolveDPS()
        elseif targetType == "party" then
            targets = engine:resolveParty()
        end
        
        for _, unitId in ipairs(targets) do
            local healthPct = engine:getHealthPercent(unitId)
            if healthPct < engine.config.emergencyThreshold then
                -- Check if shield is available and not already on target
                if not engine:hasBuff(unitId, "Power Word: Shield") then
                    return {
                        action = "cast",
                        spell = "Power Word: Shield",
                        target = unitId,
                        reason = "emergency_shield"
                    }
                end
            end
        end
        
        return nil
    end
end

-- Self preservation at threshold
function SelfPreservation(threshold)
    return function(engine)
        local healthPct = engine:getHealthPercent("player")
        if healthPct < (threshold / 100) then
            -- Use Flash Heal for emergency self-healing
            return {
                action = "cast",
                spell = "Flash Heal",
                target = "player",
                reason = "self_preservation"
            }
        end
        return nil
    end
end

-- Emergency flash heal with time prediction
function EmergencyFlash(timeThreshold, targetType)
    return function(engine)
        local targets = {}
        
        if targetType == "tank" then
            targets = engine:resolveTanks() -- Now returns all tanks
        elseif targetType == "tanks" then
            targets = engine:resolveTanks()
        elseif targetType == "healers" then
            targets = engine:resolveHealers()
        elseif targetType == "dps" then
            targets = engine:resolveDPS()
        elseif targetType == "party" then
            targets = engine:resolveParty()
        end
        
        for _, unitId in ipairs(targets) do
            if engine:willDieIn(unitId, timeThreshold) then
                return {
                    action = "cast",
                    spell = "Flash Heal",
                    target = unitId,
                    reason = "emergency_flash"
                }
            end
        end
        
        return nil
    end
end

-- Emergency heal with time prediction (slower but more efficient)
function EmergencyHeal(timeThreshold, targetType)
    return function(engine)
        local targets = {}
        
        if targetType == "tank" then
            targets = engine:resolveTanks() -- Now returns all tanks
        elseif targetType == "tanks" then
            targets = engine:resolveTanks()
        elseif targetType == "healers" then
            targets = engine:resolveHealers()
        elseif targetType == "dps" then
            targets = engine:resolveDPS()
        elseif targetType == "party" then
            targets = engine:resolveParty()
        end
        
        for _, unitId in ipairs(targets) do
            if engine:willDieIn(unitId, timeThreshold) then
                return {
                    action = "cast",
                    spell = "Heal", -- Or "Greater Heal" depending on need
                    target = unitId,
                    reason = "emergency_heal"
                }
            end
        end
        
        return nil
    end
end

-- Regular healing at health threshold
function Heal(threshold, targetType)
    return function(engine)
        local targets = {}
        
        if targetType == "tank" then
            targets = engine:resolveTanks() -- Now returns all tanks
        elseif targetType == "tanks" then
            targets = engine:resolveTanks()
        elseif targetType == "healers" then
            targets = engine:resolveHealers()
        elseif targetType == "dps" then
            targets = engine:resolveDPS()
        elseif targetType == "party" then
            targets = engine:resolveParty()
        end
        
        for _, unitId in ipairs(targets) do
            local healthPct = engine:getHealthPercent(unitId)
            if healthPct < (threshold / 100) then
                return {
                    action = "cast",
                    spell = "Heal",
                    target = unitId,
                    reason = "regular_heal"
                }
            end
        end
        
        return nil
    end
end

-- Priority-based healing (heals lowest health first)
function PriorityHeal(threshold, targetType)
    return function(engine)
        local targets = {}
        
        if targetType == "tank" then
            targets = engine:resolveTanks() -- Now returns all tanks
        elseif targetType == "tanks" then
            targets = engine:resolveTanks()
        elseif targetType == "healers" then
            targets = engine:resolveHealers()
        elseif targetType == "dps" then
            targets = engine:resolveDPS()
        elseif targetType == "party" then
            targets = engine:resolveParty()
        end
        
        local lowestHealth = 1.0
        local lowestTarget = nil
        
        for _, unitId in ipairs(targets) do
            local healthPct = engine:getHealthPercent(unitId)
            if healthPct < (threshold / 100) and healthPct < lowestHealth then
                lowestHealth = healthPct
                lowestTarget = unitId
            end
        end
        
        if lowestTarget then
            return {
                action = "cast",
                spell = "Heal",
                target = lowestTarget,
                reason = "priority_heal"
            }
        end
        
        return nil
    end
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
            result = engine:evaluateDecision(node)
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
function CVarSetup(cvarName, newValue)
    return function(engine)
        local oldValue = GetCVar(cvarName)
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
    return WithCVar("autoSelfCast", "0", unpack(nodes))
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
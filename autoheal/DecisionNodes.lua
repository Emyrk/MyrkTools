-- DecisionNodes.lua
-- Individual decision node functions for the healing decision tree

-- Quick exit if already casting
function AlreadyCasting()
    return function(engine)
        if engine:isAlreadyCasting() then
            return { action = "skip", reason = "already_casting" }
        end
        return nil
    end
end

-- Annotate party members with spell reachability
-- This is a state modifier, not an action
function Castable(...)
    local spells = {...}
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
            local tank = engine:resolveTank()
            targets = tank and {tank} or {}
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
            local tank = engine:resolveTank()
            targets = tank and {tank} or {}
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
            local tank = engine:resolveTank()
            targets = tank and {tank} or {}
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
            local tank = engine:resolveTank()
            targets = tank and {tank} or {}
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
            local tank = engine:resolveTank()
            targets = tank and {tank} or {}
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
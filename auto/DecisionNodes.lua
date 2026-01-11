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

function IsGhostWolf()
    return function(engine)
        if engine:hasBuff("player", "Spell_Nature_SpiritWolf") then
            return Action:Busy("player is ghost wolf")
        end
        return nil
    end
end

function Mounted()
    return function(engine)
        if engine:hasBuff("player", "inv_pet_speedy") then
            return Action:Busy("player is mounted")
        end
        if engine:hasBuff("player", "INV_Misc_Branch_01") then
            return Action:Busy("player is mounted")
        end
        return nil
    end
end

-- Quick exit if already casting
function AlreadyCasting(engine)
    if engine:IsMonitoredCasting() then
        local currentCast = engine:GetCurrentCast()
        local reason = "already_casting"
        
        if currentCast then
            reason = string.format("already_casting_%s_to_%s", 
                currentCast.spell or "unknown", 
                currentCast.target or "unknown")
        end
        
        return Action:Busy(reason)
    end

    if engine:IsGlobalCasting() then
        return Action:Busy("global_casting")
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
            if instant ~= nil then
                CastSpellByName(instant)
                if not SpellIsTargeting() then
                    engine.ctx.instantHeal = false
                    SpellStopTargeting()
                    SpellStopCasting()
                    return Action:Error("SpellIsTargeting failed")
                end
            else
                engine.ctx.instantHeal = false
                SpellStopTargeting()
                SpellStopCasting()
                return Action:Error("SpellIsTargeting failed, are you moving?")
            end
        end

        DebugExecution(string.format("CastableHeal: channel=%s instant=%s", tostring(engine.ctx.instantHeal), tostring(engine.ctx.instantHeal)))
        
        engine.ctx.minimumHealthPct = 1.0
        engine.ctx.minimumTTD = 1000
        
        -- Annotate party members with who is castable 
        ---@param player AllyPlayer
        engine.partyMonitor:ForEach(function(player)
            -- TODO: Move min hp and min ttd checks to here
            local healable = UnitIsHealable(player.id)
            player.castable = false
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

            if player.castable and player.healable then
                local pct = player:GetHealthPercent()

                if pct > 0 and pct < engine.ctx.minimumHealthPct then
                    engine.ctx.minimumHealthPct = pct
                end

                local ttd = player:CalculateTimeToDeath()
                if ttd and ttd > 0 and ttd < engine.ctx.minimumTTD then
                    engine.ctx.minimumTTD = ttd
                end
            end

            DebugExecution(string.format("HealableParty: %s:%s castable=%s healable=%s",player.id, player.name, tostring(player.castable), tostring(player.healable)))
        end)

        SpellStopTargeting();
        return nil
    end

    return RetainTarget(WithAutoSelfCastOff(castable))
end

-- Only execute if not in an instance
function NotInstance(actionFunc)
    return function(engine)
        if IsInInstance() then
            return nil -- Skip if in instance
        end

        return engine:evaluateStep(actionFunc)        
    end
end

function OnlyInCombat(step)
    return function(engine)
        if not InCombat() then
            return nil -- Skip if not in combat
        end
        
        return engine:evaluateStep(step)
    end
end

function OnlyNotCombat(step)
    return function(engine, player)
        if InCombat() then
            return nil -- Skip if in combat
        end
        
        return engine:evaluateStep(step)
    end
end

---@param ptype string "player", "tank", or "party"
---@param step fun(engine:DecisionEngine, player: AllyPlayer): Action|nil
function PerPlayer(ptype, step) 
    return function(engine)
        local result = nil
        engine:ForEach(ptype, function(player)
            result = step(engine, player)
            if result then
                return true -- Stop iteration on first result
            end
            return false
        end)

        return result
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

function HealFocus(pct)
    return function(engine)
        if not pfUI or not pfUI.uf or not pfUI.uf.focus then
            return nil
        end

        local focusID = pfUI.uf.focus.label .. pfUI.uf.focus.id
        if not UnitExists(focusID) then
            return nil
        end

        if UnitInParty(focusID) then
            return nil
        end

        local hp = UnitHealth(focusID)
        local hpMax = UnitHealthMax(focusID)
        local hpPct = hp / hpMax
        if hpPct > pct then
            return nil
        end


        return BestSingleHeal(focusID, UnitMana("player"), hpMax - hp, false)
    end
end

---@param overPct number Percentage of hp to cancel a heal at
function CancelOverheal(overPct)
    ---@param engine DecisionEngine
    return function(engine)
        local cm = engine:CastMonitor()
        local cast = cm:GetCurrentCast()
        if not cast then
            return nil
        end
        if not cast.isHeal then
            return nil
        end

        local hp = UnitHealth(cast.target)
        local hpMax = UnitHealthMax(cast.target)
        local hpPct = hp / hpMax
        if hpPct >= overPct then
            local spell = cast.spell or "unknown"
            Logs.Info(string.format("CancelOverheal: Cancelling heal %s to %s at %.2f%% (over %.2f%%)", tostring(spell), tostring(cast.target), hpPct * 100, overPct * 100))
            SpellStopCasting()
            return Action:Busy("Cancelled overheal")
        end

        -- Detect overheal somehow and do 'SpellStopCasting()'
        return nil
    end
end

function RogueRota(engine) 
    return Action:Custom(function()
        RogueRota:Rota()
    end, "RogueRota")
end

function WarriorRota(engine) 
    return Action:Custom(function()
        if UnitIsHealable("target") then
            ClearTarget()
        end

        if not HostileTarget() then
            TargetNearestEnemy()
            return nil
        end

        IWin:DoShit()
    end, "WarriorRota")
end
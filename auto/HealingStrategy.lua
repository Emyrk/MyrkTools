-- HealingStrategy.lua
-- The complete healing decision tree strategy

-- This is the main healing strategy decision tree
-- Decisions are evaluated in order, first match wins
HealingStrategy = {
    -- Quick exit if we're already doing something
    AlreadyCasting(),
    
    -- Annotate party members with who is reachable
    Castable("Lesser Heal", "Renew"),
    
    -- Save yourself first - emergency situations
    -- Use WithAutoSelfCastOff to ensure shields target others properly
    WithAutoSelfCastOff(
        EmergencyShield("player"),
        SelfPreservation(20) -- If less than 20%, we need to be saved
    ),
    
    -- Tank emergency situations with autoSelfCast disabled
    WithAutoSelfCastOff(
        EmergencyShield("tank"),
        EmergencyFlash(3, "tank"), -- If tank expected to die in <3s, flash heal
        EmergencyHeal(5, "tank") -- Tank takes priority if they are about to die in 5s
    ),
    
    -- Party emergency situations
    WithAutoSelfCastOff(
        EmergencyShield("party"),
        EmergencyFlash(3, "party"), -- If someone might die in 3s
        EmergencyHeal(5, "party") -- If someone might die in 5s
    ),
    
    -- Regular healing priorities
    Heal(50, "tank"), -- 50% or less, focus the tank
    PriorityHeal(85, "party"), -- 85% or less, heal the party (includes tank with higher priority)
    
    -- Idle actions when everyone is healthy
    NotInstance(Smite()), -- Don't waste mana in an instance
    Wand(),
}

-- Examples of WithSetup usage:
--
-- 1. Basic setup/teardown with custom functions:
-- WithSetup(
--     function(engine) 
--         -- Setup: save current state
--         return {oldTarget = UnitName("target")}
--     end,
--     function(engine, setupResult)
--         -- Teardown: restore state
--         if setupResult.oldTarget then
--             TargetByName(setupResult.oldTarget)
--         end
--     end,
--     SomeDecisionNode(),
--     AnotherDecisionNode()
-- )
--
-- 2. CVar management (autoSelfCast example):
-- WithAutoSelfCastOff(
--     EmergencyShield("tank"),
--     EmergencyShield("party")
-- )
--
-- 3. Generic CVar wrapper:
-- WithCVar("autoSelfCast", "0",
--     EmergencyShield("tank")
-- )
--
-- 4. Multiple CVars:
-- WithSetup(
--     function(engine)
--         local oldAutoSelf = GetCVar("autoSelfCast")
--         local oldAssist = GetCVar("assistAttack")
--         SetCVar("autoSelfCast", "0")
--         SetCVar("assistAttack", "1")
--         return {autoSelf = oldAutoSelf, assist = oldAssist}
--     end,
--     function(engine, setupResult)
--         SetCVar("autoSelfCast", setupResult.autoSelf)
--         SetCVar("assistAttack", setupResult.assist)
--     end,
--     YourDecisionNodes()
-- )
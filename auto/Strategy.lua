RogueStrategy = {
    RefreshPartyState,
}

PriestStrategy = {
    Debounce:New(0.5),
    -- Quick exit if we're already doing something
    AlreadyCasting,

    -- Calc incoming dmg, heals, etc
    RefreshPartyState,

    -- See if we can cast anything
    CastableHeal("Lesser Heal(Rank 1)", "Renew(Rank 1)"),

    -- Save yourself first - emergency situations
    EmergencyShield("player", 0.15),
    EmergencyShield("tank", 0.15),
    EmergencyShield("party", 0.15),
    Renew("party", 1.1),
}

-- This is the main healing strategy decision tree
-- Decisions are evaluated in order, first match wins
-- DefaultHealingStrategy = {
--     -- Quick exit if we're already doing something
--     AlreadyCasting,

--     -- TODO: WithPreserveTarget() to save/restore target after healing?
    
--     -- Must set autoSelfCast to "off" for detection
--     WithAutoSelfCastOff(
--         -- Annotate party members with who is reachable
--         Castable("Lesser Heal", "Renew")
--     ),
    
--     -- Save yourself first - emergency situations
--     EmergencyShield("player"),
--     SelfPreservation(20), -- If less than 20%, we need to be saved
    
--     -- Tank emergency situations
--     EmergencyShield("tank"),
--     EmergencyFlash(3, "tank"), -- If tank expected to die in <3s, flash heal
--     EmergencyHeal(5, "tank"), -- Tank takes priority if they are about to die in 5s
    
--     -- Party emergency situations
--     EmergencyShield("party"),
--     EmergencyFlash(3, "party"), -- If someone might die in 3s
--     EmergencyHeal(5, "party"), -- If someone might die in 5s
    
--     -- Regular healing priorities
--     Heal(50, "tank"), -- 50% or less, focus the tank
--     PriorityHeal(85, "party"), -- 85% or less, heal the party (includes tank with higher priority)
    
--     -- Idle actions when everyone is healthy
--     NotInstance(Smite()), -- Don't waste mana in an instance
--     Wand(),
-- }

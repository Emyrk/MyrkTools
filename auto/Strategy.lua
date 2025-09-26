RogueStrategy = {
    IsDead,
    RefreshPartyState,
}

PriestStrategy = {
    Debounce:New(0.5),

    IsDead,
    PlayerIsDrinking,
    Mounted(),
    -- Quick exit if we're already doing something
    AlreadyCasting,

    -- Calc incoming dmg, heals, etc
    RefreshPartyState,

    -- TODO: If spell targeting, reset it.
    -- See if we can cast anything
    CastableHeal("Lesser Heal(Rank 1)", "Renew(Rank 1)"),

    -- TODO: If spirit of redemption, use max rank flash heals
    -- TODO: Check enough mana on all spells.

    -- Save yourself first - emergency situations
    EmergencyShield("player", 0.15), 
    EmergencyShield("tank", 0.15),
    EmergencyShield("party", 0.15),

    -- Using time to death (ttd) and pct to determine if we should cast
    EmergencyShield("player", 0.50, 2),
    EmergencyShield("tank", 0.50, 2),
    EmergencyShield("party", 0.50, 2),

    -- EmergencyFlashHeal uses ttd and pct to determine if we should cast
    EmergencyFlashHeal("tank", 0.75, 3.5),
    EmergencyFlashHeal("party", 0.75, 3.5),

    -- Dispel Magic on party members

    -- Regular healing priorities
    -- Any top ups
    LesserHeal("tank", 0.85),

    -- Always heal the tank first
    -- TODO: Downrank a heal if we don't need a big heal to a lesser heal
    Priest_Heal("tank", 0.85),
    Priest_Heal("party", 0.85),

    LesserHeal("party", 0.90),


    -- Renew("party", 0.1),
    Wanding:New(),
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

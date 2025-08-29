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
    EmergencyShield("player"),
    SelfPreservation(20), -- If less than 20%, we need to be saved
    
    -- Tank emergency situations
    EmergencyShield("tank"),
    EmergencyFlash(3, "tank"), -- If tank expected to die in <3s, flash heal
    EmergencyHeal(5, "tank"), -- Tank takes priority if they are about to die in 5s
    
    -- Party emergency situations
    EmergencyShield("party"),
    EmergencyFlash(3, "party"), -- If someone might die in 3s
    EmergencyHeal(5, "party"), -- If someone might die in 5s
    
    -- Regular healing priorities
    Heal(50, "tank"), -- 50% or less, focus the tank
    PriorityHeal(85, "party"), -- 85% or less, heal the party (includes tank with higher priority)
    
    -- Idle actions when everyone is healthy
    NotInstance(Smite()), -- Don't waste mana in an instance
    Wand(),
}

-- Alternative strategies can be defined here
-- For example, a more conservative strategy:
ConservativeStrategy = {
    AlreadyCasting(),
    Castable("Lesser Heal", "Renew"),
    
    -- More conservative thresholds
    EmergencyShield("player"),
    SelfPreservation(30), -- Higher self-preservation threshold
    
    EmergencyShield("tank"),
    EmergencyFlash(2, "tank"), -- Shorter emergency window
    
    EmergencyShield("party"),
    EmergencyFlash(2, "party"),
    
    -- More conservative healing thresholds
    Heal(70, "tank"), -- Heal tank at 70%
    PriorityHeal(90, "party"), -- Heal party at 90%
}

-- Aggressive strategy for high-damage situations
AggressiveStrategy = {
    AlreadyCasting(),
    Castable("Flash Heal", "Heal", "Renew"),
    
    -- Lower emergency thresholds
    EmergencyShield("player"),
    SelfPreservation(15),
    
    EmergencyShield("tank"),
    EmergencyFlash(4, "tank"), -- Longer prediction window
    EmergencyHeal(6, "tank"),
    
    EmergencyShield("party"),
    EmergencyFlash(4, "party"),
    EmergencyHeal(6, "party"),
    
    -- Lower healing thresholds
    Heal(40, "tank"),
    PriorityHeal(75, "party"),
    
    -- No idle actions - focus on healing
}

-- Function to switch strategies
function SetHealingStrategy(strategyName)
    if strategyName == "conservative" then
        HealingStrategy = ConservativeStrategy
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Auto]|r Strategy set to Conservative")
    elseif strategyName == "aggressive" then
        HealingStrategy = AggressiveStrategy
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Auto]|r Strategy set to Aggressive")
    else
        -- Reset to default
        HealingStrategy = {
            AlreadyCasting(),
            Castable("Lesser Heal", "Renew"),
            EmergencyShield("player"),
            SelfPreservation(20),
            EmergencyShield("tank"),
            EmergencyFlash(3, "tank"),
            EmergencyHeal(5, "tank"),
            EmergencyShield("party"),
            EmergencyFlash(3, "party"),
            EmergencyHeal(5, "party"),
            Heal(50, "tank"),
            PriorityHeal(85, "party"),
            NotInstance(Smite()),
            Wand(),
        }
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Auto]|r Strategy set to Default")
    end
end
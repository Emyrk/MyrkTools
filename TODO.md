Need:
- Spell monitor
- Check for error message and blacklist a member who is LoS or out of range

```lua
-- This is a decision tree
doFirst({
    -- AlreadyCasting is a quick exit if we are already
    -- doing something.
    AlreadyCasting,
    -- Castable just annotates the party members with who is reachable
    Castable(Lesser Heal, Renew),

    -- Save yourself first
    EmergencyShield("player"),
    -- If less than 20%, we need to be saved.
    SelfPreservation(20),

    -- Will save the tank if they are about to die.
    EmergencyShield("tank"),
    -- If the tank is expected to die in <3s, flash heal
    EmergencyFlash(3, "tank"),
    -- Tank takes priority if they are about to die in 5s
    EmergencyHeal(5, "tank"),


    -- If someone in the party might die.
    EmergencyShield("party"),
    EmergencyFlash(3, "party"), -- 3s
    EmergencyHeal(5, "tank"), -- 5s

    -- Emergencys are over, heal the tank first, then the party.
    Heal(50, "tank"), -- 50% or less, we will focus the tank
    -- Party has priorities set, and the tank has a higher prio. So this covers the tank too.
    PriorityHeal(85, "party"), -- 85% or less, heal the party. 

    -- Everyone is ok?! Sweet! Let's do something fun then.
    NotInstance(Smite), -- Don't waste mana in an instance
    Wand,
})  
```
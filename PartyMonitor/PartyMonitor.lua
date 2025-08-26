-- PartyMonitor keeps track of all the current members of our party including ourselves.
-- We want to keep track of the incoming damage to each member. This will allow us to calculate
-- the damage against them, and predict how much damage they will take in the future.
-- This will all be used to predict healing.
PartyMonitor = MyrkAddon:NewModule("MyrkPartyMonitor")

function PartyMonitor:OnEnable()
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkPartyMonitor]|r Loaded")
end
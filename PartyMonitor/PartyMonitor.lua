-- PartyMonitor keeps track of all the current members of our party including ourselves.
-- We want to keep track of the incoming damage to each member. This will allow us to calculate
-- the damage against them, and predict how much damage they will take in the future.
-- This will all be used to predict healing.
PartyMonitor = MyrkAddon:NewModule("MyrkPartyMonitor")
PartyMonitor.party = Party:New()

function PartyMonitor:OnEnable()
  self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdatePartyMembers")
  self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdatePartyMembers")

  self:UpdatePartyMembers()
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkPartyMonitor]|r Loaded")
end

function PartyMonitor:UpdatePartyMembers()
  -- Reload the party members
  self.party.Refresh()
end

local MAJOR_VERSION = "PartyMonitor-1.0"
local MINOR_VERSION = "$Revision: 0 $"
AceLibrary:Register(PartyMonitor.party, MAJOR_VERSION, MINOR_VERSION)
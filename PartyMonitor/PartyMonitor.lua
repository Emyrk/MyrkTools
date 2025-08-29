-- PartyMonitor keeps track of all the current members of our party including ourselves.
-- We want to keep track of the incoming damage to each member. This will allow us to calculate
-- the damage against them, and predict how much damage they will take in the future.
-- This will all be used to predict healing.
-- Added role annotation system for flexible party management
PartyMonitor = MyrkAddon:NewModule("MyrkPartyMonitor")
PartyMonitor.party = Party:New()

-- External deps
DamageComm = AceLibrary("DamageComm-1.0")
HealComm = AceLibrary("HealComm-1.0")

-- AceDB defaults for persistent storage
local defaults = {
    realm = {
        roleAssignments = {}, -- Store role assignments per realm
    },
}

function PartyMonitor:OnEnable()
    -- Initialize AceDB
    self.db = LibStub("AceDB-3.0"):New("PartyMonitorDB", defaults, true)
    
    -- Load saved role assignments from realm storage into party
    self.party.roleAssignments = self.db.realm.roleAssignments
    
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdatePartyMembers")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdatePartyMembers")

    self:UpdatePartyMembers()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkPartyMonitor]|r Loaded")
end

function PartyMonitor:OnDisable()
    -- Save role assignments to AceDB realm storage
    if self.db then
        self.db.realm.roleAssignments = self.party.roleAssignments
    end
end

function PartyMonitor:UpdatePartyMembers()
    -- Reload the party members
    self.party:Refresh()
end

-- Role management functions
function PartyMonitor:SetRole(playerName, role)
    local success, error = self.party:SetRole(playerName, role)
    if success then
        -- Save to AceDB realm storage immediately
        self.db.realm.roleAssignments = self.party.roleAssignments
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[PartyMonitor]|r %s is now %s", playerName, role))
    else
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[PartyMonitor]|r %s", error))
    end
    return success
end

function PartyMonitor:GetRole(playerName)
    return self.party:GetRole(playerName)
end

function PartyMonitor:ClearRole(playerName)
    self.party:ClearRole(playerName)
    -- Save to AceDB realm storage immediately
    self.db.realm.roleAssignments = self.party.roleAssignments
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[PartyMonitor]|r Cleared role for %s", playerName))
end

-- Query functions for other modules to use
function PartyMonitor:GetTanks()
  return self.party:GetTanks()
end

function PartyMonitor:GetHealers()
  return self.party:GetHealers()
end

function PartyMonitor:GetDPS()
  return self.party:GetDPS()
end

function PartyMonitor:GetPlayersByRole(role)
  return self.party:GetPlayersByRole(role)
end

function PartyMonitor:ListRoles()
  local assignments = self.party:ListRoleAssignments()
  if #assignments == 0 then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PartyMonitor]|r No role assignments")
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PartyMonitor]|r Role assignments:")
    for _, assignment in ipairs(assignments) do
      DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %s", assignment.name, assignment.role))
    end
  end
end

function PartyMonitor:GetAvailableRoles()
  return Party.ROLES
end

-- Helper function for other modules to get unit IDs by role
function PartyMonitor:GetTankUnitIds()
  local tanks = self:GetTanks()
  local unitIds = {}
  for _, tank in ipairs(tanks) do
    table.insert(unitIds, tank.id)
  end
  return unitIds
end

function PartyMonitor:GetHealerUnitIds()
  local healers = self:GetHealers()
  local unitIds = {}
  for _, healer in ipairs(healers) do
    table.insert(unitIds, healer.id)
  end
  return unitIds
end

function PartyMonitor:GetDPSUnitIds()
  local dps = self:GetDPS()
  local unitIds = {}
  for _, dpsPlayer in ipairs(dps) do
    table.insert(unitIds, dpsPlayer.id)
  end
  return unitIds
end

local MAJOR_VERSION = "PartyMonitor-1.0"
local MINOR_VERSION = "$Revision: 0 $"
AceLibrary:Register(PartyMonitor.party, MAJOR_VERSION, MINOR_VERSION)
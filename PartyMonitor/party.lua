-- Fixed version of Party.lua for testing
-- This version fixes the bugs in the original implementation
-- Added role annotation system for flexible party management

Party = {}
Party.__index = Party

-- Available roles for party members
Party.ROLES = {
    TANK = "Tank",
    OFF_TANK = "Off-Tank", 
    HEALER = "Healer",
    OFF_HEALER = "Off-Healer",
    DPS_MELEE = "Melee DPS",
    DPS_RANGED = "Ranged DPS",
    DPS_CASTER = "Caster DPS",
    SUPPORT = "Support",
    NONE = "None"
}

function Party:New()
    local instance = {
      players = {},
      roleAssignments = {}, -- Persistent role storage by player name
    }
    setmetatable(instance, Party)
    return instance
end

function Party:Refresh()
  self:RefreshID("player") -- Always include player
  for i=1,4 do
    self:RefreshID("party" .. i)
  end
end

-- id should be party1, party2, etc.
-- "player" is also accepted
function Party:RefreshID(id) 
  if UnitExists(id) then
    local name = UnitName(id) -- Fixed: was 'unitstr', now 'id'
    if name and name ~= "" then
      if not self.players[id] then
        self.players[id] = AllyPlayer:New(id)
      end

      self.players[id]:Refresh() -- Fixed: added colon for method call
      
      -- Apply stored role if available
      if self.roleAssignments[name] then
        self.players[id].role = self.roleAssignments[name]
      end
      
      return
    end
  end

  self:RemoveID(id) -- Fixed: added colon for method call
end

function Party:RemoveID(id) 
  self.players[id] = nil
end

-- Role management functions
function Party:SetRole(playerName, role)
  -- Validate role
  local validRole = false
  for _, validRoleName in pairs(self.ROLES) do
    if role == validRoleName then
      validRole = true
      break
    end
  end
  
  if not validRole then
    return false, "Invalid role: " .. tostring(role)
  end
  
  -- Store role assignment
  self.roleAssignments[playerName] = role
  
  -- Apply to current player if they're in party
  local unitId = self:GetUnitIdByName(playerName)
  if unitId and self.players[unitId] then
    self.players[unitId].role = role
  end
  
  return true
end

function Party:GetRole(playerName)
  return self.roleAssignments[playerName] or self.ROLES.NONE
end

function Party:ClearRole(playerName)
  self.roleAssignments[playerName] = nil
  
  -- Clear from current player if they're in party
  local unitId = self:GetUnitIdByName(playerName)
  if unitId and self.players[unitId] then
    self.players[unitId].role = self.ROLES.NONE
  end
end

-- Query functions for roles
function Party:GetPlayersByRole(role)
  local result = {}
  for unitId, player in pairs(self.players) do
    if player.role == role then
      table.insert(result, player)
    end
  end
  return result
end

function Party:GetTanks()
  local tanks = self:GetPlayersByRole(self.ROLES.TANK)
  local offTanks = self:GetPlayersByRole(self.ROLES.OFF_TANK)
  
  -- Combine and return tanks first, then off-tanks
  for _, offTank in ipairs(offTanks) do
    table.insert(tanks, offTank)
  end
  
  return tanks
end

function Party:GetHealers()
  local healers = self:GetPlayersByRole(self.ROLES.HEALER)
  local offHealers = self:GetPlayersByRole(self.ROLES.OFF_HEALER)
  
  -- Combine and return healers first, then off-healers
  for _, offHealer in ipairs(offHealers) do
    table.insert(healers, offHealer)
  end
  
  return healers
end

function Party:GetDPS()
  local dps = {}
  local meleeList = self:GetPlayersByRole(self.ROLES.DPS_MELEE)
  local rangedList = self:GetPlayersByRole(self.ROLES.DPS_RANGED)
  local casterList = self:GetPlayersByRole(self.ROLES.DPS_CASTER)
  
  for _, player in ipairs(meleeList) do table.insert(dps, player) end
  for _, player in ipairs(rangedList) do table.insert(dps, player) end
  for _, player in ipairs(casterList) do table.insert(dps, player) end
  
  return dps
end

function Party:GetUnitIdByName(playerName)
  if UnitName("player") == playerName then
    return "player"
  end
  
  for i = 1, 4 do
    local unitId = "party" .. i
    if UnitExists(unitId) and UnitName(unitId) == playerName then
      return unitId
    end
  end
  
  return nil
end

function Party:ListRoleAssignments()
  local assignments = {}
  for playerName, role in pairs(self.roleAssignments) do
    table.insert(assignments, {name = playerName, role = role})
  end
  return assignments
end

AllyPlayer = {} -- Fixed: was PartyPlayer, should be AllyPlayer
AllyPlayer.__index = AllyPlayer

function AllyPlayer:New(id)
    local instance = {
      id = id,
      name = "",
      hp = -1,
      hpmax = -1,
      class = "",
      role = Party.ROLES.NONE, -- Default role
    }
    setmetatable(instance, AllyPlayer)
    return instance
end

function AllyPlayer:Refresh()
  local _, englishClass = UnitClass(self.id)
  self.name = UnitName(self.id)
  self.hp = UnitHealth(self.id)
  self.hpmax = UnitHealthMax(self.id)
  self.class = englishClass
  -- Note: role is managed by Party:SetRole(), not refreshed here
end

function AllyPlayer:GetHealthPercent()
  if self.hpmax == 0 then
    return 1.0
  end
  return self.hp / self.hpmax
end

function AllyPlayer:IsTank()
  return self.role == Party.ROLES.TANK or self.role == Party.ROLES.OFF_TANK
end

function AllyPlayer:IsHealer()
  return self.role == Party.ROLES.HEALER or self.role == Party.ROLES.OFF_HEALER
end

function AllyPlayer:IsDPS()
  return self.role == Party.ROLES.DPS_MELEE or 
         self.role == Party.ROLES.DPS_RANGED or 
         self.role == Party.ROLES.DPS_CASTER
end
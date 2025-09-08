-- Fixed version of Party.lua for testing
-- This version fixes the bugs in the original implementation
-- Added role annotation system for flexible party management

-- Global variable declarations to prevent undefined errors
local DamageComm = DamageComm or (AceLibrary and AceLibrary("DamageComm-1.0"))
local HealComm = HealComm or (AceLibrary and AceLibrary("HealComm-1.0"))

---@class Party
---@field players table<string, AllyPlayer> key is unitID like "player", "party1", etc.
---@field roleAssignments table<string, PartyRoles> key is player name, value is their role like "Tank"
Party = {}
Party.__index = Party

-- Available roles for party members
---@enum PartyRoles
Party.ROLES = {
    TANK = "Tank",
    NONE = ""
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
    local name = UnitName(id)
    if name and name ~= "" then
      if not self.players[id] then
        self.players[id] = AllyPlayer:New(id)
      end

      self.players[id]:Refresh() 
      
      -- Apply stored role if available
      if self.roleAssignments[name] then
        self.players[id].role = self.roleAssignments[name]
      end
      
      return
    end
  end

  self:RemoveID(id)
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

  if role == self.ROLES.NONE then
    self.roleAssignments[playerName] = nil
  end
  
  return true
end

function Party:GetRole(playerName)
  return self.roleAssignments[playerName] or self.ROLES.NONE
end

function Party:ClearRole(playerName)
  self:SetRole(playerName, self.ROLES.NONE)
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

---Return the player id for a given name if they are in the party. Otherwise returns nil
---@param playerName string
---@return string|nil playerID will be 'player', 'party1', etc. or nil if not found
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

---@class AllyPlayer
---@field id string unit ID like "player", "party1", etc.
---@field name? string Player's name
---@field hp number Current health
---@field hpmax number Maximum health
---@field recentDmg number Recent damage taken
---@field incHeal number Incoming heals
---@field class? string Player's class in English
---@field role string Player's role, e.g. "Tank"
---@field healable? boolean True if the player can be healed
---@field castable? boolean True if the player can be targeted by the spell
AllyPlayer = {} -- Fixed: was PartyPlayer, should be AllyPlayer
AllyPlayer.__index = AllyPlayer

function AllyPlayer:New(id)
    local instance = {
      id = id,
      name = "",
      hp = -1,
      hpmax = -1,
      recentDmg = 0,
      incHeal = 0,
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
  
  -- Safe loading of damage and heal data with fallbacks
  if DamageComm and DamageComm.UnitGetIncomingDamage then
    self.recentDmg = DamageComm.UnitGetIncomingDamage(self.name) or 0
  else
    self.recentDmg = 0
  end
  
  if HealComm and HealComm.getHeal then
    self.incHeal = HealComm:getHeal(self.name) or 0
  else
    self.incHeal = 0
  end
  
  -- Note: role is managed by Party:SetRole(), not refreshed here
end

function AllyPlayer:GetHealthPercent()
  if self.hpmax == 0 then
    return 1.0
  end
  return self.hp / self.hpmax
end

function AllyPlayer:IsTank()
  return self.role == Party.ROLES.TANK
end

function AllyPlayer:HPNeeded(time)
  local dps = (self.recentDmg or 0) / 5
  local hp_needed = (self.hpmax - self.hp + (self.incHeal or 0)) - (dps * (time or 0))
  return hp_needed
end

function AllyPlayer:CalculateTimeToDeath()
    if not self or self.hp <= 0 then
        return 1000 -- Already dead or invalid
    end

    if self.hpmax <= 0 then
        return 1000 -- Invalid max health, assume safe
    end
    
    -- Calculate net damage per second (damage - healing)
    local netDamagePer5Second = self.recentDmg or 0
    local netDamagePerSecond = netDamagePer5Second / 5.0
    local incHeal = self.incHeal or 0
    
    if netDamagePerSecond <= 0 then
        return 1000 -- Taking no net damage or being healed, won't die
    end
    
    -- Calculate time until death
    local timeToDeath = (self.hp + incHeal) / netDamagePerSecond
    
    return math.max(0, timeToDeath)
end
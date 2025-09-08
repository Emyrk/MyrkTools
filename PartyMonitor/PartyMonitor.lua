-- PartyMonitor keeps track of all the current members of our party including ourselves.
-- We want to keep track of the incoming damage to each member. This will allow us to calculate
-- the damage against them, and predict how much damage they will take in the future.
-- This will all be used to predict healing.
-- Added role annotation system for flexible party management
---@class PartyMonitor
---@field instance PartyMonitor
PartyMonitor = MyrkAddon:NewModule("MyrkPartyMonitor", "AceEvent-3.0")

-- External deps
-- local DamageComm = AceLibrary("DamageComm-1.0")
-- local HealComm = AceLibrary("HealComm-1.0")

-- AceDB defaults for persistent storage
local defaults = {
    realm = {
        roleAssignments = {}, -- Store role assignments per realm
    },
}

function PartyMonitor:OnEnable()
  PartyMonitor.party = Party:New()
  -- Initialize AceDB
  self.db = LibStub("AceDB-3.0"):New("PartyMonitorDB", defaults, true)

  -- Load saved role assignments from realm storage into party
  self.party.roleAssignments = self.db.realm.roleAssignments
  
  self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdatePartyMembers")
  self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdatePartyMembers")

  self:UpdatePartyMembers()
  
  -- Initialize pfUI integration
  self:InitializePfUI()
  
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkPartyMonitor]|r Loaded")
end

function PartyMonitor:OnDisable()
    -- Save role assignments to AceDB realm storage
    if self.db then
        self.db.realm.roleAssignments = self.party.roleAssignments
    end
end

---@param callback function(player: PartyPlayer): boolean|nil Return true to stop iteration
function PartyMonitor:ForEach(callback, sortBy)
    if not self.party then
        return
    end

    local sorted = {}
    
    -- Collect all players into an array for sorting
    for k in pairs(self.party.players) do
        table.insert(sorted, k)
    end
    
    -- Sort players if sortBy is specified
    if sortBy then
        if sortBy == "time_to_death" then
            table.sort(sorted, function(a, b)
                local timeA = self.party.players[a]:CalculateTimeToDeath()
                local timeB = self.party.players[b]:CalculateTimeToDeath()
                return timeA < timeB -- Shortest time to death first
            end)
        elseif sortBy == "health_percent" then
            table.sort(sorted, function(a, b)
                local pctA = self.party.players[a].hpmax > 0 and (self.party.players[a].hp / self.party.players[a].hpmax) or 1
                local pctB = self.party.players[b].hpmax > 0 and (self.party.players[b].hp / self.party.players[b].hpmax) or 1
                return pctA < pctB -- Lowest health percent first
            end)
        elseif sortBy == "health_absolute" then
            table.sort(sorted, function(a, b)
                return self.party.players[a].hp < self.party.players[b].hp -- Lowest absolute health first
            end)
        elseif sortBy == "incoming_damage" then
            table.sort(sorted, function(a, b)
                return self.party.players[a].recentDmg > self.party.players[b].recentDmg -- Highest incoming damage first
            end)
        end
    end
    
    -- Iterate through sorted players
    for _, key in ipairs(sorted) do
        local player = self.party.players[key]
        local stop = callback(player)
        if stop then
            break
        end
    end
end

function PartyMonitor:UpdatePartyMembers()
    if not self.party then
        return
    end
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
        
        -- Update pfUI indicators
        self:UpdatePfUIIndicators()
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
    
    -- Update pfUI indicators
    self:UpdatePfUIIndicators()
end

-- Query functions for other modules to use
function PartyMonitor:GetTanks()
  return self.party:GetPlayersByRole(Party.ROLES.TANK)
end

function PartyMonitor:GetPlayersByRole(role)
  return self.party:GetPlayersByRole(role)
end

function PartyMonitor:ListRoles()
  local assignments = self.party:ListRoleAssignments()
  if table.getn(assignments) == 0 then
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

function PartyMonitor:Debug()
    if not self.party then
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PartyMonitor]|r Debug Info:")
    for unitId, player in pairs(self.party.players) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %s (HP: %d/%d, Incoming Heal: %d, Recent Damage: %d, Role: %s)", 
            unitId, player.name, player.hp, player.hpmax, player.incHeal, player.recentDmg, player.role))
    end
end

-- pfUI integration for tank role indicators
function PartyMonitor:PartyMonitorHookPfUI()
    if not pfUI then
        return -- pfUI not available
    end
    
    pfUI:RegisterModule("TankRoleIndicator", "vanilla:tbc", function()
        local HookRefreshUnit = pfUI.uf.RefreshUnit
        function pfUI.uf:RefreshUnit(unit, component)
            -- Always run pfUI's original logic first
            HookRefreshUnit(this, unit, component)
            
            -- Only show on party members and player
            if not unit or not (unit.label == "party" or unit.label == "player") then
                if unit.tankIcon then 
                    unit.tankIcon:Hide() 
                end
                return
            end
            
            local unitstr = (unit.label or "") .. (unit.id or "")
            if unitstr == "" or not UnitExists(unitstr) then
                if unit.tankIcon then 
                    unit.tankIcon:Hide() 
                end
                return
            end
            
            -- Create the tank icon frame once
            if not unit.tankIcon then
                unit.tankIcon = CreateFrame("Frame", nil, unit.hp)
                unit.tankIcon.tex = unit.tankIcon:CreateTexture(nil, "OVERLAY")
                
                -- Try custom texture first, fallback to default if it fails
                local customTexture = "Interface\\AddOns\\MyrkTools\\img\\tank_icon"
                local fallbackTexture = "Interface\\Icons\\Ability_Defend"
                
                unit.tankIcon.tex:SetTexture(customTexture)
                
                -- Check if custom texture loaded successfully
                if not unit.tankIcon.tex:GetTexture() then
                    -- Custom texture failed, use fallback
                    unit.tankIcon.tex:SetTexture(fallbackTexture)
                end
                
                unit.tankIcon.tex:SetAllPoints()
                unit.tankIcon:SetFrameStrata("HIGH")
                unit.tankIcon:SetFrameLevel((unit.hp:GetFrameLevel() or 1) + 15)
                unit.tankIcon:Hide()
            end
            
            -- Check if this player has Tank role
            local playerName = UnitName(unitstr)
            local hasRole = false
            
            if playerName and PartyMonitor.party then
                local role = PartyMonitor.party:GetRole(playerName)
                hasRole = (role == "Tank")
            end
            
            if hasRole then
                -- Show tank icon in top-right corner of health bar
                local iconSize = math.min(8)
                
                unit.tankIcon:SetWidth(iconSize)
                unit.tankIcon:SetHeight(iconSize)
                unit.tankIcon:ClearAllPoints()
                unit.tankIcon:SetPoint("TOPRIGHT", unit.hp, "TOPRIGHT", 0, 0)
                
                -- Set icon color (slightly blue-tinted for visibility)
                unit.tankIcon.tex:SetVertexColor(0.8, 0.9, 1.0, 0.9)
                unit.tankIcon:Show()
            else
                unit.tankIcon:Hide()
            end
        end
    end)
end

-- Initialize pfUI hook
function PartyMonitor:InitializePfUI()
    -- Check if pfUI is available before attempting integration
    if not pfUI then
        -- pfUI not available, skip integration silently
        return
    end
    
    -- Additional safety checks
    if not pfUI.RegisterModule or not pfUI.uf then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[PartyMonitor]|r pfUI found but missing required components")
        return
    end
    
    -- Proceed with pfUI integration
    self:PartyMonitorHookPfUI()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PartyMonitor]|r pfUI tank role indicators enabled")
end

-- Update pfUI indicators when roles change
function PartyMonitor:UpdatePfUIIndicators()
    -- if pfUI and pfUI.uf and pfUI.uf.RefreshUnit then
    --     -- Refresh all unit frames to update tank indicators
    --     for _, frame in pairs(pfUI.uf.units) do
    --         if frame.label == "party" or frame.label == "player" then
    --             pfUI.uf:RefreshUnit(frame)
    --         end
    --     end
    -- end
end

-- Get role priority for sorting (lower number = higher priority)
function PartyMonitor:GetRolePriority(role)
    local priorities = {
        ["Tank"] = 1,
        ["Healer"] = 2,
        ["Off-Tank"] = 3,
        ["Off-Healer"] = 4,
        ["Melee DPS"] = 5,
        ["Ranged DPS"] = 6,
        ["Caster DPS"] = 7,
        ["Support"] = 8,
        ["None"] = 9
    }
    
    return priorities[role] or 10
end
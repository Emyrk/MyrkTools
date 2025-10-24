-- PartyMonitor keeps track of all the current members of our party including ourselves.
-- We want to keep track of the incoming damage to each member. This will allow us to calculate
-- the damage against them, and predict how much damage they will take in the future.
-- This will all be used to predict healing.
-- Added role annotation system for flexible party management
---@class PartyMonitor
---@field instance PartyMonitor
---@field party Party
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

function PartyMonitor:BlackList(id, duration)
    if not self.party then
        return
    end
    self.party:BlackList(id, duration)
end

---@param callback function(player: PartyPlayer): boolean|nil Return true to stop iteration
function PartyMonitor:ForEach(callback)
    if not self.party then
        return
    end

    self.party:ForEach(callback)
end

function PartyMonitor:UpdatePartyMembers()
    if not self.party then
        return
    end
    -- Reload the party members
    self.party:Refresh()
end

function PartyMonitor:DebugPrint()
  self:UpdatePartyMembers() -- Ensure data is current
  for _, id in ipairs(self.party.sorted) do
    local player = self.party.players[id]
    DEFAULT_CHAT_FRAME:AddMessage(string.format("ID: %s, Name: %s, Healable: %s, Role: %s, HP: %d/%d, Class: %s, RecentDmg: %d, IncHeal: %d, TTD: %.1f", 
      id, player.name or "Unknown", player.role or "None", tostring(player.healable), player.hp or -1, player.hpmax or -1, player.class or "Unknown", player.recentDmg or 0, player.incHeal or 0, player:CalculateTimeToDeath()))
  end
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

                if unit.blackListIcon then
                    unit.blackListIcon:Hide()
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
            
            -- Blacklist icon
            if not unit.blackListIcon then
                unit.blackListIcon = CreateFrame("Frame", nil, unit.hp)
                unit.blackListIcon.tex = unit.blackListIcon:CreateTexture(nil, "OVERLAY")
                
                -- Try custom texture first, fallback to default if it fails
                local customTexture = ""
                local fallbackTexture = "Interface\\Icons\\Ability_rogue_feigndeath"
                
                unit.blackListIcon.tex:SetTexture(customTexture)
                
                -- Check if custom texture loaded successfully
                if not unit.blackListIcon.tex:GetTexture() then
                    -- Custom texture failed, use fallback
                    unit.blackListIcon.tex:SetTexture(fallbackTexture)
                end
                
                unit.blackListIcon.tex:SetAllPoints()
                unit.blackListIcon:SetFrameStrata("HIGH")
                unit.blackListIcon:SetFrameLevel((unit.hp:GetFrameLevel() or 1) + 15)
                unit.blackListIcon:Hide()
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

            if PartyMonitor.party:IsBlacklisted(unitstr) then
                -- Show blacklist icon in bottom-right corner of health bar
                local iconSize = math.min(13)
                
                unit.blackListIcon:SetWidth(iconSize)
                unit.blackListIcon:SetHeight(iconSize)
                unit.blackListIcon:ClearAllPoints()
                unit.blackListIcon:SetPoint("BOTTOMRIGHT", unit.hp, "BOTTOMRIGHT", 0, 0)

                -- Set icon color (slightly blue-tinted for visibility)
                unit.blackListIcon.tex:SetVertexColor(0.8, 0.9, 1.0, 0.9)
                unit.blackListIcon:Show()
            else
                unit.blackListIcon:Hide()
            end
        end
    end)
end

-- Initialize pfUI hook
function PartyMonitor:InitializePfUI()
    if pfUI then
        self:PartyMonitorHookPfUI()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PartyMonitor]|r pfUI tank role indicators enabled")
    end
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
-- DecisionEngine.lua
-- Core decision tree executor for the Auto system

DecisionEngine = {}
DecisionEngine.__index = DecisionEngine

function DecisionEngine:New()
    local instance = {
        partyMonitor = nil, -- Set by module
        config = {
            emergencyThreshold = 0.15, -- 15% health for emergency
            selfPreservationThreshold = 0.20, -- 20% for self preservation
            tankHealThreshold = 0.50, -- 50% for tank healing
            partyHealThreshold = 0.85, -- 85% for party healing
            emergencyTimeThreshold = 3, -- seconds to predict death
            tankEmergencyTimeThreshold = 5, -- seconds for tank emergency
        }
    }
    setmetatable(instance, DecisionEngine)
    return instance
end

-- Core decision tree executor
function DecisionEngine:doFirst(decisions)
    for _, decision in ipairs(decisions) do
        local result = self:evaluateDecision(decision)
        if result then
            return result -- First successful decision wins
        end
    end
    return nil -- No decision matched
end

function DecisionEngine:evaluateDecision(decision)
    if type(decision) == "function" then
        return decision(self)
    elseif type(decision) == "table" and decision.evaluate then
        return decision:evaluate(self)
    end
    return nil
end

-- Target resolution helpers using PartyMonitor roles
function DecisionEngine:resolveTank()
    if not self.partyMonitor then
        return nil
    end
    
    -- Get tank unit IDs from PartyMonitor
    local tankUnitIds = self.partyMonitor:GetTankUnitIds()
    
    -- Return first available tank
    for _, unitId in ipairs(tankUnitIds) do
        if UnitExists(unitId) then
            return unitId
        end
    end
    
    return nil
end

function DecisionEngine:resolveTanks()
    if not self.partyMonitor then
        return {}
    end
    
    -- Get all tank unit IDs from PartyMonitor
    local tankUnitIds = self.partyMonitor:GetTankUnitIds()
    local validTanks = {}
    
    for _, unitId in ipairs(tankUnitIds) do
        if UnitExists(unitId) then
            table.insert(validTanks, unitId)
        end
    end
    
    return validTanks
end

function DecisionEngine:resolveParty()
    if not self.partyMonitor then
        -- Fallback to manual party resolution
        local members = {}
        
        -- Add player
        if UnitExists("player") then
            table.insert(members, "player")
        end
        
        -- Add party members
        for i = 1, 4 do
            local unitId = "party" .. i
            if UnitExists(unitId) then
                table.insert(members, unitId)
            end
        end
        
        return members
    end
    
    -- Use PartyMonitor for party resolution
    local members = {}
    for unitId, player in pairs(self.partyMonitor.party.players) do
        if UnitExists(unitId) then
            table.insert(members, unitId)
        end
    end
    
    return members
end

function DecisionEngine:resolveHealers()
    if not self.partyMonitor then
        return {}
    end
    
    -- Get all healer unit IDs from PartyMonitor
    local healerUnitIds = self.partyMonitor:GetHealerUnitIds()
    local validHealers = {}
    
    for _, unitId in ipairs(healerUnitIds) do
        if UnitExists(unitId) then
            table.insert(validHealers, unitId)
        end
    end
    
    return validHealers
end

function DecisionEngine:resolveDPS()
    if not self.partyMonitor then
        return {}
    end
    
    -- Get all DPS unit IDs from PartyMonitor
    local dpsUnitIds = self.partyMonitor:GetDPSUnitIds()
    local validDPS = {}
    
    for _, unitId in ipairs(dpsUnitIds) do
        if UnitExists(unitId) then
            table.insert(validDPS, unitId)
        end
    end
    
    return validDPS
end

-- Helper function to get health percentage
function DecisionEngine:getHealthPercent(unitId)
    if not UnitExists(unitId) then
        return 1.0 -- Assume healthy if unit doesn't exist
    end
    
    local current = UnitHealth(unitId)
    local max = UnitHealthMax(unitId)
    
    if max == 0 then
        return 1.0
    end
    
    return current / max
end

-- Helper function to predict incoming damage using DamageComm
function DecisionEngine:predictDamage(unitId, timeSeconds)
    local unitName = UnitName(unitId)
    if not unitName then
        return 0
    end
    
    -- Use DamageComm to get incoming damage
    local incomingDamage = UnitGetIncomingDamage(unitName)
    local dps = incomingDamage / 5 -- DamageComm gives 5-second window
    
    return dps * timeSeconds
end

-- Helper function to check if unit will die in X seconds
function DecisionEngine:willDieIn(unitId, timeSeconds)
    local currentHealth = UnitHealth(unitId)
    local predictedDamage = self:predictDamage(unitId, timeSeconds)
    
    return currentHealth - predictedDamage <= 0
end

-- Helper function to check if we're already casting
function DecisionEngine:isAlreadyCasting()
    local spell, _, _, _, _, endTime = UnitCastingInfo("player")
    return spell ~= nil
end

-- Helper function to check if target has a specific buff
function DecisionEngine:hasBuff(unitId, buffName)
    local i = 1
    while UnitBuff(unitId, i) do
        local buff = UnitBuff(unitId, i)
        if string.find(buff, buffName) then
            return true
        end
        i = i + 1
    end
    return false
end
-- DecisionEngine.lua
-- Core decision tree executor for the Auto system

---@class DecisionEngine
DecisionEngine = {}
DecisionEngine.__index = DecisionEngine

function DecisionEngine:New()
    local instance = {
        partyMonitor = nil, -- Set by module
        castMonitor = nil, 
        strategy = nil, -- Current strategy (list of decision nodes)
        config = {
        }
    }

    local localizedClass, englishClass = UnitClass("player")
    if englishClass == "ROGUE" then
        instance.strategy = Rogue
    elseif englishClass == "PRIEST" then
        instance.strategy = HealingStrategy
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r Unsupported class: " .. tostring(englishClass))
        return nil
    end
    
    setmetatable(instance, DecisionEngine)
    return instance
end

function DecisionEngine:LoadModules()
    if not self.partyMonitor then
        self.partyMonitor = MyrkAddon:GetModule("MyrkPartyMonitor")
        if not self.partyMonitor then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r PartyMonitor not found")
        end
    end

    if not self.castMonitor then
        self.castMonitor = MyrkAddon:GetModule("MyrkCastMonitor")
        if not self.castMonitor then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r MyrkCastMonitor not found")
        end
    end
end

function DecisionEngine:Ready()
    self:LoadModules()
    return self.partyMonitor and self.castMonitor
end

-- Core decision tree executor
function DecisionEngine:Execute()
    for _, step in ipairs(self.strategy) do
        print("Evaluating step:", step)
        local result = self:evaluateStep(step)
        print("Step result:", type(result))
        if result then
            return result -- First successful decision wins
        end
    end
    return nil -- No decision matched
end

function DecisionEngine:evaluateStep(step)
    if type(step) == "function" then
        return step(self)
    elseif type(step) == "table" and step.evaluate then
        return step:evaluate(self)
    end
    return nil
end

-- Target resolution helpers using PartyMonitor roles
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
    return self.castMonitor:IsCasting()
end

-- Execute a healing action with monitoring
function DecisionEngine:ExecuteAction(decision)
    if not decision or decision.action ~= "cast" then
        return false
    end
    
    -- Start monitoring the cast
    local callbacks = {
        onSuccess = function(spell, target, reason)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Auto]|r Cast successful: %s -> %s (%s)", 
                spell, target, reason))
        end,
        onFailed = function(spell, target, reason, error)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[Auto]|r Cast failed: %s -> %s (%s) - %s", 
                spell, target, reason, error or "Unknown"))
        end,
        onInterrupted = function(spell, target, reason, error)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffffff00[Auto]|r Cast interrupted: %s -> %s (%s) - %s", 
                spell, target, reason, error or "Unknown"))
        end
    }
    
    self.castMonitor:StartMonitor(decision.spell, decision.target, decision.reason, callbacks)
    
    -- Target the unit first
    TargetUnit(decision.target)
    
    -- Cast the spell
    CastSpellByName(decision.spell)
    
    return true
end

-- Get current cast information
function DecisionEngine:GetCurrentCast()
    return self.castMonitor:GetCurrentCast()
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
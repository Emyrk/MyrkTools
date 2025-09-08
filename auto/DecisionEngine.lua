-- DecisionEngine.lua
-- Core decision tree executor for the Auto system

---@class DecisionEngine
---@field partyMonitor PartyMonitor
---@field castMonitor CastMonitor
DecisionEngine = {}
DecisionEngine.__index = DecisionEngine

function DecisionEngine:New()
    local localizedClass, englishClass = UnitClass("player")
    local strategy = {}
    if englishClass == "ROGUE" then
        strategy = RogueStrategy
    elseif englishClass == "PRIEST" then
        strategy = PriestStrategy
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r Unsupported class: " .. tostring(englishClass))
        return nil
    end

    local instance = {
        partyMonitor = nil, -- Set by module
        castMonitor = nil, 
        strategy = strategy, -- Current strategy (list of decision nodes)
        config = {
        }
    }
    
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
        local result = self:evaluateStep(step)
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

-- Helper function to check if we're already casting
function DecisionEngine:isAlreadyCasting()
    return self.castMonitor:IsCasting()
end

function DecisionEngine:ExecuteCast(decision)
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
    
    self.castMonitor:CastSpell(decision.spell, callbacks)
    -- Target the unit first
    TargetUnit(decision.target)
    
    -- Cast the spell
    CastSpellByName(decision.spell, decision.target)

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
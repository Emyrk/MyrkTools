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

    ReloadSpells()
    -- print(PrintTable(Spells))
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
        if not self.castMonitor then
            self.castMonitor = MyrkAddon:GetModule("MyrkCastMonitor")
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r MyrkCastMonitor not found")
        end
    end
end

function DecisionEngine:Ready()
    self:LoadModules()
    return self.partyMonitor and self.castMonitor
end

-- Core decision tree executor
---@return Action|nil
function DecisionEngine:Execute()
    self.ctx = {}
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
    else 
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r Invalid decision step: " .. type(step))
    end
    return nil
end

-- Helper function to check if we're already casting
function DecisionEngine:isAlreadyCasting()
    return self.castMonitor:IsCasting()
end

function DecisionEngine:ExecuteCast(decision)
    if not decision or decision.action ~= ACTIONS.cast then
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
    
    -- Assume the target is already correctly selected
    self.castMonitor:StartMonitor(decision.spellID, decision.target_id, decision.reason, callbacks)
    CastSpellByName(decision.spellID)

    return true
end

function DecisionEngine:ExecuteHeal(decision)
    if not decision or decision.action ~= ACTIONS.heal then
        return false
    end

        -- Start monitoring the cast
    local callbacks = {
        onSuccess = function(spell, target, reason)
            -- DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Auto]|r Cast successful: %s -> %s (%s)", 
            --     spell, target, reason))
        end,
        onFailed = function(spell, target, reason, error)
            self.partyMonitor:BlackList(target, 5)
            -- DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[Auto]|r Cast failed: %s -> %s (%s) - %s", 
            --     spell, target, reason, error or "Unknown"))
        end,
        onInterrupted = function(spell, target, reason, error)
            -- DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffffff00[Auto]|r Cast interrupted: %s -> %s (%s) - %s", 
            --     spell, target, reason, error or "Unknown"))
        end
    }
    

    local result = WithAutoSelfCastOff(RetainTarget(function (engine)
        engine.castMonitor:StartMonitor(decision.spellID, decision.target_id, decision.reason, callbacks)
        CastSpell(decision.spellID, BOOKTYPE_SPELL)

        if not SpellIsTargeting() then
            return Action:Error("Spell is not targeting")
        end

        SpellTargetUnit(decision.target_id)

        -- If the target failed to acquire, throw an error.
        -- We should no longer be targeting after this point.
        if SpellIsTargeting() then
            SpellStopTargeting()
            return Action:Error("Failed to target unit")
        end

        return nil
    end))(self)
   
    if result and result.action == ACTIONS.error then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[Auto]|r Cast error: %s -> %s (%s)", 
            decision.spellID, decision.target_id or "??", result.reason))
        return false
    end

    return true
end

-- Get current cast information
function DecisionEngine:GetCurrentCast()
    return self.castMonitor:GetCurrentCast()
end

---@param ptype string "player", "tank", or "party"
---@param callback fn(player: PartyPlayer): boolean|nil Return true to stop iteration
function DecisionEngine:ForEach(ptype, callback)
    self.partyMonitor:ForEach(function(player)
        if ptype == "player" and player.unitId == "player" then
            return callback(player)
        elseif ptype == "tank" and player.role == "Tank" then
            return callback(player)
        elseif ptype == "party" then
            return callback(player)
        end

        return false
    end)
end

-- Helper function to check if target has a specific buff
function DecisionEngine:hasBuff(unitId, buffName)
    local i = 1
    while UnitBuff(unitId, i) do
        local icon, _, _, id = UnitBuff(unitId, i)
        if string.find(icon, buffName) then
            return true
        end
        i = i + 1
    end
    return false
end

function DecisionEngine:hasDebuff(unitId, debuffName)
    local i = 1
    while UnitDebuff(unitId, i) do
        local icon, _, _, id = UnitDebuff(unitId, i)
        if string.find(icon, debuffName) then
            return true
        end
        i = i + 1
    end
    return false
end
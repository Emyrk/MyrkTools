-- DecisionEngine.lua
-- Core decision tree executor for the Auto system

---@class DecisionEngine
---@field partyMonitor PartyMonitor
---@field castMonitor CastMonitor
---@field loopStrategy table List of decision nodes to evaluate every loop
---@field class string Player class
DecisionEngine = {}
DecisionEngine.__index = DecisionEngine

function DecisionEngine:New()
    local localizedClass, englishClass = UnitClass("player")
    local strategy = {}
    local loopStrategy = NoopLoopStrategy
    if englishClass == "ROGUE" then
        loopStrategy = RogueLoopStrategy
    elseif englishClass == "PRIEST" then
        loopStrategy = PriestLoopStrategy
    elseif englishClass == "SHAMAN" then
        loopStrategy = ShamanLoopStrategy
    elseif englishClass == "WARLOCK" then
        loopStrategy = WarlockLoopStrategy
    elseif englishClass == "WARRIOR" then
        loopStrategy = WarriorLoopStrategy
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r Unsupported class: " .. tostring(englishClass))
        return nil
    end

    local instance = {
        partyMonitor = nil, -- Set by module
        castMonitor = nil, 
        loopStrategy = loopStrategy,
        config = {
        },
        class = englishClass,
    }
    
    setmetatable(instance, DecisionEngine)

    ReloadSpells()
    -- print(PrintTable(Spells))
    return instance
end

function DecisionEngine:LoadModules()
    self:PartyMonitor()
    self:CastMonitor()
end

function DecisionEngine:PartyMonitor()
    if not self.partyMonitor then
        self.partyMonitor = MyrkAddon:GetModule("MyrkPartyMonitor")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r MyrkPartyMonitor not found")
    end
    return self.partyMonitor
end

function DecisionEngine:CastMonitor()
    if not self.castMonitor then
        self.castMonitor = MyrkAddon:GetModule("MyrkCastMonitor")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r MyrkCastMonitor not found")
    end
    return self.castMonitor
end

function DecisionEngine:Ready()
    self:LoadModules()
    return self.partyMonitor and self.castMonitor
end

function DecisionEngine:ExecuteLoopedStrategy()
    self.ctx = {}
    if GetNumRaidMembers() > 0 and self.loopStrategy["raid"] then
        return self:executeSteps(self.loopStrategy["raid"])
    end
    if self.loopStrategy["default"] then
        return self:executeSteps(self.loopStrategy["default"])
    end
    return self:executeSteps(self.loopStrategy or {})
end

-- Core decision tree executor
---@return Action|nil
function DecisionEngine:executeSteps(steps)
    for _, step in ipairs(steps) do
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
function DecisionEngine:IsMonitoredCasting()
    return self:CastMonitor():IsMonitoredCasting()
end

function DecisionEngine:IsGlobalCasting()
    return self:CastMonitor():IsGlobalCasting()
end

function DecisionEngine:ExecuteCast(decision)
    if not decision or decision.action ~= ACTIONS.cast then
        return false
    end

        -- Start monitoring the cast
    local callbacks = {
        onSuccess = function(spell, target, reason)
            --DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Auto]|r Cast successful: %s -> %s (%s)", 
            --    spell, target, reason))
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

    -- The original target will be restored after the cast
    local targetChanged = false
    if decision.target_id ~= "target" then
        TargetUnit(decision.target_id)
        targetChanged = true
    end

    if decision.spellID then
        self:CastMonitor():StartMonitor(decision.spellID, decision.target_id, decision.reason, callbacks)
        CastSpell(decision.spellID, BOOKTYPE_SPELL)
    else
        -- Assume the target is already correctly selected
        if decision.spellName ~= "Shoot" then
            self:CastMonitor():StartMonitor(decision.spellName, decision.target_id, decision.reason, callbacks)
        end
        CastSpellByName(decision.spellName)
    end

    if targetChanged then
        TargetLastTarget()
    end

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
            self:PartyMonitor():UpdatePartyMembers()
        end,
        onFailed = function(spell, target, reason, error)
            if error ~= "LeftButton" then
                self:PartyMonitor():BlackList(target, 5)
                Logs.Error(string.format("Cast failed, blacklist: %s -> %s (%s) - %s", 
                spell, target, reason, error or "Unknown"))
            end

            -- DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[Auto]|r Cast failed: %s -> %s (%s) - %s", 
            --     spell, target, reason, error or "Unknown"))
        end,
        onInterrupted = function(spell, target, reason, error)
            -- DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffffff00[Auto]|r Cast interrupted: %s -> %s (%s) - %s", 
            --     spell, target, reason, error or "Unknown"))
        end
    }
    
    -- Might help to cast inner focus here
    -- if self.class == "PRIEST" and UnitHealth(decision.target_id)/UnitHealthMax(decision.target_id) < 0.5 then
    --     CastInnerFocus(self) 
    -- end

    if UnitIsUnit(decision.target_id, "target") then
        -- No magic needed
        CastSpell(decision.spellID, BOOKTYPE_SPELL)
        return true
    end

    local result = WithAutoSelfCastOff(RetainTarget(function (engine)
        SpellStopTargeting()
        SpellStopCasting()
        engine:CastMonitor():StartMonitor(decision.spellID, decision.target_id, decision.reason, callbacks, true)
        CastSpell(decision.spellID, BOOKTYPE_SPELL)

        if not SpellIsTargeting() then
            return Action:Error("Spell is not targeting")
        end

        SpellTargetUnit(decision.target_id)

        -- If the target failed to acquire, throw000000 an error.
        -- We should no longer be targeting after this point.
        if SpellIsTargeting() then
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
    return self:CastMonitor():GetCurrentCast()
end

---@param ptype string "player", "tank", or "party"
---@param callback function(player: PartyPlayer): boolean|nil Return true to stop iteration
function DecisionEngine:ForEach(ptype, callback)
    self:PartyMonitor():ForEach(function(player)
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

function DecisionEngine:PrintBuffs(unitId, buffName)
    local i = 1
    while UnitBuff(unitId, i) do
        local icon, applications, _, id = UnitBuff(unitId, i)
        print(string.format("Buff %d: %s (id=%s, applications=%d)", i, icon or "nil", id or "nil", applications or 0))
        i = i + 1
    end
    return false
end

-- Helper function to check if target has a specific buff
---@arg unitId string Unit ID to check
---@param selector string|number|function(string,number):boolean
function DecisionEngine:hasBuff(unitId, selector)
    local i = 1
    while UnitBuff(unitId, i) do
        local icon, _, id = UnitBuff(unitId, i)
        if type(selector) == "string" then
            if string.find(icon, selector) then
                return true
            end
        elseif type(selector) == "number" then
            if id == selector then
                return true
            end
        elseif type(selector) == "function" then
            if selector(icon, id) then
                return true
            end
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
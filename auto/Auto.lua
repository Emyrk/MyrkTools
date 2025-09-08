-- Auto - Decision tree based healing system
-- Uses a modular decision tree approach for flexible healing strategies

Auto = MyrkAddon:NewModule("MyrkAuto", "AceEvent-3.0")

-- Safe library loading with error handling
local function SafeLoadLibrary(name)
    if AceLibrary and type(AceLibrary) == "function" then
        return AceLibrary(name)
    end
    return nil
end

-- Load libraries safely
local HealComm = SafeLoadLibrary("HealComm-1.0")
local DamageComm = SafeLoadLibrary("DamageComm-1.0")
local Logs = SafeLoadLibrary("MyrkLogs-1.0")
-- Party = SafeLoadLibrary("PartyMonitor-1.0")

---@class Auto
---@field engine DecisionEngine
function Auto:OnEnable()
    -- Initialize the decision engine
    self.engine = DecisionEngine:New()
    
    -- Register for party/raid updates
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnPartyChanged")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "OnPartyChanged")
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkAuto]|r Loaded")
end

function Auto:OnPartyChanged()
    -- PartyMonitor handles role management now
end

function Auto:Perform()
    if not self.engine then
        Logs.Error("Auto engine not initialized")
        return false
    end

    if not self.engine:Ready() then
        Logs.Error("Auto engine is not ready")
        return false

    end
        
    -- Execute the healing strategy
    local decision = self.engine:Execute()
    if decision then
        if decision.action == ACTIONS.busy then
            -- Logs.Debug("Busy: " .. (decision.reason or "no reason"))
            return true -- Still busy, do not interrupt 
        end

        if decision.action == ACTIONS.cast then
            local name = UnitName(decision.target_id) or decision.target_id

            Logs.Info(string.format("Casting %s on %s (%s)", 
                decision.spellID, name, decision.reason or "no reason"))
            return self.engine:ExecuteCast(decision)
        end

        if decision.action == ACTIONS.error then
            Logs.Error("Error: " .. (decision.reason or "no reason"))
            return false
        end

         if decision.action == ACTIONS.heal then
            local name = UnitName(decision.target_id) or decision.target_id
            local spellName, spellRank = GetSpellName(decision.spellID, BOOKTYPE_SPELL)
            Logs.Info(string.format("Healing %s:%s on %s (%s)", 
                spellName, spellRank, name, decision.reason))
            return self.engine:ExecuteHeal(decision)
        end

        Logs.Error("Error: Unsupported action = " .. (decision.action or "no reason"))
    end
    
    return false
end
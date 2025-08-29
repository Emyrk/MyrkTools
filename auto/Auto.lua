-- Auto - Decision tree based healing system
-- Uses a modular decision tree approach for flexible healing strategies

Auto = MyrkAddon:NewModule("MyrkAuto")
HealComm = AceLibrary("HealComm-1.0")
DamageComm = AceLibrary("DamageComm-1.0")
Logs = AceLibrary("MyrkLogs-1.0")
-- Party = AceLibrary("PartyMonitor-1.0")

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

-- Main healing function to be called from keybinds or automation
function Auto:PerformHealing()
    if not self.engine then
        Logs.Error("Auto engine not initialized")
        return false
    end

    if not self.engine.partyMonitor then
        -- Get the current party state from PartyMonitor
        local partyMonitor = MyrkAddon:GetModule("MyrkPartyMonitor")
        if not partyMonitor then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAuto]|r PartyMonitor not found")
            return false
        end
        self.engine.partyMonitor = partyMonitor
    end
        
    -- Execute the healing strategy
    local decision = self.engine:doFirst(HealingStrategy)
    
    if decision and decision.action == "cast" then
        -- Execute the healing action with monitoring
        return self.engine:ExecuteAction(decision)
    end
    
    return false -- No action taken
end
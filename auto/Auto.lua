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
    
    -- Configure tank list (manually set for now)
    self.engine.tankList = {} -- Add tank names here: {"TankName1", "TankName2"}
    
    -- Register for party/raid updates to refresh tank list
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnPartyChanged")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "OnPartyChanged")
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkAuto]|r Loaded")
end

function Auto:OnPartyChanged()
    -- Could auto-detect tanks here or refresh manual list
    -- TODO: PartyMonitor can maybe allow annotations?
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
        -- Execute the healing action
        self:ExecuteHealingAction(decision)
        return true
    end
    
    return false -- No action taken
end

function Auto:ExecuteHealingAction(decision)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Auto]|r %s -> %s (%s)", 
        decision.spell, decision.target, decision.reason))
    
    -- Target the unit first
    TargetUnit(decision.target)
    
    -- Cast the spell
    CastSpellByName(decision.spell)
end

-- Configuration functions
function Auto:AddTank(tankName)
    if not self.engine then return end
    
    for _, name in ipairs(self.engine.tankList) do
        if name == tankName then
            return -- Already in list
        end
    end
    
    table.insert(self.engine.tankList, tankName)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Auto]|r Added tank: %s", tankName))
end

function Auto:RemoveTank(tankName)
    if not self.engine then return end
    
    for i, name in ipairs(self.engine.tankList) do
        if name == tankName then
            table.remove(self.engine.tankList, i)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[Auto]|r Removed tank: %s", tankName))
            return
        end
    end
end

function Auto:ListTanks()
    if not self.engine then return end
    
    if #self.engine.tankList == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Auto]|r No tanks configured")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Auto]|r Tanks:")
        for _, name in ipairs(self.engine.tankList) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. name)
        end
    end
end
-- AutoHeal - Decision tree based healing system
-- Uses a modular decision tree approach for flexible healing strategies

AutoHeal = MyrkAddon:NewModule("MyrkAutoHeal")

function AutoHeal:OnEnable()
    -- Initialize the decision engine
    self.engine = DecisionEngine:New()
    
    -- Configure tank list (manually set for now)
    self.engine.tankList = {} -- Add tank names here: {"TankName1", "TankName2"}
    
    -- Register for party/raid updates to refresh tank list
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnPartyChanged")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "OnPartyChanged")
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkAutoHeal]|r Loaded")
end

function AutoHeal:OnPartyChanged()
    -- Could auto-detect tanks here or refresh manual list
end

-- Main healing function to be called from keybinds or automation
function AutoHeal:PerformHealing()
    if not self.engine then
        return false
    end
    
    -- Get the current party state from PartyMonitor
    local partyMonitor = MyrkAddon:GetModule("MyrkPartyMonitor")
    if not partyMonitor then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MyrkAutoHeal]|r PartyMonitor not found")
        return false
    end
    
    self.engine.partyMonitor = partyMonitor
    
    -- Execute the healing strategy
    local decision = self.engine:doFirst(HealingStrategy)
    
    if decision and decision.action == "cast" then
        -- Execute the healing action
        self:ExecuteHealingAction(decision)
        return true
    end
    
    return false -- No action taken
end

function AutoHeal:ExecuteHealingAction(decision)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[AutoHeal]|r %s -> %s (%s)", 
        decision.spell, decision.target, decision.reason))
    
    -- Target the unit first
    TargetUnit(decision.target)
    
    -- Cast the spell
    CastSpellByName(decision.spell)
end

-- Configuration functions
function AutoHeal:AddTank(tankName)
    if not self.engine then return end
    
    for _, name in ipairs(self.engine.tankList) do
        if name == tankName then
            return -- Already in list
        end
    end
    
    table.insert(self.engine.tankList, tankName)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[AutoHeal]|r Added tank: %s", tankName))
end

function AutoHeal:RemoveTank(tankName)
    if not self.engine then return end
    
    for i, name in ipairs(self.engine.tankList) do
        if name == tankName then
            table.remove(self.engine.tankList, i)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[AutoHeal]|r Removed tank: %s", tankName))
            return
        end
    end
end

function AutoHeal:ListTanks()
    if not self.engine then return end
    
    if #self.engine.tankList == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoHeal]|r No tanks configured")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoHeal]|r Tanks:")
        for _, name in ipairs(self.engine.tankList) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. name)
        end
    end
end
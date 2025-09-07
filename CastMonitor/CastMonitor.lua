-- CastMonitor.lua
-- Monitors spell casting state and provides feedback on cast success/failure
-- Based on QuickHeal's StartMonitor/StopMonitor system

---@class CastMonitor
---@field instance ClassMonitorInstance
CastMonitor = MyrkAddon:NewModule("MyrkCastMonitor")
Logs = AceLibrary("MyrkLogs-1.0")

-- Monitoring state
local monitorFrame = nil

Reasons = {
    OUT_OF_RANGE = "OUT_OF_RANGE",
    LINE_OF_SIGHT = "LINE_OF_SIGHT",
}

function CastMonitor:OnEnable()
    ---@class ClassMonitorInstance
    ---@field isActive boolean
    self.instance = {
        isActive = false,
        currentTarget = nil,
        currentSpell = nil,
        currentReason = nil,
        startTime = nil,
        callbacks = {
            onSuccess = nil,
            onFailed = nil,
            onInterrupted = nil,
        }
    }
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkCastMonitor]|r Loaded")
end

-- /script CastMonitor:CastSpellByNameAndLog("Heal")
-- /script print(CastMonitor:IsMonitoring())
function CastMonitor:CastSpellByNameAndLog(spell)
    local name = UnitName("target")
    if not name then
        -- TODO: Double check this
        name = UnitName("player")
    end

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

    self:StartMonitor(spell, name, "manual", callbacks)
    
    -- Cast the spell
    CastSpellByName(spell)
end

-- Start monitoring a spell cast
function CastMonitor:StartMonitor(spell, target, reason, callbacks)
    -- Stop any existing monitor
    self:StopMonitor("Starting new cast")
    if not callbacks then
        callbacks = {}
    end
    
    -- Set up monitoring state
    self.instance = {
        isActive = true,
        currentTarget = target,
        currentSpell = spell,
        currentReason = reason or "unknown",
        startTime = GetTime(),
        callbacks = {
            onSuccess = callbacks.onSuccess or nil,
            onFailed = callbacks.onFailed or nil,
            onInterrupted = callbacks.onInterrupted or nil,
        }
    }
    
    -- Create frame if it doesn't exist
    if not monitorFrame then
        monitorFrame = CreateFrame("Frame")
        monitorFrame:SetScript("OnEvent", function()
            CastMonitor:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
        end)
    end
    
    -- Register events
    monitorFrame:RegisterEvent("SPELLCAST_STOP")
    monitorFrame:RegisterEvent("SPELLCAST_FAILED")
    monitorFrame:RegisterEvent("SPELLCAST_INTERRUPTED")
    monitorFrame:RegisterEvent("UI_ERROR_MESSAGE")
    
    local msg = string.format("|cff00ff00[CastMonitor]|r Started monitoring %s -> %s (%s)", 
        spell, target, reason)
    Logs.Debug(msg)
    -- DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Stop monitoring
function CastMonitor:StopMonitor(trigger)
    if not self.instance.isActive then
        return
    end
    
    -- Unregister events
    if monitorFrame then
        monitorFrame:UnregisterEvent("SPELLCAST_STOP")
        monitorFrame:UnregisterEvent("SPELLCAST_FAILED")
        monitorFrame:UnregisterEvent("SPELLCAST_INTERRUPTED")
        monitorFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    end
    
    local msg = string.format("|cff00ff00[CastMonitor]|r Stopped monitoring: %s", 
        trigger or "Unknown trigger")
    Logs.Debug(msg)
    -- DEFAULT_CHAT_FRAME:AddMessage(msg)
    
    -- Clear state
    self.instance = {
        isActive = false,
        currentTarget = nil,
        currentSpell = nil,
        currentReason = nil,
        startTime = nil
    }
    
    -- Clear callbacks
    self.callbacks = nil
end

-- Event handler
function CastMonitor:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
    if not self.instance.isActive then
        Logs.Debug("CastMonitor received event while not active: " .. (event or "nil"))
        return
    end
    
    if event == "SPELLCAST_STOP" then
        -- Spell cast completed successfully
        if self.callbacks and self.callbacks.onSuccess then
            self.callbacks.onSuccess(self.currentSpell, self.currentTarget, self.currentReason)
        end
        self:StopMonitor("SPELLCAST_STOP")
        
    elseif event == "SPELLCAST_FAILED" then
        -- Spell cast failed
        if self.callbacks and self.callbacks.onFailed then
            self.callbacks.onFailed(self.currentSpell, self.currentTarget, self.currentReason, arg1)
        end
        self:StopMonitor("SPELLCAST_FAILED: " .. (arg1 or "Unknown"))
        
    elseif event == "SPELLCAST_INTERRUPTED" then
        -- Spell cast was interrupted
        if self.callbacks and self.callbacks.onInterrupted then
            self.callbacks.onInterrupted(self.currentSpell, self.currentTarget, self.currentReason, arg1)
        end
        self:StopMonitor("SPELLCAST_INTERRUPTED: " .. (arg1 or "Unknown"))
        
    elseif event == "UI_ERROR_MESSAGE" and arg1 then
        -- Handle specific error messages
        if arg1 == ERR_SPELL_OUT_OF_RANGE then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[CastMonitor]|r Out of range: %s", 
                self.currentTarget or "unknown"))
            if self.callbacks and self.callbacks.onFailed then
                self.callbacks.onFailed(self.currentSpell, self.currentTarget, self.currentReason, "OUT_OF_RANGE")
            end
            self:StopMonitor(Reasons.OUT_OF_RANGE)
            
        elseif arg1 == SPELL_FAILED_LINE_OF_SIGHT then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[CastMonitor]|r Line of sight: %s", 
                self.currentTarget or "unknown"))
            if self.callbacks and self.callbacks.onFailed then
                self.callbacks.onFailed(self.currentSpell, self.currentTarget, self.currentReason, "LINE_OF_SIGHT")
            end
            self:StopMonitor(Reasons.LINE_OF_SIGHT)
        end
    end
end

-- Check if currently monitoring a cast
function CastMonitor:IsMonitoring()
    return self.instance.isActive
end

-- Get current cast info
function CastMonitor:GetCurrentCast()
    if not self.instance.isActive then
        return nil
    end
    
    return {
        spell = self.currentSpell,
        target = self.currentTarget,
        reason = self.currentReason,
        startTime = self.startTime,
        duration = GetTime() - (self.startTime or 0)
    }
end

-- Check if we're currently casting (either monitored or via WoW API)
function CastMonitor:IsCasting()
    -- Check if we're monitoring a cast
    if self.instance.isActive then
        return true
    end
    
    -- Check WoW's casting info as fallback
    local spell, _, _, _, _, endTime = UnitCastingInfo("player")
    return spell ~= nil
end
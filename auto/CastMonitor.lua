-- CastMonitor.lua
-- Monitors spell casting state and provides feedback on cast success/failure
-- Based on QuickHeal's StartMonitor/StopMonitor system

CastMonitor = {}
CastMonitor.__index = CastMonitor

-- Monitoring state
local isMonitoring = false
local currentCast = nil
local monitorFrame = nil

function CastMonitor:New()
    local instance = {
        isActive = false,
        currentTarget = nil,
        currentSpell = nil,
        currentReason = nil,
        startTime = nil,
        callbacks = {
            onSuccess = nil,
            onFailed = nil,
            onInterrupted = nil,
            onStopped = nil
        }
    }
    setmetatable(instance, CastMonitor)
    return instance
end

-- Start monitoring a spell cast
function CastMonitor:StartMonitor(spell, target, reason, callbacks)
    -- Stop any existing monitor
    self:StopMonitor("Starting new cast")
    
    -- Set up monitoring state
    self.isActive = true
    self.currentTarget = target
    self.currentSpell = spell
    self.currentReason = reason or "unknown"
    self.startTime = GetTime()
    
    -- Store callbacks
    if callbacks then
        self.callbacks.onSuccess = callbacks.onSuccess
        self.callbacks.onFailed = callbacks.onFailed
        self.callbacks.onInterrupted = callbacks.onInterrupted
        self.callbacks.onStopped = callbacks.onStopped
    end
    
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
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[CastMonitor]|r Started monitoring %s -> %s (%s)", 
        spell, target, reason))
end

-- Stop monitoring
function CastMonitor:StopMonitor(trigger)
    if not self.isActive then
        return
    end
    
    -- Unregister events
    if monitorFrame then
        monitorFrame:UnregisterEvent("SPELLCAST_STOP")
        monitorFrame:UnregisterEvent("SPELLCAST_FAILED")
        monitorFrame:UnregisterEvent("SPELLCAST_INTERRUPTED")
        monitorFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[CastMonitor]|r Stopped monitoring: %s", 
        trigger or "Unknown trigger"))
    
    -- Clear state
    self.isActive = false
    self.currentTarget = nil
    self.currentSpell = nil
    self.currentReason = nil
    self.startTime = nil
    
    -- Clear callbacks
    self.callbacks.onSuccess = nil
    self.callbacks.onFailed = nil
    self.callbacks.onInterrupted = nil
    self.callbacks.onStopped = nil
end

-- Event handler
function CastMonitor:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
    if not self.isActive then
        return
    end
    
    if event == "SPELLCAST_STOP" then
        -- Spell cast completed successfully
        if self.callbacks.onSuccess then
            self.callbacks.onSuccess(self.currentSpell, self.currentTarget, self.currentReason)
        end
        self:StopMonitor("SPELLCAST_STOP")
        
    elseif event == "SPELLCAST_FAILED" then
        -- Spell cast failed
        if self.callbacks.onFailed then
            self.callbacks.onFailed(self.currentSpell, self.currentTarget, self.currentReason, arg1)
        end
        self:StopMonitor("SPELLCAST_FAILED: " .. (arg1 or "Unknown"))
        
    elseif event == "SPELLCAST_INTERRUPTED" then
        -- Spell cast was interrupted
        if self.callbacks.onInterrupted then
            self.callbacks.onInterrupted(self.currentSpell, self.currentTarget, self.currentReason, arg1)
        end
        self:StopMonitor("SPELLCAST_INTERRUPTED: " .. (arg1 or "Unknown"))
        
    elseif event == "UI_ERROR_MESSAGE" and arg1 then
        -- Handle specific error messages
        if arg1 == ERR_SPELL_OUT_OF_RANGE then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[CastMonitor]|r Out of range: %s", 
                self.currentTarget or "unknown"))
            if self.callbacks.onFailed then
                self.callbacks.onFailed(self.currentSpell, self.currentTarget, self.currentReason, "OUT_OF_RANGE")
            end
            self:StopMonitor("OUT_OF_RANGE")
            
        elseif arg1 == SPELL_FAILED_LINE_OF_SIGHT then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[CastMonitor]|r Line of sight: %s", 
                self.currentTarget or "unknown"))
            if self.callbacks.onFailed then
                self.callbacks.onFailed(self.currentSpell, self.currentTarget, self.currentReason, "LINE_OF_SIGHT")
            end
            self:StopMonitor("LINE_OF_SIGHT")
        end
    end
end

-- Check if currently monitoring a cast
function CastMonitor:IsMonitoring()
    return self.isActive
end

-- Get current cast info
function CastMonitor:GetCurrentCast()
    if not self.isActive then
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
    if self.isActive then
        return true
    end
    
    -- Check WoW's casting info as fallback
    local spell, _, _, _, _, endTime = UnitCastingInfo("player")
    return spell ~= nil
end

-- Global instance
GlobalCastMonitor = CastMonitor:New()
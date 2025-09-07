-- CastMonitor.lua
-- Monitors spell casting state and provides feedback on cast success/failure
-- Based on QuickHeal's StartMonitor/StopMonitor system
-- Includes pfUI integration for visual indicators

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

-- pfUI integration for visual indicator
function CastMonitor:CastMonitorHookPfUI()
    if not pfUI then
        return -- pfUI not available
    end
    
    pfUI:RegisterModule("CastMonitorIndicator", "vanilla:tbc", function()
        local HookRefreshUnit = pfUI.uf.RefreshUnit
        function pfUI.uf:RefreshUnit(unit, component)
            -- Always run pfUI's original logic first
            HookRefreshUnit(this, unit, component)
            
            -- Only show indicator on player frame
            if not unit or unit.label ~= "player" then
                if unit and unit.castMonitor then 
                    unit.castMonitor:Hide() 
                end
                return
            end
            
            local unitstr = "player"
            if not UnitExists(unitstr) then
                if unit.castMonitor then 
                    unit.castMonitor:Hide() 
                end
                return
            end
            
            -- Create the indicator frame once
            if not unit.castMonitor then
                unit.castMonitor = CreateFrame("Frame", nil, unit.hp)
                unit.castMonitor.tex = unit.castMonitor:CreateTexture(nil, "OVERLAY")
                unit.castMonitor.tex:SetTexture("Interface\\Buttons\\WHITE8X8")
                unit.castMonitor.tex:SetAllPoints()
                unit.castMonitor:SetFrameStrata("HIGH")
                unit.castMonitor:SetFrameLevel((unit.hp:GetFrameLevel() or 1) + 10)
                unit.castMonitor:Hide()
            end
            
            -- Show/hide based on monitoring state
            if GlobalCastMonitor and GlobalCastMonitor:IsMonitoring() then
                -- Create a small green dot in the center of the health bar
                local width = unit.config.width or 100
                local height = unit.config.height or 20
                local dotSize = math.min(8, math.min(width, height) / 3)
                
                unit.castMonitor:SetWidth(dotSize)
                unit.castMonitor:SetHeight(dotSize)
                unit.castMonitor:ClearAllPoints()
                unit.castMonitor:SetPoint("CENTER", unit.hp, "CENTER", 0, 0)
                
                -- Set green color with some transparency
                unit.castMonitor.tex:SetVertexColor(0.2, 1.0, 0.2, 0.8)
                unit.castMonitor:Show()
            else
                unit.castMonitor:Hide()
            end
        end
    end)
end

-- Initialize pfUI hook
function CastMonitor:InitializePfUI()
    if pfUI then
        self:CastMonitorHookPfUI()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CastMonitor]|r pfUI integration enabled")
    end
end

-- Update pfUI indicator
function CastMonitor:UpdatePfUIIndicator()
    if pfUI and pfUI.uf and pfUI.uf.RefreshUnit then
        -- Refresh the player unit frame to update the indicator
        for _, frame in pairs(pfUI.uf.units) do
            if frame.label == "player" then
                pfUI.uf:RefreshUnit(frame)
                break
            end
        end
    end
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
    
    -- Update pfUI indicator
    self:UpdatePfUIIndicator()
    
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
    
    -- Update pfUI indicator
    self:UpdatePfUIIndicator()
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

-- Initialize pfUI integration when the file loads
if GlobalCastMonitor then
    GlobalCastMonitor:InitializePfUI()
end
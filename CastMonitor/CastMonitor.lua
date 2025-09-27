-- CastMonitor.lua
-- Monitors spell casting state and provides feedback on cast success/failure
-- Based on QuickHeal's StartMonitor/StopMonitor system

---@class CastMonitor
---@field instance ClassMonitorInstance
CastMonitor = MyrkAddon:NewModule("MyrkCastMonitor")
Logs = AceLibrary("MyrkLogs-1.0")

-- Monitoring state
local monitorFrame = nil
local playerUnitUI = nil

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

    if pfUI then
        CastMonitor:CastMonitorHookPfUI()
    end
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
    self:UpdatePfUIIndicator()
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
    

    local msg = string.format("[CastMonitor]Started monitoring %s -> %s (%s)", 
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
    
    local msg = string.format("[CastMonitor] Stopped monitoring: %s", 
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
    self:UpdatePfUIIndicator()
end

-- Event handler
function CastMonitor:OnEvent(event, arg1, arg2, arg3, arg4, arg5)
    if not self.instance.isActive then
        Logs.Debug("CastMonitor received event while not active: " .. (event or "nil"))
        return
    end

    local instance = self.instance
    
    if event == "SPELLCAST_STOP" then
        -- Spell cast completed successfully
        if instance.callbacks and instance.callbacks.onSuccess then
            instance.callbacks.onSuccess(instance.currentSpell, instance.currentTarget, instance.currentReason)
        end
        self:StopMonitor("SPELLCAST_STOP")
        
    elseif event == "SPELLCAST_FAILED" then
        -- Spell cast failed
        if instance.callbacks and instance.callbacks.onFailed then
            instance.callbacks.onFailed(instance.currentSpell, instance.currentTarget, instance.currentReason, arg1)
        end
        self:StopMonitor("SPELLCAST_FAILED: " .. (arg1 or "Unknown"))
        
    elseif event == "SPELLCAST_INTERRUPTED" then
        -- Spell cast was interrupted
        if instance.callbacks and instance.callbacks.onInterrupted then
            instance.callbacks.onInterrupted(instance.currentSpell, instance.currentTarget, instance.currentReason, arg1)
        end
        self:StopMonitor("SPELLCAST_INTERRUPTED: " .. (arg1 or "Unknown"))
        
    elseif event == "UI_ERROR_MESSAGE" and arg1 then
        -- Handle specific error messages
        if arg1 == ERR_SPELL_OUT_OF_RANGE then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[CastMonitor]|r Out of range: %s", 
                instance.currentTarget or "unknown"))
            if instance.callbacks and instance.callbacks.onFailed then
                instance.callbacks.onFailed(instance.currentSpell, instance.currentTarget, instance.currentReason, "OUT_OF_RANGE")
            end
            self:StopMonitor(Reasons.OUT_OF_RANGE)
            
        elseif arg1 == SPELL_FAILED_LINE_OF_SIGHT then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[CastMonitor]|r Line of sight: %s", 
                instance.currentTarget or "unknown"))
            if instance.callbacks and instance.callbacks.onFailed then
                instance.callbacks.onFailed(instance.currentSpell, instance.currentTarget, instance.currentReason, "LINE_OF_SIGHT")
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
    if not self.instance then
        return false
    end

    if self.instance.startTime and (GetTime() - self.instance.startTime) > 5 then
        -- Timeout after 5 seconds
        self:StopMonitor("Timeout")
        return false
    end

    -- Check if we're monitoring a cast
    if self.instance.isActive then
        return true
    end
    
    return false;
    -- Check WoW's casting info as fallback
    -- local spell, _, _, _, _, endTime = UnitCastingInfo("player")
    -- return spell ~= nil
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
            end
            
            -- Show/hide based on monitoring state
            if CastMonitor:IsCasting() then
                unit.castMonitor:Show()
            else
                unit.castMonitor:Hide()
            end

            playerUnitUI = unit.castMonitor
        end
    end)
end

-- Update pfUI indicator
-- TODO: Probably better to just call the PFUI refresh function directly
function CastMonitor:UpdatePfUIIndicator()
    if playerUnitUI then
        if CastMonitor:IsCasting() then
            playerUnitUI:Show()
        else
            playerUnitUI:Hide()
        end
    end
end
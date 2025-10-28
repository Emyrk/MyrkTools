-- MyrkOverlay.lua
-- Shows an overlay above the player for 0.8 seconds when triggered.

MyrkOverlay = MyrkAddon:NewModule("MyrkOverlay")

local overlayFrame = nil
local overlayTexture = "Interface\\AddOns\\MyrkTools\\img\\DruidNaturesGrace"
local overlayDuration = 1.2
local fadeTime = 0.8
local activeTimer = 0
local called = 0

function MyrkOverlay:OnEnable()
    -- Create overlay frame above player
    overlayFrame = CreateFrame("Frame", "MyrkOverlayFrame", UIParent)
    overlayFrame:SetWidth(128)
    overlayFrame:SetHeight(128)
    overlayFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150) -- Above player
    overlayFrame:SetFrameStrata("HIGH")
    overlayFrame:Hide()

    overlayFrame.tex = overlayFrame:CreateTexture(nil, "OVERLAY")
    overlayFrame.tex:SetAllPoints()
    overlayFrame.tex:SetTexture(overlayTexture)
    overlayFrame.tex:SetAlpha(1)
    -- This might rotate it 90 degrees
    overlayFrame.tex:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)

    overlayFrame:SetScript("OnUpdate", function()
        if not overlayFrame:IsShown() then return end

        local now = GetTime()
        local remaining = endTime - now
        if remaining <= 0 then
            overlayFrame:Hide()
        elseif remaining < fadeTime then
            overlayFrame.tex:SetAlpha(remaining / fadeTime)
        end
        lastUpdate = now
    end)

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkOverlay]|r Loaded")
end

function MyrkOverlay:ShowOverlay()
    if not overlayFrame then return end
    endTime = GetTime() + overlayDuration
    overlayFrame.tex:SetAlpha(1)
    overlayFrame:Show()
end

-- Example test command:
-- /run MyrkOverlay:ShowOverlay()
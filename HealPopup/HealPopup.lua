-- HealPopup.lua
-- Shows a popup with healing information when casting heals

HealPopup = MyrkAddon:NewModule("HealPopup")

local popupFrame = nil
local displayDuration = 3.0
local fadeTime = 0.5
local endTime = 0

function HealPopup:OnEnable()
    -- Create popup frame
    popupFrame = CreateFrame("Frame", "HealPopupFrame", UIParent)
    popupFrame:SetWidth(300)
    popupFrame:SetHeight(120)
    popupFrame:SetPoint("CENTER", UIParent, "CENTER", 250, -290) -- Position
    popupFrame:SetFrameStrata("HIGH")
    popupFrame:SetMovable(true)
    popupFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    popupFrame:Hide()

    -- Title text
    popupFrame.title = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    popupFrame.title:SetPoint("TOP", 0, -15)
    popupFrame.title:SetTextColor(0.3, 1.0, 0.3)
    popupFrame.title:SetText("Healing")

    -- Target text
    popupFrame.target = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popupFrame.target:SetPoint("TOP", 0, -35)
    popupFrame.target:SetTextColor(1.0, 1.0, 1.0)

    -- Spell text
    popupFrame.spell = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popupFrame.spell:SetPoint("TOP", 0, -55)
    popupFrame.spell:SetTextColor(0.5, 0.9, 1.0)

    -- Amount text
    popupFrame.amount = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popupFrame.amount:SetPoint("TOP", 0, -75)
    popupFrame.amount:SetTextColor(0.3, 1.0, 0.3)

    -- Damage text
    popupFrame.damage = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popupFrame.damage:SetPoint("TOP", 0, -95)
    popupFrame.damage:SetTextColor(1.0, 0.3, 0.3)

    -- OnUpdate script for fading
    popupFrame:SetScript("OnUpdate", function()
        if not popupFrame:IsShown() then return end

        local now = GetTime()
        local remaining = endTime - now
        if remaining <= 0 then
            popupFrame:Hide()
        elseif remaining < fadeTime then
            popupFrame:SetAlpha(remaining / fadeTime)
        end
    end)

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[HealPopup]|r Loaded")
end

function HealPopup:Show(targetName, spellName, spellRank, healAmount, incomingDamage, hpNeeded)
    if not popupFrame then return end

    -- Format the text
    popupFrame.target:SetText("Target: " .. (targetName or "Unknown"))
    
    local spellText = spellName or "Unknown Spell"
    if spellRank and spellRank > 0 then
        spellText = spellText .. " (Rank " .. spellRank .. ")"
    end
    popupFrame.spell:SetText("Spell: " .. spellText)

    local amountText = ""
    if healAmount and healAmount > 0 then
        amountText = string.format("Heal: %.0f HP", healAmount)
        if hpNeeded and hpNeeded > 0 then
            amountText = amountText .. string.format(" (Need: %.0f)", hpNeeded)
        end
    end
    popupFrame.amount:SetText(amountText)

    local damageText = ""
    if incomingDamage and incomingDamage > 0 then
        damageText = string.format("Incoming Dmg: %.0f", incomingDamage)
    end
    popupFrame.damage:SetText(damageText)

    -- Show the popup
    endTime = GetTime() + displayDuration
    popupFrame:SetAlpha(1)
    popupFrame:Show()
end

-- Example test command:
-- /run HealPopup:Show("PlayerName", "Greater Heal", 5, 2500, 800, 2000)

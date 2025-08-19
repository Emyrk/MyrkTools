MyrkAddon = LibStub("AceAddon-3.0"):NewAddon("MyrkAddon", "AceConsole-3.0")
MyrkTools = {}

function MyrkTools:Initialize()

end

-- Primary frame
local f = CreateFrame("MessageFrame", "AutoMyrk", UIParent)
f:SetWidth(800)  -- very wide
f:SetHeight(200) -- very tall
f:SetPoint("CENTER", UIParent, "CENTER", 500, -400)
f:SetInsertMode("TOP")
f:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE") -- massive font
f:SetTimeVisible(1.0)                        -- stays visible for 3 seconds
f:SetFadeDuration(1.0)                       -- 1 sec fade
f:SetJustifyH("CENTER")
f:SetJustifyV("MIDDLE")
f:SetClampedToScreen(true)
f:Show()


-- make it movable
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
-- f:SetScript("OnDragStart", function(self) self:StartMoving() end)
-- f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- helper function
function AutoMyrk:Info(msg, r, g, b)
  self:AddMessage(msg, r or 1, g or 0.2, b or 0.2)
end

function HostileTarget()
  if not UnitExists("target") then return false end
  if UnitIsDead("target") then return false end
  if UnitIsFriend("player", "target") then return false end
  -- if UnitCanAttack("player", "target") ~= true then return false end
  return true
end

function BoolToString(val, yes, no)
  if val then
    return yes or "true"
  else
    return no or "false"
  end
end

function InCombat()
  return UnitAffectingCombat("player") == 1
end

-- function MyrkTools:DebugSlot()
--   for slot = 1, 120 do
--     local t, id = GetActionText(slot)
--     if t == "spell" then
--       local name = GetSpellName(id, BOOKTYPE_SPELL)
--       if name == "Shoot" then
--         print("Shoot is in slot", slot)
--       end
--     end
--   end
-- end

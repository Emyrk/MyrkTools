MyrkAddon = LibStub("AceAddon-3.0"):NewAddon("MyrkAddon", "AceConsole-3.0", "AceEvent-3.0")
MyrkTools = {}

function MyrkTools:Initialize()

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

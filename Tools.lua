MyrkAddon = LibStub("AceAddon-3.0"):NewAddon("MyrkAddon", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
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

-- Add this to your Tools.lua file
function MyrkTools:IsDrinking()
    for i = 1, 32 do
        local buffTexture, buffApplications = UnitBuff("player", i)
        if not buffTexture then
            break
        end

        if string.find(buffTexture, "Interface\\Icons\\INV_Drink_%d+") then
            return true
        end
    end
    return false
end
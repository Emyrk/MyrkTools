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
function IsDrinking()
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

function PrintTable(t, indent)
  indent = indent or 0
  local spacing = string.rep("  ", indent)
  
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(spacing .. tostring(k) .. ":")
      PrintTable(v, indent + 1)
    else
      print(spacing .. tostring(k) .. ": " .. tostring(v))
    end
  end
end

-- Calculate expected unit health after incoming damage
-- Returns the unit's current health minus expected incoming damage
function ExpectedUnitHealth(unitName)
  if not unitName then
    return 0
  end
  
  -- Get current health
  local currentHealth = UnitHealth(unitName)
  if not currentHealth or currentHealth <= 0 then
    return 0
  end
  
  -- Get expected incoming damage from DamageComm
  local incomingDamage = 0
  if UnitGetIncomingDamage then
    incomingDamage = UnitGetIncomingDamage(unitName) or 0
  end
  
  -- Calculate expected health (don't go below 0)
  local expectedHealth = currentHealth - incomingDamage
  return math.max(0, expectedHealth)
end
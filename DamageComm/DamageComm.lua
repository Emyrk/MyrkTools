local MAJOR_VERSION = "DamageComm-1.0"
local MINOR_VERSION = "$Revision: 0 $"

DamageComm = MyrkAddon:NewModule("MyrkDamageComm")

function DamageComm:OnEnable()
  if not pfUI then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkDamageComm]|r not loaded, no pfUI found")
    return
  end

  if not ShaguDPS then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkDamageComm]|r not loaded, no ShaguDPS found")
    return
  end
  self:DamageCommHookPfUI()
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkDamageComm]|r Loaded")
end

---@param unitname string Player name
---@return number recent damage taken in last 5 seconds.
function UnitGetIncomingDamage(unitname)
  if not ShaguDPS then
    return 0
  end
  
  -- Cleanup if necessary
  -- ShaguDPS.data["taken"]
  if not ShaguDPS.data or 
    not ShaguDPS.data["recent"] or 
    not ShaguDPS.data["recent"][1] or 
    not ShaguDPS.data["recent"][1][unitname] or
    not ShaguDPS.data["recent"][1][unitname]["_sum"] then
    return 0
  end

  if ShaguDPS.data["taken"][1][unitname]["_tick"] then
    local now = GetTime()
    if now - ShaguDPS.data["taken"][1][unitname]["_tick"] > 5 then
      return 0
    end
  end

  local recent = ShaguDPS.data["recent"][1][unitname]["_sum"]
  return recent or 0
end

function DamageComm:DamageCommHookPfUI()
  pfUI:RegisterModule("DamageOverlay", "vanilla:tbc", function()
    local HookRefreshUnit = pfUI.uf.RefreshUnit
    function pfUI.uf:RefreshUnit(unit, component)
      -- Always run pfUI’s original logic
      HookRefreshUnit(this, unit, component)
      -- print all table elements of the unit
      -- for k, v in pairs(unit) do
      --   DEFAULT_CHAT_FRAME:AddMessage("unit["..k.."]="..tostring(v))
      -- end

      -- Only party members (party1..party4)
      if not unit or not (unit.label == "party" or unit.label == "player") then
        if unit and unit.incDmg then unit.incDmg:Hide() end
        return
      end

      local unitstr = (unit.label or "") .. (unit.id or "")
      if unitstr == "" or not UnitExists(unitstr) then
        if unit.incDmg then unit.incDmg:Hide() end
        return
      end

      -- Create once
      if not unit.incDmg then
        unit.incDmg = CreateFrame("Frame", nil, unit.hp)
        unit.incDmg.tex = unit.incDmg:CreateTexture(nil, "OVERLAY")
        unit.incDmg.tex:SetTexture(pfUI.media["img:bar"])
        unit.incDmg.tex:SetAllPoints()
        unit.incDmg:SetFrameStrata("MEDIUM")
        unit.incDmg:SetFrameLevel((unit.hp:GetFrameLevel() or 1) + 5)
        unit.incDmg:Hide()
      end

      local width  = unit.config.width
      local height = unit.config.height
      local health, maxHealth = UnitHealth(unitstr), UnitHealthMax(unitstr)
      if maxHealth <= 0 or health <= 0 then unit.incDmg:Hide() 
        return 
      end

      local name, _ = UnitName(unitstr)
      local dmg = UnitGetIncomingDamage(name)
      if not dmg or dmg <= 0 then unit.incDmg:Hide() return end

      -- Clamp to visible health
      if dmg > health then dmg = health end

      -- Half-height red strip anchored to the top so the bottom half stays visible
      local barH = math.max(1, math.floor(height / 4))
      unit.incDmg:SetHeight(barH)
      unit.incDmg.tex:SetVertexColor(0.9, 0.15, 0.15, 1)

      if unit.config.verticalbar == "0" then
        -- Horizontal bars
        local healthWidth = width * (health / maxHealth)
        local dmgWidth    = width * (dmg   / maxHealth)
        unit.incDmg:ClearAllPoints()

        unit.incDmg:SetPoint("BOTTOMLEFT", 0, "BOTTOMLEFT", x, 0)
        if unit.config.invert_healthbar == "1" then
          -- Inverted: health fills right->left; place band at the right edge of the health region
          -- TODO: This works like healcomm
          local x = width - healthWidth
          unit.incDmg:SetPoint("BOTTOMLEFT", unit.hp.bar, "BOTTOMLEFT", x, 0)
        else
          -- Start from the left.
          local x = healthWidth - dmgWidth
          unit.incDmg:SetPoint("BOTTOMLEFT", 0, "BOTTOMLEFT", x, 0)
          -- Normal: health fills left->right; place band at the right edge of the health region
          -- local x = healthWidth - dmgWidth
          -- if x < 0 then x = 0 end
          -- unit.incDmg:SetPoint("TOPLEFT", unit.hp.bar, "TOPLEFT", x, 0)
        end

        unit.incDmg:SetWidth(dmgWidth)
        unit.incDmg:Show()
      else
        -- Optional: implement if you use vertical health bars. For now, hide.
        unit.incDmg:Hide()
      end
    end
  end)
end


DamageCommLib = {}
DamageCommLib.UnitGetIncomingDamage = UnitGetIncomingDamage
AceLibrary:Register(DamageCommLib, MAJOR_VERSION, MINOR_VERSION)
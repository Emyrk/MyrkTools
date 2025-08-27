DamageComm = MyrkAddon:NewModule("MyrkDamageComm")

function DamageComm:OnEnable()
  self:DamageCommHookPfUI()
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkDamageComm]|r Loaded")
end

function DamageComm:DamageCommHookPfUI()
  pfUI:RegisterModule("DamageOverlay", "vanilla:tbc", function()
    local getIncomingDamage = function(unitstr)
      -- Adapt this to your DamageComm API.
      -- A) If you provide a UnitGetIncomingDamage(unit) API:
      if DamageComm and DamageComm.UnitGetIncomingDamage then
        return DamageComm:UnitGetIncomingDamage(unitstr) or 0
      end
      if DamageComm and DamageComm.GetIncomingDamage then
        return DamageComm:GetIncomingDamage(unitstr) or 0
      end
      -- B) If you ship an Ace library:
      if AceLibrary and AceLibrary:HasInstance("DamageComm-1.0") then
        local DC = AceLibrary("DamageComm-1.0")
        if DC and DC.UnitGetIncomingDamage then
          return DC:UnitGetIncomingDamage(unitstr) or 0
        end
      end
      return 200
    end

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

      local dmg = getIncomingDamage(unitstr)
      if not dmg or dmg <= 0 then unit.incDmg:Hide() return end

      -- Clamp to visible health
      if dmg > health then dmg = health end

      -- Half-height red strip anchored to the top so the bottom half stays visible
      local barH = math.max(1, math.floor(height / 2))
      unit.incDmg:SetHeight(barH)
      unit.incDmg.tex:SetVertexColor(0.9, 0.15, 0.15, 1)

      if unit.config.verticalbar == "0" then
        -- Horizontal bars
        local healthWidth = width * (health / maxHealth)
        local dmgWidth    = width * (dmg   / maxHealth)
        unit.incDmg:ClearAllPoints()

        unit.incDmg:SetPoint("TOPLEFT", 0, "TOPLEFT", x, 0)
        if unit.config.invert_healthbar == "1" then
          -- Inverted: health fills right->left; place band at the right edge of the health region
          -- TODO: This works like healcomm
          local x = width - healthWidth
          unit.incDmg:SetPoint("TOPLEFT", unit.hp.bar, "TOPLEFT", x, 0)
        else
          -- Start from the left.
          local x = healthWidth - dmgWidth
          unit.incDmg:SetPoint("TOPLEFT", 0, "TOPLEFT", x, 0)
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
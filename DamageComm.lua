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
      -- run pfUI's original logic first so sizes are up-to-date
      HookRefreshUnit(this, unit, component)

      if not unit or not unit.hp or not unit.config then return end
      local unitstr = (unit.label or "") .. (unit.id or "")
      if unitstr == "" then return end
      if not UnitExists(unitstr) then return end

      -- create once
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
      if maxHealth <= 0 then unit.incDmg:Hide() return end

      local dmg = getIncomingDamage(unitstr)
      if not dmg or dmg <= 0 or health <= 0 then
        unit.incDmg:Hide()
        return
      end

      -- clamp damage to current health (only show the part that can actually remove visible HP)
      if dmg > health then dmg = health end

      -- size: half height as requested
      local barH = math.max(1, math.floor(height / 2))
      unit.incDmg:SetHeight(barH)

      if unit.config.verticalbar == "0" then
        -- horizontal bars
        local healthWidth = width * (health / maxHealth)
        local dmgWidth = width * (dmg / maxHealth)

        unit.incDmg:ClearAllPoints()
        if unit.config.invert_healthbar == "1" then
          -- inverted: health fills from right -> left. Overlay at the right edge of the health region.
          local x = width - dmgWidth
          unit.incDmg:SetPoint("TOPLEFT", unit.hp.bar, "TOPLEFT", x, 0)
        else
          -- normal: health fills left -> right. Overlay at the right edge of the health region.
          local x = healthWidth - dmgWidth
          if x < 0 then x = 0 end
          unit.incDmg:SetPoint("TOPLEFT", unit.hp.bar, "TOPLEFT", x, 0)
        end

        unit.incDmg:SetWidth(dmgWidth)
        unit.incDmg.tex:SetVertexColor(0.9, 0.15, 0.15, 1)
        unit.incDmg:Show()
      else
        -- vertical bars (optional draft; confirm desired orientation)
        -- Assumption: bar grows bottom -> top when not inverted.
        local healthHeight = height * (health / maxHealth)
        local dmgHeight = height * (dmg / maxHealth)
        if unit.config.invert_healthbar == "1" then
          -- inverted: top -> bottom. Draw at top edge of health region.
          local y = 0 -- top anchored, use height/positioning as needed
          unit.incDmg:ClearAllPoints()
          unit.incDmg:SetPoint("TOPLEFT", unit.hp.bar, "TOPLEFT", 0, -y)
          unit.incDmg:SetPoint("TOPRIGHT", unit.hp.bar, "TOPRIGHT", 0, -y)
          unit.incDmg:SetHeight(dmgHeight)
        else
          -- normal: bottom -> top. Draw at top edge (inside health).
          local y = healthHeight - dmgHeight
          unit.incDmg:ClearAllPoints()
          unit.incDmg:SetPoint("TOPLEFT", unit.hp.bar, "BOTTOMLEFT", 0, y)
          unit.incDmg:SetPoint("TOPRIGHT", unit.hp.bar, "BOTTOMRIGHT", 0, y)
          unit.incDmg:SetHeight(dmgHeight)
        end
        unit.incDmg.tex:SetVertexColor(0.9, 0.15, 0.15, 1)
        unit.incDmg:Show()
      end
    end
  end)
end

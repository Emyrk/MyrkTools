-- SpellQueue allows queuing of spells to be cast on the next available opportunity
-- when using a strategy engine. The queued spell will have an indicator on the action bar.
---@class MyrkSpellQueue : AceEvent-3.0
---@field queued Action|nil
---@field queuedAt number|nil
SpellQueue = MyrkAddon:NewModule("MyrkSpellQueue", "AceEvent-3.0")

-- function SpellQueue:evaluate(engine)
--   print("SpellQueue:Evaluate called")
--   return self:Dequeue()
-- end

function SpellQueueEvaluate()
  return function (engine)
    local dq = SpellQueue:Dequeue()
    return dq
  end
end

function SpellQueue:OnEnable()
  self.queued = nil

  if ActionButton1 then
    for i = 1,12 do self:SetupButton("ActionButton"..i) end
		for i = 1,12 do self:SetupButton("MultiBarRightButton"..i) end
		for i = 1,12 do self:SetupButton("MultiBarLeftButton"..i) end
		for i = 1,12 do self:SetupButton("MultiBarBottomRightButton"..i) end
		for i = 1,12 do self:SetupButton("MultiBarBottomLeftButton"..i) end
		for i = 1,12 do self:SetupButton("BonusActionButton"..i) end
  end

  if pfActionBarLeftButton1 then
    for i = 1,12 do self:SetupButton("pfActionBarLeftButton"..i) end
    for i = 1,12 do self:SetupButton("pfActionBarRightButton"..i) end
    for i = 1,12 do self:SetupButton("pfActionBarTopButton"..i) end
    for i = 1,12 do self:SetupButton("pfActionBarMainButton"..i) end
  end
  
  if SpellButton1 then
    for i = 1,12 do self:SetupButton("SpellButton"..i) end
  end


  local localizedClass, englishClass = UnitClass("player")
  if englishClass == "PRIEST" then
    -- Whisper the priest if you want something!
    self:RegisterEvent("CHAT_MSG_WHISPER", "PriestWhisper")
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[SpellQueue]|r Enabled ")
end

function SpellQueue:PriestWhisper()
    local msg = arg1
    local sender = arg2
    local text = string.lower(msg or "")

    local player = PartyMonitor:PlayerByName(sender)
    if not player then
      return
    end

    if text == "shield" then
      Logs.Info("Queuing PWS for " .. player.name)
      SpellQueue:PWS(player, "priest_whisper_shield")
      return
    end

    if text == "renew" then
      Logs.Info("Queuing Renew for " .. player.name)
      SpellQueue:Renew(player, "priest_whisper_renew")
      return
    end
end

function SpellQueue:PWS(player, reason)
  local ok, spellID = self:checkSpell("Power Word: Shield")
  if not ok then
    return
  end


  local cant = DecisionEngine:hasBuff(player.id, "Spell_Holy_PowerWordShield") or
      DecisionEngine:hasDebuff(player.id, "AshesToAshes")
  if cant then
    return
  end

  self:Enqueue(Action:Heal(spellID, player.id, reason))
end

function SpellQueue:Renew(player, reason)
  local ok, spellID = self:checkSpell("Renew")
  if not ok then
    return
  end


  local cant = DecisionEngine:hasBuff(player.id, "Spell_Holy_Renew")
  if cant then
    return
  end

  self:Enqueue(Action:Heal(spellID, player.id, reason))
end

function SpellQueue:CastSpellByName(spellName, onSelf)
  if not Auto:IsGlobalCasting() then
    -- Pass through to normal
    CastSpellByName(spellName, onSelf)
    return
  end

  local ok, spellID = self:checkSpell(spellName)
  if not ok then
    return
  end

  self:Enqueue(Action:Cast(spellID, "target", "queued_due_to_global_casting"))
end

---@param action Action
function SpellQueue:Enqueue(action)
  local previous = self:Dequeue()

  if action.spellID == nil or action.globalSpellID == nil or action.spellName == "" then
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SpellQueue]|r Spell ID, Global Spell ID, and Spell Name required to enqueue"))
    return
  end

  if (previous ~= nil and previous.globalSpellID ~= action.globalSpellID) or previous == nil then
    Logs.Info(string.format("Enqueued spell: %s (ID: %d, GlobalID: %d)", action.spellName, action.spellID, action.globalSpellID))
  end

  self.queued = action
  self.queuedAt = GetTime()
end

function SpellQueue:checkSpell(spellName)
  local spellData = HealTable:MaxRankData(spellName)
  if spellData == nil then
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SpellQueue]|r Unknown spell name: %s", spellName))
    return false
  end

  if spellData.manacost > UnitMana("player") then
    return false
  end

  local spellID = HealTable:MaxRankID(spellName)
  if spellID == nil then
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SpellQueue]|r Unknown spell name: %s", spellName))
    return false
  end

  -- Global CD is 1.5, so casting a spell puts others on a 1.5+ second cooldown
  -- Just prevent queuing if the spell is on cooldown for more than that
  local _, duration = GetSpellCooldown(spellID, BOOKTYPE_SPELL) 
  if duration > 1.5 then
    return false
  end

  return true, spellID
end

function SpellQueue:Dequeue()
  if not self.queued or self.queuedAt == nil then
    self.queuedAt = nil
    return nil
  end

  if GetTime() - self.queuedAt > 10 then 
    self.queuedAt = nil
    self.queued = nil
    return nil
  end

  local action = self.queued
  self.queued = nil
  self.queuedAt = nil
  return action
end

-- buttonID is like "ActionButton1"
function SpellQueue:SetupButton(buttonID)
  local oldbutton = getglobal(buttonID)
  if not oldbutton then
    return
  end

  oldbutton.previousUpdate = oldbutton:GetScript("OnUpdate")
  oldbutton:SetScript("OnUpdate", self.ButtonUpdate)
  if oldbutton.queueText ~= nil then
    return
  end

  oldbutton.queueText = oldbutton:CreateFontString(nil, "OVERLAY")
  oldbutton.queueText:SetPoint("TOPLEFT", oldbutton, "TOPLEFT", 0, 0)
  oldbutton.queueText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
  oldbutton.queueText:SetText("*")
  oldbutton.queueText:SetTextColor(0, 255, 0)
  oldbutton.queueText:Show()

  -- local name = buttonID
  -- local sp = getglobal(name)
  -- if sp then
  --   print(name .. " -> " .. tostring(sp:GetID()))
  -- end
end

function SpellQueue:ButtonUpdate()
  if this.previousUpdate then
		this.previousUpdate()
	end

  if SpellQueue.queued == nil then
    this.queueText:Hide()
    return
  end

  local _, type, id = GetActionText(this:GetID())
  if type == "SPELL" and id ~= SpellQueue.queued.globalSpellID then 
    this.queueText:Hide()
    -- this.queueText:Show()
    -- this.queueText:SetText(id)
    return
  end
  if type == "MACRO" then
    local _, _, body, _ = GetMacroInfo(id)
    local tt = ShowTooltip(body)
    local show = tt == SpellQueue.queued.spellName

    if not show then
      this.queueText:Hide()
      return
    end
  end

  if type ~= "SPELL" and type ~= "MACRO" then
    this.queueText:Hide()
    return
  end
  
  this.queueText:Show()
end

---@param macroText string
---@return string|nil
function ShowTooltip(macroText) 
  macroText = string.gsub(macroText, "^%s+", "")
  local _, _, tt = string.find(macroText, "#showtooltip%s+([^\r\n]+)")
  return tt
end

-- Help find pf ui action buttons
local function FindButtons()
  for name, frame in pairs(_G) do
    if type(frame) == "table" and type(frame.GetObjectType) == "function" and frame:GetObjectType() == "Button" then
      if (string.find(name, "Action") or string.find(name, "Button")) and string.find(name, "pf") then
        DEFAULT_CHAT_FRAME:AddMessage("Found: " .. name)
      end
    end
  end
end

-- FindButtons()

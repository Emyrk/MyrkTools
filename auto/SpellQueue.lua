-- SpellQueue allows queuing of spells to be cast on the next available opportunity
-- when using a strategy engine. The queued spell will have an indicator on the action bar.
---@class MyrkSpellQueue : AceEvent-3.0
---@field queued Action|nil
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
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[SpellQueue]|r Enabled ")
end

---@param action Action
function SpellQueue:Enqueue(action)
  self:Dequeue()

  if action.spellID == nil then
    return
  end

  self.queued = action
end

function SpellQueue:Dequeue()
  if not self.queued then
    return nil
  end
  local action = self.queued
  self.queued = nil
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
  if type ~= "SPELL" then 
    this.queueText:Hide()
    return
  end

  if id ~= SpellQueue.queued then
    this.queueText:Hide()
    return
  end
  
  this.queueText:Show()
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

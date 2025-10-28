Debounce = {}
Debounce.__index = Debounce
function Debounce:New(cooldown)
  local instance = {
    lastTime = 0,
    cooldown = cooldown or 0.5, -- seconds
  }
  setmetatable(instance, Debounce)
  return instance
end

function Debounce:evaluate(engine)
  local now = GetTime()
  if now - self.lastTime >= self.cooldown then
    self.lastTime = now
    return nil
  end
  return Action:Busy("debounce")
end

---@class HealSpell
---@field playerType string "player", "tank", or "party"
---@field spellName string
---@field spellRank? number
---@field smartRank? boolean
---@field incDmgTime? number seconds to expect for incoming damage
---@field targetType? string TODO REMOVE
---@field instant boolean
---@field minimumMana? number Minimum mana required to cast
---@field miniumPartyHPct? number Minimum party health percentage to consider. If less, then the heal skips
---@field minimumTTD? number Minimum party ttd to consider. If less, then the heal skips
---@field pct number
---@field prevent fun(engine: any, player: AllyPlayer): boolean|nil If returns true, skip this target
HealSpell = {}
HealSpell.__index = HealSpell

---Constructor
---@param hp HealSpell
---@return HealSpell
function HealSpell:new(hp)
  return setmetatable(hp, self)
end

---@param engine DecisionEngine
function HealSpell:evaluate(engine)

  DebugExecution(self.spellName .. " healspell evaluate")
  if self.instant and not engine.ctx.instantHeal then
 
    return nil -- Cannot cast instant heal
  end
  if not self.instant and not engine.ctx.channelHeal then
 
    return nil -- Cannot cast channel heal
  end
  if self.minimumMana and self.minimumMana ~= 0 then
    local mana = UnitMana("player")
    if mana < self.minimumMana then
      return nil
    end
  end

  if self.miniumPartyHPct and engine.ctx.minimumHealthPct < self.miniumPartyHPct then
    DebugExecution(self.spellName .. " evaluate failed min party hpct at " .. tostring(engine.ctx.minimumHealthPct) .. " < " .. tostring(self.miniumPartyHPct))
    return nil
  end

  if self.minimumTTD and engine.ctx.minimumTTD < self.minimumTTD then
    DebugExecution(self.spellName .. " evaluate failed min party ttd")
    return nil
  end

  local action = PerPlayer(self.playerType or "party", function(engine, player)
    return self:evaluatePlayer(engine, player)
  end)(engine)
  return action
end

---Evaluate the heal decision.
---@param engine any
---@return table|nil
function HealSpell:evaluatePlayer(engine, player)
  if not player then
    Logs.Error("HealSpell:evaluate called without player")
    return nil
  end

  local spellid = nil
  if self.spellRank then
    spellid = HealTable:RankID(self.spellName, self.spellRank)
  else
    spellid = HealTable:MaxRankID(self.spellName)-- Highest rank
  end

  local _, duration = GetSpellCooldown(spellid, BOOKTYPE_SPELL)
  if duration ~= 0 then
    Logs.Debug("cooldown")
    return nil -- Spell is on cooldown
  end
  if not player.castable or not player.healable then
    return nil
  end

  local healthPct = player:GetHealthPercent()
  if healthPct < self.pct then
    if self.prevent and self.prevent(engine, player) then
      -- preventing this heal
    else
      local hp_needed = player:HPNeeded(self.incDmgTime or 0)
      if self.smartRank then
        spellid = HealTable:RankID(self.spellName, GetOptimalRank(self.spellName, hp_needed))
      end

      return Action:Heal(spellid, player.id, "heal")
    end
  end
  return nil
end
  


Wanding = {}
Wanding.__index = Wanding
function Wanding:New()
  local wandSlot = nil
  for slot = 1, 120 do
    local _, _, id = GetActionText(slot)
    if id == 5019 then
      wandSlot = slot
      Logs.Info("Wand slot found = " .. slot)
      break
    end
  end

  local instance = {
    wandSlot = wandSlot,
  }
  setmetatable(instance, Wanding)
  return instance
end

function Wanding:evaluate(engine)
  if self.wandSlot ~= nil and
    IsAutoRepeatAction(self.wandSlot) == 1 then
    return Action:Busy("already wanding") -- Already wanding
  end

  if UnitExists("target") and UnitCanAttack("player", "target") then
      return Action:Cast("Shoot", "target", "idle_wand")
  end

  return nil
end

function Smite()
  return function(engine)
    if not HostileTarget() then
      return nil
    end

    local m = UnitMana("player") / UnitManaMax("player");
    if m < 0.8 then
      return nil
    end


    local _, duration = GetSpellCooldown(HealTable:MaxRankID("Mind Blast"), BOOKTYPE_SPELL)
    if duration == 0 then

      return Action:Cast("Mind Blast", "target", "mind blast")
    end

    return Action:Cast("Smite", "target", "smite")
  end
end

function SmartBuff(manaThreshold)
  return function(engine)
    if not SMARTBUFF_command then
      return nil
    end
    
    local pct = UnitMana("player") / UnitManaMax("player");
    if pct < manaThreshold then
      return nil
    end

    return Action:Custom(function (engine)
      SMARTBUFF_command("")
    end, "smart_buff")
  end
end
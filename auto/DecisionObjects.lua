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
---@field spellName string
---@field spellRank? number
---@field targetType string
---@field instant boolean
---@field pct number
---@field prevent fun(unitID: string): boolean|nil If returns true, skip this target
HealSpell = {}
HealSpell.__index = HealSpell

---Constructor
---@param hp HealSpell
---@return HealSpell
function HealSpell:new(hp)
  return setmetatable(hp, self)
end

---Evaluate the heal decision.
---@param engine any
---@return table|nil
function HealSpell:evaluate(engine)
  if self.instant and not engine.ctx.instantHeal then
    return nil
  elseif not engine.ctx.channelHeal then
    return nil
  end

  local ranks = Spells[self.spellName]
  local spellid = nil
  if self.spellRank then
    spellid = ranks[self.spellRank]
  else
    spellid = ranks[table.getn(ranks) - 1] -- Highest rank
  end

  local _, duration = GetSpellCooldown(spellid, BOOKTYPE_SPELL)
  if duration ~= 0 then
    Logs.Debug("cooldown")
    return nil -- Spell is on cooldown
  end

  local action = nil
  engine:ForEach(self.targetType, function(player)
    if not player.castable or not player.healable then
      return false
    end

    local healthPct = engine:getHealthPercent(player.id)
    if healthPct < self.pct then
      if self.prevent and self.prevent(engine, player.id) then
        -- preventing this heal
      else
        action = Action:Heal(spellid, player.id, "heal")
        return true
      end
    end
  end)

  return action
end

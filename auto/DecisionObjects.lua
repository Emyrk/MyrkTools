---@class HealSpell
---@field spellName string
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
        action = Action:Heal(self.spellName, player.id, "heal")
        return true
      end
    end
  end)

  return action
end

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
---@field spellName string|fun(hp_needed: number): string
---@field spellRank? number
---@field smartRank? boolean
---@field incDmgTime? number seconds to expect for incoming damage
---@field targetType string
---@field instant boolean
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

function HealSpell:SpellName(hp_needed) 
  local name = self.spellName
  if type(self.spellName) == "function" then
    name = self.spellName(hp_needed)
  end 
  return name
end

function HealSpell:SpellID(hp_needed)
  local name = self:SpellName(hp_needed)
  local ranks = Spells[name]
  local spellid = nil

  if self.spellRank then
    spellid = ranks[self.spellRank]
  else
    spellid = ranks[table.getn(ranks)] -- Highest rank
  end

  if self.smartRank then
    local optimalRank = GetOptimalRank(name, hp_needed)
    spellid = ranks[optimalRank]
  end

  return spellid
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

  -- Assume a lot of health is needed. We will downrank later if needed.
  local spellid = self:SpellID(5000)
  local _, duration = GetSpellCooldown(spellid, BOOKTYPE_SPELL)
  if duration ~= 0 then
    Logs.Debug("cooldown")
    return nil -- Spell is on cooldown
  end

  local action = nil
  engine:ForEach(self.targetType, function(player)
      ---@cast player AllyPlayer
    if not player.castable or not player.healable then
      return false
    end

    local healthPct = player:GetHealthPercent()
    if healthPct < self.pct then
      if self.prevent and self.prevent(engine, player) then
        -- preventing this heal
      else
        local hp_needed = player:HPNeeded(self.incDmgTime or 0)
        if self.smartRank then
          spellid = self:SpellID(hp_needed)
        end

        action = Action:Heal(spellid, player.id, "heal")
        return true
      end
    end
  end, "time_to_death") -- Sort by time to death

  return action
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
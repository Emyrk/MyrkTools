---@enum actions
ACTIONS = {
	busy = "busy",
  cast = "cast",
  heal = "heal",
  error = "error",
  custom = "custom",
}


---@class Action
---@field doFunction fun(engine) A function that does something
---@field spellID? string The spell id to cast.
---@field spellName? string The spell name to cast.
---@field globalSpellID? number The global spell id, used for comparisons
---@field target_id? string The target unit ID.
---@field action actions What action to execute.
---@field reason string Explain why no action should be taken. For debugging purposes.
Action = {}
Action.__index = Action

---comment This exits the decision tree and still holds control of the character.
---@param reason string explain why no action should be taken.
---@return table
function Action:Busy(reason)
    local instance = {
      action = ACTIONS.busy,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end

function Action:Error(reason)
    local instance = {
      action = ACTIONS.error,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end

function Action:Heal(spellID, target_id, reason)
  local name, rankName, globalSpellID = GetSpellName(spellID, BOOKTYPE_SPELL)

    local instance = {
      action = ACTIONS.heal,
      spellID = spellID,
      globalSpellID = globalSpellID,
      spellName = name,
      target_id = target_id,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end

function Action:CastByName(spellName, target_id, reason)
    local instance = {
      action = ACTIONS.cast,
      spellName = spellName,
      target_id = target_id,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end

function Action:Cast(spellID, target_id, reason)
    local name, rankName, globalSpellID = GetSpellName(spellID, BOOKTYPE_SPELL)

    local instance = {
      action = ACTIONS.cast,
      spellID = spellID,
      globalSpellID = globalSpellID,
      spellName = name,
      target_id = target_id,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end

---@param doFunction fun(engine)  A function that does something
function Action:Custom(doFunction, reason)
    local instance = {
      action = ACTIONS.custom,
      doFunction = doFunction,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end
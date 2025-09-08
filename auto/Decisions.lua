---@enum actions
ACTIONS = {
	busy = "busy",
  cast = "cast",
  heal = "heal",
  error = "error",
}


---@class Action
---@field spellID? string The spell id to cast.
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
    local instance = {
      action = ACTIONS.heal,
      spellID = spellID,
      target_id = target_id,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end

function Action:Cast(spellID, target_id, reason)
    local instance = {
      action = ACTIONS.cast,
      spellID = spellID,
      target_id = target_id,
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end
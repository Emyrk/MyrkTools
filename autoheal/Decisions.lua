Action = {}
Action.__index = Action

---comment This exits the decision tree and still holds control of the character.
---@param reason string explain why no action should be taken.
---@return table
function Action:Busy(reason)
    local instance = {
      action = "busy",
      reason = reason,
    }
    setmetatable(instance, Action)
    return instance
end
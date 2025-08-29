---@enum actions
local ACTIONS = {
	busy = "busy",
}


---@class Action
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
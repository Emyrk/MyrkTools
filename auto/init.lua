-- init.lua
-- Initialization file for the AutoHeal system
-- This file loads all components in the correct order

-- Load core decision engine
loadfile("autoheal/DecisionEngine.lua")()

-- Load decision node functions
loadfile("autoheal/DecisionNodes.lua")()

-- Load healing strategies
loadfile("autoheal/HealingStrategy.lua")()

-- Load main AutoHeal module
loadfile("autoheal/AutoHeal.lua")()

-- Register slash commands for configuration
SLASH_AUTOHEAL1 = "/autoheal"
SLASH_AUTOHEAL2 = "/ah"

function SlashCmdList.AUTOHEAL(msg)
    local command, arg = string.match(msg, "^(%S+)%s*(.*)$")
    if not command then command = msg end
    command = string.lower(command)
    
    local autoHeal = MyrkAddon:GetModule("MyrkAuto")
    if not autoHeal then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Auto]|r Module not loaded")
        return
    end
    
    if command == "heal" then
        -- Manual healing trigger
        local success = autoHeal:PerformHealing()
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AutoHeal]|r No healing action taken")
        end
        
    elseif command == "addtank" then
        if arg and arg ~= "" then
            autoHeal:AddTank(arg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AutoHeal]|r Usage: /autoheal addtank <name>")
        end
        
    elseif command == "removetank" or command == "deltank" then
        if arg and arg ~= "" then
            autoHeal:RemoveTank(arg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AutoHeal]|r Usage: /autoheal removetank <name>")
        end
        
    elseif command == "tanks" or command == "listtanks" then
        autoHeal:ListTanks()
        
    elseif command == "strategy" then
        if arg and arg ~= "" then
            SetHealingStrategy(arg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AutoHeal]|r Usage: /autoheal strategy <default|conservative|aggressive>")
        end
        
    elseif command == "help" or command == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoHeal]|r Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /autoheal heal - Trigger healing manually")
        DEFAULT_CHAT_FRAME:AddMessage("  /autoheal addtank <name> - Add a tank to the list")
        DEFAULT_CHAT_FRAME:AddMessage("  /autoheal removetank <name> - Remove a tank from the list")
        DEFAULT_CHAT_FRAME:AddMessage("  /autoheal tanks - List configured tanks")
        DEFAULT_CHAT_FRAME:AddMessage("  /autoheal strategy <type> - Set healing strategy")
        DEFAULT_CHAT_FRAME:AddMessage("    Available strategies: default, conservative, aggressive")
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[AutoHeal]|r Unknown command. Use /autoheal help for help")
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoHeal]|r System initialized. Use /autoheal help for commands")
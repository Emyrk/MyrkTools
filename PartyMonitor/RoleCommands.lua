-- RoleCommands.lua
-- Slash commands for managing party member roles

-- Register slash commands for role management
-- SLASH_PARTYROLES1 = "/role"
-- SLASH_PARTYROLES2 = "/roles"

-- function SlashCmdList.PARTYROLES(msg)
--     local command, arg1, arg2 = string.match(msg, "^(%S+)%s*(%S*)%s*(.*)$")
--     if not command then command = msg end
--     command = string.lower(command)
    
--     local partyMonitor = MyrkAddon:GetModule("MyrkPartyMonitor")
--     if not partyMonitor then
--         DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Roles]|r PartyMonitor not loaded")
--         return
--     end
    
--     if command == "set" then
--         if arg1 == "" or arg2 == "" then
--             DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Roles]|r Usage: /role set <player> <role>")
--             ShowAvailableRoles()
--             return
--         end
        
--         -- Validate and set role
--         local roles = partyMonitor:GetAvailableRoles()
--         local targetRole = nil
        
--         -- Find matching role (case insensitive)
--         for _, role in pairs(roles) do
--             if string.lower(role) == string.lower(arg2) then
--                 targetRole = role
--                 break
--             end
--         end
        
--         if not targetRole then
--             DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Roles]|r Invalid role: " .. arg2)
--             ShowAvailableRoles()
--             return
--         end
        
--         partyMonitor:SetRole(arg1, targetRole)
        
--     elseif command == "clear" or command == "remove" then
--         if arg1 == "" then
--             DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Roles]|r Usage: /role clear <player>")
--             return
--         end
        
--         partyMonitor:ClearRole(arg1)
        
--     elseif command == "list" or command == "show" or command == "" then
--         partyMonitor:ListRoles()
        
--     elseif command == "tanks" then
--         local tanks = partyMonitor:GetTanks()
--         if table.getn(tanks) == 0 then
--             DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Roles]|r No tanks assigned")
--         else
--             DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Roles]|r Tanks:")
--             for _, tank in ipairs(tanks) do
--                 DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s (%s)", tank.name, tank.role))
--             end
--         end
        
--     elseif command == "available" or command == "types" then
--         ShowAvailableRoles()
        
--     elseif command == "help" then
--         ShowRoleHelp()
        
--     else
--         DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Roles]|r Unknown command. Use /role help for help")
--     end
-- end

-- function ShowAvailableRoles()
--     local partyMonitor = MyrkAddon:GetModule("MyrkPartyMonitor")
--     if not partyMonitor then return end
    
--     local roles = partyMonitor:GetAvailableRoles()
--     DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Roles]|r Available roles:")
--     for _, role in pairs(roles) do
--         if role ~= "" then -- Don't show "" as an option
--             DEFAULT_CHAT_FRAME:AddMessage("  " .. role)
--         end
--     end
-- end

-- function ShowRoleHelp()
--     DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Roles]|r Commands:")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role set <player> <role> - Assign a role to a player")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role clear <player> - Clear a player's role")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role list - Show all role assignments")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role tanks - Show all tanks")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role healers - Show all healers")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role dps - Show all DPS")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role available - Show available role types")
--     DEFAULT_CHAT_FRAME:AddMessage("  /role help - Show this help")
-- end

-- -- Auto-complete function for player names
-- function GetPartyMemberNames()
--     local names = {}
    
--     -- Add player
--     table.insert(names, UnitName("player"))
    
--     -- Add party members
--     for i = 1, 4 do
--         local unitId = "party" .. i
--         if UnitExists(unitId) then
--             table.insert(names, UnitName(unitId))
--         end
--     end
    
--     return names
-- end

-- DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Roles]|r Commands loaded. Use /role help for help")
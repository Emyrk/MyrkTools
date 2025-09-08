local unpack = unpack or table.unpack

if not string.match then
    string.match = function (s, pattern, init)
        init = init or 1
        -- try to find captures
        local results = { string.find(s, pattern, init) }
        if table.getn(results) > 2 then
            -- drop the start/end positions, keep captures
            local captures = {}
            for i = 3, table.getn(results) do
                table.insert(captures, results[i])
            end
            return unpack(captures)
        elseif results[1] and results[2] then
            -- no captures, return the matched substring
            return string.sub(s, results[1], results[2])
        end
        return nil
    end
end


-- Return true if the unit is healable by player
function UnitIsHealable(unit, explain)
    if UnitExists(unit) then
        if EvaluateUnitCondition(unit, UnitIsFriend('player', unit), "is not a friend", explain) then
            return false
        end
        if EvaluateUnitCondition(unit, not UnitIsEnemy(unit, 'player'), "is an enemy", explain) then
            return false
        end
        if EvaluateUnitCondition(unit, not UnitCanAttack('player', unit), "can be attacked by player", explain) then
            return false
        end
        if EvaluateUnitCondition(unit, UnitIsConnected(unit), "is not connected", explain) then
            return false
        end
        if EvaluateUnitCondition(unit, not UnitIsDeadOrGhost(unit), "is dead or ghost", explain) then
            return false
        end
        if EvaluateUnitCondition(unit, UnitIsVisible(unit), "is not visible to client", explain) then
            return false
        end
    else
        return false
    end
    return true
end

function EvaluateUnitCondition(unit, condition, debugText, explain)
    if not condition then
        if explain then
            print(unit .. " " .. debugText)
        end
        return true
    else
        return false
    end
end
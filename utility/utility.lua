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

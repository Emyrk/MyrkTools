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

local AddonPath = "Interface\\AddOns\\MyrkTools\\"
for _, name in pairs(tocs) do
  local current = string.format("MyrkTools%s", name)
  local _, title = GetAddOnInfo(current)
  if title then
    AddonPath = "Interface\\AddOns\\" .. current
    break
  end
end

-- handle/convert media dir paths
Media = setmetatable({}, { __index = function(tab,key)
  local value = tostring(key)
  if strfind(value, "img:") then
    value = string.gsub(value, "img:", AddonPath .. "\\img\\")
  elseif strfind(value, "font:") then
    value = string.gsub(value, "font:", AddonPath .. "\\fonts\\")
  else
    value = string.gsub(value, "Interface\\AddOns\\MyrkTools\\", AddonPath .. "\\")
  end
  rawset(tab,key,value)
  return value
end})

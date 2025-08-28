-- Fixed version of Party.lua for testing
-- This version fixes the bugs in the original implementation

Party = {}
Party.__index = Party

function Party:New()
    local instance = {
      players = {},
    }
    setmetatable(instance, Party)
    return instance
end

function Party:Refresh()
  self:RefreshID("player") -- Always include player
  for i=1,4 do
    self:RefreshID("party" .. i)
  end
end

-- id should be party1, party2, etc.
-- "player" is also accepted
function Party:RefreshID(id) 
  if UnitExists(id) then
    local name = UnitName(id) -- Fixed: was 'unitstr', now 'id'
    if name and name ~= "" then
      if not self.players[id] then
        self.players[id] = AllyPlayer:New(id)
      end

      self.players[id]:Refresh() -- Fixed: added colon for method call
      return
    end
  end

  self:RemoveID(id) -- Fixed: added colon for method call
end

function Party:RemoveID(id) 
  self.players[id] = nil
end

AllyPlayer = {} -- Fixed: was PartyPlayer, should be AllyPlayer
AllyPlayer.__index = AllyPlayer

function AllyPlayer:New(id)
    local instance = {
      id = id,
      name = "",
      hp = -1,
      hpmax = -1,
      class = "",
    }
    setmetatable(instance, AllyPlayer)
    return instance
end

function AllyPlayer:Refresh()
  local _, englishClass = UnitClass(self.id)
  self.name = UnitName(self.id)
  self.hp = UnitHealth(self.id)
  self.hpmax = UnitHealthMax(self.id)
  self.class = englishClass
end

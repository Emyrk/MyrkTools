Party = {}
Party.__index = Party

function Party:New()
    local instance = {
      players = {},
    }
    setmetatable(instance, Party)
    return instance
end

function Party:Refresh(self)
  self.RefreshID(self, "player") -- Always include player
  for i=1,4 do
    self.RefreshID(self, "party" .. i)
  end
end

-- id should be party1, party2, etc.
-- "player" is also accepted
function Party:RefreshID(self, id) 
  if UnitExists(id) then
    local name = UnitName(unitstr)
    if name and name ~= "" then
      if not self.players[id] then
        self.players[id] = AllyPlayer:New(id)
      end

      self.players[id].Refresh()
      return
    end
  end

  self.RemoveID(self, id)
end

function Party:RemoveID(self, id) 
  self.players[id] = nil
end

PartyPlayer = {}
PartyPlayer.__index = PartyPlayer

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

function AllyPlayer:Refresh(self)
  local _, englishClass = UnitClass(self.id)
  self.name = UnitName(self.id)
  self.hp = UnitHealth(self.id)
  self.hpmax = UnitHealthMax(self.id)
  self.class = englishClass
end
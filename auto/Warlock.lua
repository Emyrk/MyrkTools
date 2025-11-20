-- Global Variables
WarlockRota = {}

---@param engine DecisionEngine
function WarlockRota:evaluate(engine)
  if UnitIsHealable("target") then
    ClearTarget()
  end

  if not HostileTarget() then
    TargetNearestEnemy()
    return nil
  end

	local health = UnitHealth("target")
	local healthMax = UnitHealthMax("target")
	local healthPercent = 100*(health/healthMax)
	local mana = UnitMana("player")
	local manaMax = UnitManaMax("player")
	local manaPercent = 100*(mana/manaMax)
  local myHealth = UnitHealth("player")
  local myHealthMax = UnitHealthMax("player")
  local myHealthPercent = 100*(myHealth/myHealthMax)
	
	-- Long fights (bosses/elites)
	-- local isLongFight = (UnitClassification("target") == "elite" or 
	--                      UnitClassification("target") == "worldboss" or 
	--                      UnitClassification("target") == "rareelite" or
	--                      healthMax > 10000)
	

	-- Main nuke - Shadow Bolt
  if healthPercent < 15  and mana > 20 and WarlockRota:CountSoulShards() < 50 then
    return Action:CastByName("Drain Soul", "target", "soul shards")
  end

	if mana > 99 then
    return Action:CastByName("Shadow Bolt", "target", "main_nuke")
  end

  if mana < 100 and myHealthPercent > 50 then
    return Action:CastByName("Life Tap", "player", "life_tap")
  end
	
  return nil
end

function WarlockRota:CountSoulShards()
	local shardCount = 0
	-- Bags 0-4 (0 = backpack, 1-4 = bag slots)
	for bag = 0, 4 do
		local slots = GetContainerNumSlots(bag)
		if slots then
			for slot = 1, slots do
				local itemLink = GetContainerItemLink(bag, slot)
				if itemLink then
					-- Extract item ID from link
					-- Format: |cffffffff|Hitem:6265:0:0:0|h[Soul Shard]|h|r
					local _, _, itemID = string.find(itemLink, "item:(%d+):")
					if itemID and tonumber(itemID) == 6265 then
						local _, count = GetContainerItemInfo(bag, slot)
						shardCount = shardCount + (count or 1)
					end
				end
			end
		end
	end
	return shardCount
end
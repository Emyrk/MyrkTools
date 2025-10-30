local libHC = AceLibrary("HealComm-1.0")
local libSC = AceLibrary("SpellCache-1.0")
local libIB = AceLibrary("ItemBonusLib-1.0")

function GetSpellIDs(spellName)
    local i = 1;
    local List = {};
    local spellNamei, spellRank;

    while true do
        spellNamei, spellRank = GetSpellName(i, BOOKTYPE_SPELL);

        if not spellNamei then
            return List
        end

        --debug(string.format("spellNamei: %s ", Bonus));

        if spellNamei == spellName then
            _, _, spellRank = string.find(spellRank, " (%d+)$");
            spellRank = tonumber(spellRank);
            if not spellRank then
                return i
            end

            -- print("HEY >>> spellname: " .. spellNamei .. " spellRank: " .. spellRank);
            List[spellRank] = i;
        end
        i = i + 1;
    end
end

function GetOptimalRank(spell, hp_needed)
    if not libSC.data[spell] then
        self:Print('smartheal rank not found')
        return
    end

    local bonus, power, mod
    if TheoryCraft == nil then
        bonus = tonumber(libIB:GetBonus("HEAL"))
        power, mod = libHC:GetUnitSpellPower(unit, spell)
        local buffpower, buffmod = libHC:GetBuffSpellPower()
        bonus = bonus + buffpower
        mod = mod * buffmod
    end
    local max_rank = tonumber(libSC.data[spell].Rank)
    local rank = max_rank

    local mana = UnitMana("player")
    local spelldata = nil
    for i = max_rank, 1, -1 do
        spellData = TheoryCraft ~= nil and TheoryCraft_GetSpellDataByName(spell, i)
        if spellData then
            if mana >= spellData.manacost then
                if spellData.averagehealnocrit > (hp_needed) then
                    rank = i
                else
                    break
                end
            else
                rank = i > 1 and i - 1 or 1
            end
        else
            local heal = (libHC.Spells[spell][i](bonus) + power) * mod
            if heal > (hp_needed) then
                rank = i
            else
                break
            end
        end
    end
    --[[
    self:Print(spell
            .. ' rank ' .. rank
            .. ' hp ' .. math.floor(spellData.averagehealnocrit)
            .. ' hpm ' .. (spellData.averagehealnocrit / spellData.manacost)
            .. ' mana ' .. spellData.manacost )
    ]]
    return rank
end


SpellIndex = {
}

function ReloadSpells()
  SpellIndex["Healing Wave"] = GetSpellIDs("Healing Wave")
  SpellIndex["Lesser Heal"] = GetSpellIDs("Lesser Heal")
  SpellIndex["Greater Heal"] = GetSpellIDs("Greater Heal")
  SpellIndex["Heal"] = GetSpellIDs("Heal")
  SpellIndex["Flash Heal"] = GetSpellIDs("Flash Heal")
  SpellIndex["Renew"] = GetSpellIDs("Renew")
  SpellIndex["Power Word: Shield"] = GetSpellIDs("Power Word: Shield")
  SpellIndex["Smite"] = GetSpellIDs("Smite")
  SpellIndex["Wand"] = GetSpellIDs("Wand")
end

function ManualLookup(spellName, rank)
  if spellName == "Fade" then
    return Fade(rank)
  elseif spellName == "Psychic Scream" then
    return Scream(rank)
  end

  return nil
end

function Fade(rank) 
    if rank >= 5 then
        return nil
    end

    mana = {
        [1] = 38,
        [2] = 72,
        [3] = 120,
        [4] = 168,
        [5] = 225,
        [6] = 275,
    }

    spellnumber = {
        [1] = 586,
        [2] = 9578,
        [3] = 9579,
        [4] = 9592,
        [5] = 10941,
        [6] = 10942,
    }

    return {
        spellname = "Fade",
        spellrank = rank,
        manacost = mana[rank],
        spellnumber = spellnumber[rank],
        averagehealnocrit = 0,
    }
end

function Scream(rank) 
    if rank >= 4 then
        return nil
    end

    mana = {
        [1] = 100,
        [2] = 140,
        [3] = 180,
        [4] = 210,
    }

    spellnumber = {
        [1] = 8122,
        [2] = 8124,
        [3] = 10888,
        [4] = 10890,
    }

    return {
        spellname = "Psychic Scream",
        spellrank = rank,
        manacost = mana[rank],
        spellnumber = spellnumber[rank],
        averagehealnocrit = 0,
    }
end
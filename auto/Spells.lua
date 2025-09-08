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


Spells = {
}

function ReloadSpells()
  Spells["Lesser Heal"] = GetSpellIDs("Lesser Heal")
  Spells["Heal"] = GetSpellIDs("Heal")
  Spells["Flash Heal"] = GetSpellIDs("Flash Heal")
  Spells["Renew"] = GetSpellIDs("Renew")
  Spells["Power Word: Shield"] = GetSpellIDs("Power Word: Shield")
  Spells["Smite"] = GetSpellIDs("Smite")
  Spells["Wand"] = GetSpellIDs("Wand")
end
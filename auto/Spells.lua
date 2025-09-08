-- Spells.lua
-- Spell management and calculation system

-- Safe library loading with validation
local function SafeLoadLibrary(name, fallback)
    if AceLibrary and type(AceLibrary) == "function" then
        local lib = AceLibrary(name)
        if lib then
            return lib
        end
    end
    return fallback or {}
end

local libHC = SafeLoadLibrary("HealComm-1.0")
local libSC = SafeLoadLibrary("SpellCache-1.0")
local libIB = SafeLoadLibrary("ItemBonusLib-1.0")

-- Fallback functions if libraries are not available
local function GetHealAmount(spellName, rank)
    if libHC and libHC.getHealAmount then
        return libHC:getHealAmount(spellName, rank)
    end
    -- Fallback: basic heal amounts for common spells
    local fallbackHeals = {
        ["Flash Heal"] = {[1] = 200, [2] = 350, [3] = 500, [4] = 700, [5] = 900, [6] = 1100, [7] = 1400},
        ["Heal"] = {[1] = 300, [2] = 500, [3] = 800, [4] = 1200},
        ["Greater Heal"] = {[1] = 900, [2] = 1200, [3] = 1600, [4] = 2000}
    }
    return (fallbackHeals[spellName] and fallbackHeals[spellName][rank]) or 500
end
-- Auto - Decision tree based healing system
-- Uses a modular decision tree approach for flexible healing strategies

Auto = MyrkAddon:NewModule("MyrkAuto", "AceEvent-3.0")
HealComm = AceLibrary("HealComm-1.0")
DamageComm = AceLibrary("DamageComm-1.0")
Logs = AceLibrary("MyrkLogs-1.0")
-- Party = AceLibrary("PartyMonitor-1.0")

---@class Auto
---@field engine DecisionEngine
function Auto:OnEnable()
    -- Initialize the decision engine
    self.engine = DecisionEngine:New()
    
    -- Register for party/raid updates
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnPartyChanged")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "OnPartyChanged")
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MyrkAuto]|r Loaded")
end

function Auto:IsGlobalCasting()
    if not self.engine then
        return false
    end

    return self.engine:IsGlobalCasting()
end

function Auto:OnPartyChanged()
    -- PartyMonitor handles role management now
end

function Auto:Perform()
    if not self.engine then
        Logs.Error("Auto engine not initialized")
        return false
    end

    if not self.engine:Ready() then
        Logs.Error("Auto engine is not ready")
        return false

    end
        
    -- Execute the healing strategy
    local decision = self.engine:ExecuteLoopedStrategy()
    if decision then
        if decision.action == ACTIONS.busy then
            Logs.Debug("Busy: " .. (decision.reason or "no reason"))
            return true -- Still busy, do not interrupt 
        end

        if decision.action == ACTIONS.cast then
            local name = UnitName(decision.target_id) or decision.target_id

            Logs.Info(string.format("Casting %s on %s (%s)", 
                decision.spellID or "", name, decision.reason or "no reason"))
            return self.engine:ExecuteCast(decision)
        end

        if decision.action == ACTIONS.error then
            Logs.Error("Error: " .. (decision.reason or "no reason"))
            return false
        end

        if decision.action == ACTIONS.custom then
            Logs.Info(string.format("Custom action: %s", 
                decision.reason or "no reason"))
            decision.doFunction(self.engine)
            return true
        end

         if decision.action == ACTIONS.heal then
            local name = UnitName(decision.target_id) or decision.target_id
            local spellName, spellRank = GetSpellName(decision.spellID, BOOKTYPE_SPELL)
            Logs.Info(string.format("Healing %s:%s on %s (%s)", 
                spellName, spellRank, name, decision.reason))
            return self.engine:ExecuteHeal(decision)
        end

        Logs.Error("Error: Unsupported action = " .. (decision.action or "no reason"))
    end
    
    return false
end


-- Shaman targeting and rotation script
local function HasBuff(name)
	for i=0, 31 do
		local buffTexture, buffApplications = UnitBuff("player", i)
        if buffTexture and string.find(buffTexture, name) then
			return true
		end
	end
	return false
end

local shamanSpellCache = {}

-- Shaman targeting and rotation script
function ShamanTag()
    if table.getn(shamanSpellCache) == 0 then
        shamanSpellCache["Earth Shock"] = GetSpellIDs("Earth Shock")
        shamanSpellCache["Lightning Bolt"] = GetSpellIDs("Lightning Bolt")
        shamanSpellCache["Lightning Shield"] = GetSpellIDs("Lightning Shield")
        -- print(PrintTable(shamanSpellCache))
    end

    -- 0. Cast Lightning Shield if not active
	if not HasBuff("LightningShield") then
		CastSpell(shamanSpellCache["Lightning Shield"][1], BOOKTYPE_SPELL)
		return
	end

	-- 1. If not targeting an enemy, target one
	if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then
		TargetNearestEnemy()
		return
	end
	
	-- 2. If enemy has <100% health, clear target and target someone else
	local health = UnitHealth("target")
	local healthMax = UnitHealthMax("target")
	if health < healthMax then
		ClearTarget()
		TargetNearestEnemy()
		return
	end
	
	-- 3. Cast Earth Shock if not on cooldown
	local start, _, _ = GetSpellCooldown(shamanSpellCache["Earth Shock"][1], BOOKTYPE_SPELL)
	if start == 0 then
		CastSpell(shamanSpellCache["Earth Shock"][1], BOOKTYPE_SPELL)
        ClearTarget()
		return
	end
	
	-- 4. Cast Lightning Bolt rank 1
	CastSpell(shamanSpellCache["Lightning Bolt"][1], BOOKTYPE_SPELL)
    ClearTarget()
end
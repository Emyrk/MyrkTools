-- WoW API Mock System for Unit Testing
-- This file provides mock implementations of WoW API functions for testing

local WoWAPIMock = {}

-- Mock data storage
local mockData = {
  units = {},
  shaguDPS = {
    data = {
      recent = { [1] = {} },
      taken = { [1] = {} }
    }
  }
}

-- Helper function to reset all mock data
function WoWAPIMock.resetMockData()
  mockData.units = {}
  mockData.shaguDPS.data.recent[1] = {}
  mockData.shaguDPS.data.taken[1] = {}
end

-- Helper function to set unit health data
function WoWAPIMock.setUnitHealth(unitName, currentHealth, maxHealth)
  mockData.units[unitName] = {
    health = currentHealth,
    maxHealth = maxHealth,
    exists = true,
    dead = currentHealth <= 0,
    name = unitName,
    class = "WARRIOR", -- Default class
    englishClass = "WARRIOR"
  }
end

-- Helper function to set unit class
function WoWAPIMock.setUnitClass(unitName, localizedClass, englishClass)
  if not mockData.units[unitName] then
    mockData.units[unitName] = { exists = true, health = 100, maxHealth = 100, name = unitName }
  end
  mockData.units[unitName].class = localizedClass or englishClass
  mockData.units[unitName].englishClass = englishClass
end

-- Helper function to set unit data completely
function WoWAPIMock.setUnitData(unitName, data)
  mockData.units[unitName] = {
    health = data.health or 100,
    maxHealth = data.maxHealth or 100,
    exists = data.exists ~= false,
    dead = (data.health or 100) <= 0,
    name = data.name or unitName,
    class = data.class or "WARRIOR",
    englishClass = data.englishClass or data.class or "WARRIOR"
  }
end

-- Helper function to remove a unit (simulate leaving party)
function WoWAPIMock.removeUnit(unitName)
  mockData.units[unitName] = nil
end

-- Helper function to set incoming damage data
function WoWAPIMock.setIncomingDamage(unitName, damage, tick)
  tick = tick or GetTime()
  mockData.shaguDPS.data.recent[1][unitName] = {
    _sum = damage
  }
  mockData.shaguDPS.data.taken[1][unitName] = {
    _tick = tick
  }
end

-- Mock WoW API functions
function UnitHealth(unit)
  local unitData = mockData.units[unit]
  if not unitData or not unitData.exists then
    return 0
  end
  return unitData.health or 0
end

function UnitHealthMax(unit)
  local unitData = mockData.units[unit]
  if not unitData or not unitData.exists then
    return 0
  end
  return unitData.maxHealth or 0
end

function UnitExists(unit)
  local unitData = mockData.units[unit]
  return unitData and unitData.exists or false
end

function UnitIsDead(unit)
  local unitData = mockData.units[unit]
  if not unitData or not unitData.exists then
    return true
  end
  return unitData.dead or false
end

function UnitName(unit)
  if UnitExists(unit) then
    return unit, nil -- Return unit name and realm (nil for same realm)
  end
  return nil, nil
end

function UnitClass(unit)
  local unitData = mockData.units[unit]
  if not unitData or not unitData.exists then
    return nil, nil
  end
  return unitData.class or "Warrior", unitData.englishClass or "WARRIOR"
end

function UnitClassBase(unit)
  local unitData = mockData.units[unit]
  if not unitData or not unitData.exists then
    return nil
  end
  return unitData.englishClass or "WARRIOR"
end

-- Mock GetTime function
local mockTime = 0
function GetTime()
  return mockTime
end

function WoWAPIMock.setTime(time)
  mockTime = time
end

-- Mock ShaguDPS global
ShaguDPS = mockData.shaguDPS

-- Mock other globals that might be needed
DEFAULT_CHAT_FRAME = {
  AddMessage = function(self, msg) 
    -- Silent mock for testing
  end
}

-- Mock LibStub for addon framework
function LibStub(name)
  return {
    NewAddon = function(self, addonName, ...)
      return {
        RegisterChatCommand = function() end,
        Print = function() end,
        NewModule = function(self, moduleName)
          return {
            OnEnable = function() end
          }
        end
      }
    end
  }
end

return WoWAPIMock

-- Unit tests for Tools.lua functions
-- Requires busted testing framework

local WoWAPIMock = require('tests.wow_api_mock')

-- Load the Tools.lua file
dofile('Tools.lua')
-- Load DamageComm.lua for UnitGetIncomingDamage function
dofile('DamageComm.lua')

describe("ExpectedUnitHealth", function()
  
  before_each(function()
    -- Reset mock data before each test
    WoWAPIMock.resetMockData()
    WoWAPIMock.setTime(100) -- Set a baseline time
  end)
  
  it("should return 0 for nil unit name", function()
    local result = ExpectedUnitHealth(nil)
    assert.are.equal(0, result)
  end)
  
  it("should return 0 for non-existent unit", function()
    local result = ExpectedUnitHealth("nonexistent")
    assert.are.equal(0, result)
  end)
  
  it("should return 0 for dead unit", function()
    WoWAPIMock.setUnitHealth("player", 0, 100)
    local result = ExpectedUnitHealth("player")
    assert.are.equal(0, result)
  end)
  
  it("should return current health when no incoming damage", function()
    WoWAPIMock.setUnitHealth("player", 80, 100)
    -- No incoming damage set
    local result = ExpectedUnitHealth("player")
    assert.are.equal(80, result)
  end)
  
  it("should subtract incoming damage from current health", function()
    WoWAPIMock.setUnitHealth("player", 80, 100)
    WoWAPIMock.setIncomingDamage("player", 20, 100) -- 20 damage at time 100
    
    local result = ExpectedUnitHealth("player")
    assert.are.equal(60, result) -- 80 - 20 = 60
  end)
  
  it("should not return negative health", function()
    WoWAPIMock.setUnitHealth("player", 30, 100)
    WoWAPIMock.setIncomingDamage("player", 50, 100) -- More damage than health
    
    local result = ExpectedUnitHealth("player")
    assert.are.equal(0, result) -- Should clamp to 0, not -20
  end)
  
  it("should handle exact damage amount", function()
    WoWAPIMock.setUnitHealth("player", 50, 100)
    WoWAPIMock.setIncomingDamage("player", 50, 100) -- Exact damage amount
    
    local result = ExpectedUnitHealth("player")
    assert.are.equal(0, result)
  end)
  
  it("should work with different unit names", function()
    WoWAPIMock.setUnitHealth("party1", 75, 100)
    WoWAPIMock.setIncomingDamage("party1", 15, 100)
    
    local result = ExpectedUnitHealth("party1")
    assert.are.equal(60, result) -- 75 - 15 = 60
  end)
  
  it("should handle old damage data (expired)", function()
    WoWAPIMock.setUnitHealth("player", 80, 100)
    -- Set damage with old timestamp (more than 5 seconds ago)
    WoWAPIMock.setIncomingDamage("player", 20, 90) -- 10 seconds ago
    WoWAPIMock.setTime(100)
    
    local result = ExpectedUnitHealth("player")
    -- Should return full health since damage data is expired
    assert.are.equal(80, result)
  end)
  
  it("should handle recent damage data", function()
    WoWAPIMock.setUnitHealth("player", 80, 100)
    -- Set damage with recent timestamp (within 5 seconds)
    WoWAPIMock.setIncomingDamage("player", 20, 98) -- 2 seconds ago
    WoWAPIMock.setTime(100)
    
    local result = ExpectedUnitHealth("player")
    -- Should subtract damage since it's recent
    assert.are.equal(60, result)
  end)
  
end)

-- Additional tests for other Tools.lua functions
describe("HostileTarget", function()
  
  before_each(function()
    WoWAPIMock.resetMockData()
  end)
  
  it("should return false for non-existent target", function()
    local result = HostileTarget()
    assert.is_false(result)
  end)
  
  it("should return false for dead target", function()
    WoWAPIMock.setUnitHealth("target", 0, 100)
    local result = HostileTarget()
    assert.is_false(result)
  end)
  
end)

describe("BoolToString", function()
  
  it("should return 'true' for true value with default strings", function()
    local result = BoolToString(true)
    assert.are.equal("true", result)
  end)
  
  it("should return 'false' for false value with default strings", function()
    local result = BoolToString(false)
    assert.are.equal("false", result)
  end)
  
  it("should return custom strings", function()
    local result1 = BoolToString(true, "yes", "no")
    local result2 = BoolToString(false, "yes", "no")
    assert.are.equal("yes", result1)
    assert.are.equal("no", result2)
  end)
  
end)

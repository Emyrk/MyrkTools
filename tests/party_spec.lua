-- Unit tests for PartyMonitor/party.lua
-- Tests party member join/leave functionality

local WoWAPIMock = require('tests.wow_api_mock')

-- Load and test the fixed version
dofile('PartyMonitor/party.lua')

describe("Party System", function()
  local party
  
  before_each(function()
    -- Reset mock data before each test
    WoWAPIMock.resetMockData()
    WoWAPIMock.setTime(100)
    
    -- Create a new party instance
    party = Party:New()
    
    -- Always set up the player
    WoWAPIMock.setUnitData("player", {
      name = "Priests",
      health = 100,
      maxHealth = 100,
      class = "Priest",
      englishClass = "PRIEST"
    })
  end)
  
  describe("Party Member Join Scenarios", function()
    
    it("should add party member when they join", function()
      -- Initially no party members
      party:Refresh()
      
      -- Add a party member
      WoWAPIMock.setUnitData("party1", {
        name = "NewMember",
        health = 80,
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      
      -- Refresh party (simulating PARTY_MEMBERS_CHANGED event)
      party:Refresh()
      
      -- Member should be added
      assert.is_not_nil(party.players["party1"])
      assert.are.equal("NewMember", party.players["party1"].name)
      assert.are.equal("PRIEST", party.players["party1"].class)
      assert.are.equal(80, party.players["party1"].hp)
      assert.are.equal(100, party.players["party1"].hpmax)
    end)
    
    it("should add multiple party members", function()
      -- Add multiple party members
      WoWAPIMock.setUnitData("party1", {
        name = "Member1",
        health = 80,
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      
      WoWAPIMock.setUnitData("party2", {
        name = "Member2",
        health = 90,
        maxHealth = 100,
        class = "Mage",
        englishClass = "MAGE"
      })
      
      WoWAPIMock.setUnitData("party3", {
        name = "Member3",
        health = 95,
        maxHealth = 100,
        class = "Warlock",
        englishClass = "WARLOCK"
      })
      
      party:Refresh()
      
      -- All members should be added
      assert.is_not_nil(party.players["party1"])
      assert.is_not_nil(party.players["party2"])
      assert.is_not_nil(party.players["party3"])
      
      assert.are.equal("Member1", party.players["party1"].name)
      assert.are.equal("Member2", party.players["party2"].name)
      assert.are.equal("Member3", party.players["party3"].name)
    end)
    
  end)
  
  describe("Party Member Leave Scenarios", function()
    
    it("should remove party member when they leave", function()
      -- Start with a party member
      WoWAPIMock.setUnitData("party1", {
        name = "LeavingMember",
        health = 80,
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      
      party:Refresh()
      
      -- Verify member was added
      assert.is_not_nil(party.players["party1"])
      
      -- Simulate member leaving (remove from mock)
      WoWAPIMock.removeUnit("party1")
      
      -- Refresh party (simulating PARTY_MEMBERS_CHANGED event)
      party:Refresh()
      
      -- Member should be removed
      assert.is_nil(party.players["party1"])
    end)
    
    it("should handle partial party changes", function()
      -- Start with 3 party members
      WoWAPIMock.setUnitData("party1", {
        name = "StayingMember",
        health = 80,
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      
      WoWAPIMock.setUnitData("party2", {
        name = "LeavingMember",
        health = 90,
        maxHealth = 100,
        class = "Mage",
        englishClass = "MAGE"
      })
      
      WoWAPIMock.setUnitData("party3", {
        name = "AlsoStaying",
        health = 95,
        maxHealth = 100,
        class = "Warlock",
        englishClass = "WARLOCK"
      })
      
      party:Refresh()
      
      -- Verify all members added
      assert.is_not_nil(party.players["party1"])
      assert.is_not_nil(party.players["party2"])
      assert.is_not_nil(party.players["party3"])
      
      -- party2 leaves
      WoWAPIMock.removeUnit("party2")
      
      party:Refresh()
      
      -- party1 and party3 should remain, party2 should be gone
      assert.is_not_nil(party.players["party1"])
      assert.is_nil(party.players["party2"])
      assert.is_not_nil(party.players["party3"])
      
      assert.are.equal("StayingMember", party.players["party1"].name)
      assert.are.equal("AlsoStaying", party.players["party3"].name)
    end)
    
  end)
  
  describe("Complex Party Change Scenarios", function()
    
    it("should handle member leaving and new member joining simultaneously", function()
      -- Start with party1
      WoWAPIMock.setUnitData("party1", {
        name = "OriginalMember",
        health = 80,
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      
      party:Refresh()
      assert.is_not_nil(party.players["party1"])
      
      -- party1 leaves, party2 joins
      WoWAPIMock.removeUnit("party1")
      WoWAPIMock.setUnitData("party2", {
        name = "NewMember",
        health = 90,
        maxHealth = 100,
        class = "Rogue",
        englishClass = "ROGUE"
      })
      
      party:Refresh()
      
      -- party1 should be gone, party2 should be added
      assert.is_nil(party.players["party1"])
      assert.is_not_nil(party.players["party2"])
      assert.are.equal("NewMember", party.players["party2"].name)
      assert.are.equal("ROGUE", party.players["party2"].class)
    end)
    
    it("should handle rapid party changes", function()
      -- Simulate rapid join/leave cycles
      
      -- Round 1: party1 joins
      WoWAPIMock.setUnitData("party1", {
        name = "Member1",
        health = 80,
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      party:Refresh()
      assert.is_not_nil(party.players["party1"])
      
      -- Round 2: party1 leaves, party2 and party3 join
      WoWAPIMock.removeUnit("party1")
      WoWAPIMock.setUnitData("party2", {
        name = "Member2",
        health = 85,
        maxHealth = 100,
        class = "Mage",
        englishClass = "MAGE"
      })
      WoWAPIMock.setUnitData("party3", {
        name = "Member3",
        health = 90,
        maxHealth = 100,
        class = "Warlock",
        englishClass = "WARLOCK"
      })
      party:Refresh()
      
      assert.is_nil(party.players["party1"])
      assert.is_not_nil(party.players["party2"])
      assert.is_not_nil(party.players["party3"])
      
      -- Round 3: All leave
      WoWAPIMock.removeUnit("party2")
      WoWAPIMock.removeUnit("party3")
      party:Refresh()
      
      assert.is_nil(party.players["party1"])
      assert.is_nil(party.players["party2"])
      assert.is_nil(party.players["party3"])
    end)
    
    it("should update existing member stats on refresh", function()
      -- Add a party member
      WoWAPIMock.setUnitData("party1", {
        name = "UpdatingMember",
        health = 80,
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      
      party:Refresh()
      assert.are.equal(80, party.players["party1"].hp)
      
      -- Update member's health
      WoWAPIMock.setUnitData("party1", {
        name = "UpdatingMember",
        health = 60, -- Health decreased
        maxHealth = 100,
        class = "Priest",
        englishClass = "PRIEST"
      })
      
      party:Refresh()
      
      -- Stats should be updated
      assert.are.equal(60, party.players["party1"].hp)
      assert.are.equal("UpdatingMember", party.players["party1"].name)
    end)
    
  end)
  
end)
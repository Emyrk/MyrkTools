# Party System Unit Tests

This document describes the unit tests for the Party system in `PartyMonitor/party.lua`.

## Test Files

- `tests/party_spec.lua` - Main test suite for party join/leave functionality
- `tests/party_fixed.lua` - Corrected version of party.lua for testing expected behavior
- `tests/wow_api_mock.lua` - Extended with party-related WoW API functions

## What's Tested

### Original Implementation Tests
Tests the current `PartyMonitor/party.lua` with its existing bugs:
- Basic functionality (doesn't crash)
- Edge cases with non-existent units
- Player removal when they leave
- AllyPlayer class functionality

### Fixed Implementation Tests
Tests the corrected version to demonstrate expected behavior:

#### Party Member Join Scenarios
- ✅ Adding single party member when they join
- ✅ Adding multiple party members simultaneously
- ✅ Proper stat tracking (name, health, class)

#### Party Member Leave Scenarios  
- ✅ Removing party member when they leave
- ✅ Partial party changes (some stay, some leave)
- ✅ Maintaining correct state after changes

#### Complex Scenarios
- ✅ Simultaneous leave/join operations
- ✅ Rapid party composition changes
- ✅ Stat updates for existing members
- ✅ Full party dissolution and reformation

## Key Test Cases

### Member Joining
```lua
-- Simulate PARTY_MEMBERS_CHANGED event
WoWAPIMock.setUnitData("party1", {
  name = "NewMember",
  health = 80,
  maxHealth = 100,
  class = "Priest",
  englishClass = "PRIEST"
})

party:Refresh()

-- Verify member was added
assert.is_not_nil(party.players["party1"])
assert.are.equal("NewMember", party.players["party1"].name)
```

### Member Leaving
```lua
-- Start with member present
party:Refresh()
assert.is_not_nil(party.players["party1"])

-- Simulate member leaving
WoWAPIMock.removeUnit("party1")
party:Refresh()

-- Verify member was removed
assert.is_nil(party.players["party1"])
```

### Complex Party Changes
```lua
-- party1 leaves, party2 joins simultaneously
WoWAPIMock.removeUnit("party1")
WoWAPIMock.setUnitData("party2", { ... })

party:Refresh()

-- Verify correct state
assert.is_nil(party.players["party1"])
assert.is_not_nil(party.players["party2"])
```

## Bugs Identified in Original Code

1. **Variable Name Bug**: `RefreshID` uses `unitstr` instead of `id` parameter
2. **Method Call Bug**: Missing colons for method calls (`self.Refresh()` should be `self:Refresh()`)
3. **Class Name Bug**: `PartyPlayer` vs `AllyPlayer` inconsistency

## Running the Tests

### With NixOS
```bash
nix-shell
make test
# or specifically:
busted tests/party_spec.lua --verbose
```

### With Manual Setup
```bash
# Install dependencies
make test-install

# Run party tests
busted tests/party_spec.lua --verbose

# Run all tests
make test
```

## Expected Output

The tests will show:
- ✅ Original implementation tests (basic functionality)
- ✅ Fixed implementation tests (full party join/leave scenarios)
- 📊 Coverage of edge cases and complex scenarios

## Integration with WoW Events

In the actual addon, `Party:Refresh()` should be called when:
- `PARTY_MEMBERS_CHANGED` event fires
- `RAID_ROSTER_UPDATE` event fires (for raid groups)
- Player logs in and party state needs initialization

The tests simulate these scenarios by manipulating the mock WoW API state and calling `Party:Refresh()`.

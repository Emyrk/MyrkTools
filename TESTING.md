# MyrkTools Testing Setup

This document describes the unit testing setup for the MyrkTools World of Warcraft addon.

## Overview

The testing framework uses [Busted](https://olivinelabs.com/busted/) for Lua unit testing with custom WoW API mocks to simulate the World of Warcraft environment.

## Setup

### Prerequisites

1. Install Lua 5.1 (required for WoW addon compatibility)
2. Install LuaRocks package manager
3. Install the testing framework:

```bash
make test-install
```

Or manually:
```bash
luarocks install busted
```

### Optional Development Tools

```bash
make dev-install
```

This installs:
- `luacheck` - Lua linter
- `luacov` - Code coverage tool

## Running Tests

### Run All Tests
```bash
make test
```

### Run Specific Test File
```bash
make test-file FILE=tests/tools_spec.lua
```

### Run Tests with Coverage
```bash
make test-coverage
```

### Lint Code
```bash
make lint
```

### Run All Checks
```bash
make check
```

## Test Structure

### Mock System

The `tests/wow_api_mock.lua` file provides mock implementations of WoW API functions:

- `UnitHealth(unit)` - Returns mocked unit health
- `UnitHealthMax(unit)` - Returns mocked max health
- `UnitExists(unit)` - Checks if mocked unit exists
- `UnitIsDead(unit)` - Checks if mocked unit is dead
- `GetTime()` - Returns mocked game time
- `ShaguDPS` - Mocked damage tracking data

### Helper Functions

- `WoWAPIMock.resetMockData()` - Reset all mock data
- `WoWAPIMock.setUnitHealth(name, current, max)` - Set unit health
- `WoWAPIMock.setIncomingDamage(name, damage, tick)` - Set incoming damage
- `WoWAPIMock.setTime(time)` - Set game time

### Test Files

- `tests/tools_spec.lua` - Tests for Tools.lua functions

## Example Test

```lua
describe("ExpectedUnitHealth", function()
  before_each(function()
    WoWAPIMock.resetMockData()
    WoWAPIMock.setTime(100)
  end)
  
  it("should subtract incoming damage from current health", function()
    WoWAPIMock.setUnitHealth("player", 80, 100)
    WoWAPIMock.setIncomingDamage("player", 20, 100)
    
    local result = ExpectedUnitHealth("player")
    assert.are.equal(60, result) -- 80 - 20 = 60
  end)
end)
```

## Functions Tested

### ExpectedUnitHealth(unitName)

Calculates expected unit health after incoming damage from DamageComm.

**Parameters:**
- `unitName` (string) - Name of the unit to check

**Returns:**
- (number) - Expected health after incoming damage, clamped to 0 minimum

**Test Cases:**
- Handles nil/invalid unit names
- Returns 0 for non-existent units
- Returns 0 for dead units
- Subtracts incoming damage from current health
- Clamps result to 0 (no negative health)
- Handles expired damage data (older than 5 seconds)
- Works with different unit names (player, party1, etc.)

## Adding New Tests

1. Create a new test file in `tests/` ending with `_spec.lua`
2. Require the mock system: `local WoWAPIMock = require('tests.wow_api_mock')`
3. Load your Lua files: `dofile('YourFile.lua')`
4. Write tests using Busted's `describe` and `it` functions
5. Use `before_each` to reset mock data between tests

## Continuous Integration

The Makefile commands are designed to work in CI environments. Example GitHub Actions workflow:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Lua
        run: sudo apt-get install lua5.1 luarocks
      - name: Install dependencies
        run: make dev-install
      - name: Run tests
        run: make check
```

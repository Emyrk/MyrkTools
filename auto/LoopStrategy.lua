NoopLoopStrategy = {
  always = {
    Debounce:New(0.5),
  },
  player = {},
  tank = {},
  party = {},
  rest = {},
}

PriestLoopStrategy = {
  always = {
    Debounce:New(0.5),
    IsDead,
    PlayerIsDrinking,
    Mounted(),
    -- Quick exit if we're already doing something
    AlreadyCasting,
    -- Calc incoming dmg, heals, etc
    RefreshPartyState,
    -- TODO: If spell targeting, reset it.
    -- See if we can cast anything
    CastableHeal("Lesser Heal(Rank 1)", "Renew(Rank 1)"),
    -- If in spirit mode, go full send on healing
    SpiritFlashHeal,
  },
  ---@type table<string, fun(engine:DecisionEngine, player:AllyPlayer):Action|nil> List of decision nodes to evaluate every loop
  player = {
    PowerWordShield(0.15),
    FlashHeal(0.75, 2.5),
  },
  tank = {
    PowerWordShield(0.15),
    FlashHeal(0.75, 3.5),
    -- Always heal a tank that is ttd 5s and <50%
    PriestDynamicHeal(0.5, 5, nil, 2.5),
    -- Always heal a tank at <25%
    PriestDynamicHeal(0.25, nil, nil, 2.5)
  },
  party = {
    PowerWordShield(0.15, 4),
    FlashHeal(0.75, 3.5),
    PriestDynamicHeal(0.85, nil, nil, 2.5),
    -- TODO: Pets and prayer of healing
  },
  rest = {
    Wanding:New(),
  },
}

ShamanLoopStrategy = {
  always = {
    Debounce:New(0.5),
    IsDead,
    PlayerIsDrinking,
    Mounted(),
    -- Quick exit if we're already doing something
    AlreadyCasting,
    -- Calc incoming dmg, heals, etc
    RefreshPartyState,
    -- TODO: If spell targeting, reset it.
    -- See if we can cast anything
    CastableHeal("Healing Wave(Rank 1)", nil),
  },
  ---@type table<string, fun(engine:DecisionEngine, player:AllyPlayer):Action|nil> List of decision nodes to evaluate every loop
  player = {

  },
  tank = {
    -- Always heal a tank that is ttd 5s and <50%
    ShamanDynamicHeal(0.5, 5, nil, 2.5),
    -- Always heal a tank at <25%
    ShamanDynamicHeal(0.25, nil, nil, 2.5)
  },
  party = {
    ShamanDynamicHeal(0.90, nil, nil, 2),
  },
  rest = {
  },
}
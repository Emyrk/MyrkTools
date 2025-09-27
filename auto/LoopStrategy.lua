NoopLoopStrategy = {
  always = {
    Debounce:New(0.5),
  },
  player = {},
  tank = {},
  party = {},
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
  },
  ---@type table<string, fun(engine:DecisionEngine, player:AllyPlayer):Action|nil> List of decision nodes to evaluate every loop
  player = {
    PowerWordShield(0.15),
  },
  tank = {

  },
  party = {

  },
}
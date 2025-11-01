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
  SpellQueueEvaluate(),

  PowerWordShield("player", 0.15),
  FlashHeal("player", 0.75, 2.5),

  PowerWordShield("tank", 0.15),
  FlashHeal("tank", 0.75, 3.5),
  -- Always heal a tank that is ttd 5s and <50%
  PriestDynamicHeal("tank", 0.5, 5, nil, 2.5),
  -- Always heal a tank at <25%
  PriestDynamicHeal("tank", 0.25, nil, nil, 2.5),
  
  PowerWordShield("party", 0.15, 4),
  FlashHeal("party", 0.75, 3.5),
  PriestDynamicHeal("party", 0.85, 10, nil, 2.5),
  PriestDynamicHeal("party", 0.75, nil, nil, 2.5),
  OnlyNotCombat(
    PriestDynamicHeal("party", 0.90, nil, nil, 2.5)
  ),

  Renew("party", 0.75, 0.3, 12),
  NotInstance(
    Renew("party", 0.75, 0, 45)
  ),

  HealFocus(0.75),

  NotInstance(
    OnlyInCombat(Smite())
  ),

  OnlyNotCombat(
    PriestChampion()
  )
}

ShamanLoopStrategy = {

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

  -- Always heal a tank that is ttd 5s and <50%
  ShamanDynamicHeal("tank", 0.5, 5, nil, 2.5),
  -- Always heal a tank at <25%
  ShamanDynamicHeal("tank", 0.25, nil, nil, 2.5),

  ShamanDynamicHeal("party", 0.90, 10, nil, 2),
  ShamanDynamicHeal("party", 0.85, nil, nil, 2),
  OnlyNotCombat(
    ShamanDynamicHeal("party", 0.90, nil, nil, 2.5)
  ),
}


function DebugExecution(message) 
  -- print("DEBUG: " .. message)
end
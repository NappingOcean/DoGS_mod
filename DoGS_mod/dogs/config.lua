-- Initial values from docs/claude/experiment-plan.md. Tune from play logs only.
return {
  dog_id = "mon_dog",
  radius = 8,

  retreat = {
    adjacent = 2,      -- enter with this many adjacent enemies
    hp = 0.4,          -- or at/below this HP ratio with an enemy within `flee` tiles
    nearby = 4,        -- or this many enemies within 3 tiles
    exit_nearby = 2,   -- exit needs 0 adjacent and at most this many within 3 tiles
    hold = 2,          -- minimum turns before exit
    -- At low HP the dog stays out of the fight while any enemy is visible (E1: re-engaging killed #4 and #8).
    flee = 5,          -- at low HP, an enemy this close starts the fall-back behind the player
    -- Object permanence: an enemy that leaves perception still counts for this many turns.
    -- E3: the low-HP retreat released whenever the pursuer left sight or the radius, then re-entered.
    memory = 5,
  },
  -- block: after the engine replaces a delegated destination, DoGS steps itself for this many turns.
  -- E5: delegating whenever no enemy was within `radius` let the engine chase a farther target.
  regroup = { enter = 8, exit = 4, hold = 3, block = 5 },

  -- Control attacks need a lone target: at most this many enemies within 3 tiles.
  control_nearby = 2,

  -- Mirrors json/dogs.json; DoGS owns these cooldowns, not the engine.
  attacks = {
    dogs_takedown = { cooldown = 8, label = "Takedown" },
    dogs_ankle_tear = { cooldown = 8, label = "Ankle Tear" },
  },
  attack_ids = { "dogs_takedown", "dogs_ankle_tear" },
  takedown_targets = { mon_zombie = true },

  -- Restraints and riding states the engine must handle itself. finalize.lua checks each ID.
  -- heavysnare/lightsnare are referenced in monster.cpp but have no JSON definition at ef0eced.
  blockers = { "beartrap", "crushed", "downed", "grabbed", "in_pit", "tied", "webbed", "stunned",
    "riding", "harnessed", "led_by_leash", "pacified" },

  summary_interval = 10,
}

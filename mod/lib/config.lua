return {
  dog_id = "mon_dog", radius = 8, leash = 6, hp_retreat = 0.5, adjacent_retreat = 2, nearby_retreat = 4,
  attacks = { "dogs_takedown", "dogs_ankle_tear" },
  -- IDs resolved from effects.json and effect.cpp's movement impairment list.
  blockers = { "beartrap", "crushed", "downed", "grabbed", "heavysnare",
    "in_pit", "lightsnare", "tied", "webbed", "stunned", "riding", "harnessed", "led_by_leash", "pacified" }
}

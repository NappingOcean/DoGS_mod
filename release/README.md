# DoGS — Dogs of Good Sense 0.1.0

[한국어](README.ko.md)

A dog AI mod for **Cataclysm: Bright Nights**. DoGS does not make dogs stronger. It gives trained dogs judgment about position, risk and when to step in.

## Requirements

- A Cataclysm: Bright Nights experimental build with Lua (Lua API 2). Checked on build `2026-10-16-0238`. On an older build that lacks the Lua functions DoGS needs, loading reports an error naming the missing function.

## Install

1. Extract the zip into the game's `mods` folder, so that you have `mods/DoGS/modinfo.json`.
2. Turn on **DoGS — Dogs of Good Sense** in the world's mod list (category: creatures).

## How to use it

1. Tame a dog with dog food, as in the base game.
2. Train it to training level 1 or more with the base game's training (pet menu → Train).
3. Craft a **command dog whistle** (Other → Tools; same materials and skills as the wooden dog whistle) and use it to give the dog a role.

| Training level | What the dog can do |
| --- | --- |
| 0 | Nothing new; it behaves like a normal pet |
| 1 | Roles (Guard, Free) and the safety rules below |
| 2 | Control attacks: Takedown and Ankle Tear |
| 3 and up | Nothing more in 0.1.0; the base game's stat gains only |

A dog at level 1 or more shows the effect **[DoGS] Trained dog**. Beagles, Chihuahuas and dachshunds train only up to level 2.

### Roles

- **Guard** (default): stays within 3 tiles of you and takes on enemies that come at you or at the dog. It ignores distant enemies.
- **Free**: fights like a normal pet, mixing in control attacks.

### What a trained dog does on its own

- Steps away before it is surrounded.
- When badly hurt, falls back behind you and stays out of the fight until the enemy is gone.
- **Takedown** knocks a lone enemy down so you and the dog can hit it. The dog tries it only on enemies it is heavy enough to bring down.
- **Ankle Tear** wounds a leg and slows the enemy.

## Covered dogs

Labrador mutt, Australian cattle dog, border collie, beagle, boxer, bulldog, Chihuahua, dachshund, Great Pyrenees, German shepherd, pit bull mix, rottweiler. Puppies are covered once they grow up.

## Known limits

- The dog does not avoid your line of fire. A dog farther along the line than the tile next to you can be shot.
- Hostile NPCs are not treated as enemies by the dog's judgment.
- While enemies are in sight the dog moves one tile at a time without pathfinding, so it may get stuck around obstacles.
- The base game's dog whistle still works as before (stop/resume attacking for all dogs); DoGS dogs respect it.

## License and source

See `LICENSE`. Source, design notes and issue reports: <https://github.com/NappingOcean/DoGS_mod>

# DoGS — Dogs of Good Sense

[한국어](README.ko.md)

An experimental dog AI mod for **Cataclysm: Bright Nights**. DoGS does not make dogs stronger; it gives trained dogs judgment about position, risk and when to step in, so they work as tactical companions.

## What it does

- Runs as a judgment layer over BN's stock pet AI for 12 adult dog breeds. Capabilities open with BN's pet training level; untrained dogs keep the normal AI.
- **Roles** set per dog: **Guard** (default) stays within 3 tiles of the player and takes on enemies that close in; **Free** fights like a normal pet with control attacks mixed in.
- **Takedown** knocks enemies down so the player and dog hit them easily; **Ankle Tear** slows them with a leg wound.
- **Safety veto:** avoids encirclement, and at low HP falls back behind the player instead of fighting on.

Planned: firing-line avoidance and the Harass role (holding up the next enemy near the player so enemies do not arrive at once).

**Status:** 0.1.0 for redhot BN (Lua API 2), checked on build `2026-10-16-0238`. Source in [`DoGS_mod/`](DoGS_mod/).

## Install

Players: download `DoGS-<version>.zip` from [Releases](https://github.com/NappingOcean/DoGS_mod/releases) and extract it into the game's `mods` folder. The README inside the zip explains how to use the mod.

From the repository (development):

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN game directory>
.\scripts\Test-Mod.ps1 -GameDirectory <BN game directory>
```

Enable **DoGS — Dogs of Good Sense** in a test world, tame a dog, raise it to training level 1 or more with BN's training (Train in the pet menu), and set its role with the **command dog whistle** (crafting: Other → Tools). Experiment tools and logs need `dev_tools = true` in `DoGS_mod/dogs/config.lua` ([development guide](docs/en/development.md#developer-tools)).

## Documentation

Start with the [documentation index](docs/en/index.md) ([한국어](docs/ko/index.md)): philosophy, behavior design, roadmap, development guide and experiment results.

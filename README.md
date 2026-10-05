# DoGS — Dogs of Good Sense

[한국어](README.ko.md)

An experimental dog AI mod for **Cataclysm: Bright Nights**. DoGS does not make dogs stronger; it gives trained dogs judgment about position, risk and when to step in, so they work as tactical companions.

## What it does

- Runs as a judgment layer over BN's stock pet AI for the Labrador mutt; untrained dogs keep the normal AI.
- **Roles** set per dog: **Guard** (default) stays within 3 tiles of the player and takes on enemies that close in; **Free** fights like a normal pet with control attacks mixed in.
- **Takedown** knocks enemies down so the player and dog hit them easily; **Ankle Tear** slows them with a leg wound.
- **Safety veto:** avoids encirclement, and at low HP falls back behind the player instead of fighting on.

Planned: firing-line avoidance and the Harass role (holding up the next enemy near the player so enemies do not arrive at once).

**Status:** experimental build for redhot BN (Lua API 2) in [`DoGS_mod/`](DoGS_mod/). Experiments E0–E6 are recorded.

## Install

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN game directory>
.\scripts\Test-Mod.ps1 -GameDirectory <BN game directory>
```

Enable **DoGS — Dogs of Good Sense (rebuild)** in a test world, tame a Labrador mutt, and open action menu → Misc → **DoGS laboratory** to train it and set its role.

## Documentation

Start with the [documentation index](docs/en/index.md) ([한국어](docs/ko/index.md)): philosophy, behavior design, roadmap, development guide and experiment results.

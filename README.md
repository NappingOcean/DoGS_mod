# DoGS — Dogs of Good Sense

[한국어](README.ko.md)

An experimental dog AI mod for **Cataclysm: Bright Nights**. DoGS turns trained dogs into tactical companions through positioning, threat assessment, enemy separation, and timely retreats.

## Planned behavior

- Assist the player, intercept approaching enemies, skirmish at group edges, retreat, and regroup.
- Use **Takedown** for immediate control and **Ankle Tear** for mobility disruption.
- Visually lure exposed enemies away, break pursuit, and return safely.
- Apply DoGS behavior to trained individual dogs while preserving normal AI for untrained dogs.

**Status:** experimental build for redhot BN (Lua API 2), in [`DoGS_mod/`](DoGS_mod/). DoGS is a judgment layer over the stock pet AI for the Labrador mutt: it steps in for a safety veto (including a low-HP fall-back behind the player), Takedown/Ankle Tear control attacks, a leash, and the Guard role (the default), and otherwise leaves the dog to the engine. Training and role are set per dog in the action menu. Experiments E0–E6 are recorded; LURE, the Harass role and production training are future work.

Install, test and experiment results: [experiment plan](docs/claude/experiment-plan.md).

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN game directory>
.\scripts\Test-Mod.ps1 -GameDirectory <BN game directory>
```

See the [English design documentation](docs/en/index.md) or [한국어 설계 문서](docs/ko/index.md) for architecture, implementation constraints, and the roadmap.

# DoGS — Dogs of Good Sense

[한국어](README.ko.md)

An experimental dog AI mod for **Cataclysm: Bright Nights**. DoGS turns trained dogs into tactical companions through positioning, threat assessment, enemy separation, and timely retreats.

## Planned behavior

- Assist the player, intercept approaching enemies, skirmish at group edges, retreat, and regroup.
- Use **Takedown** for immediate control and **Ankle Tear** for mobility disruption.
- Visually lure exposed enemies away, break pursuit, and return safely.
- Apply DoGS behavior to trained individual dogs while preserving normal AI for untrained dogs.

**Status:** modular laboratory MVP for redhot BN (Lua API 2). One adult dog type, provisional NORMAL tactics, control attacks, and action-menu controls with automatic logging are implemented. Data loading and Lua fixtures pass on 2026-10-04; live combat and save/load tests remain pending. LURE and production training are future work.

Install and test: [MVP laboratory](docs/en/mvp.md).

See the [English design documentation](docs/en/index.md) or [한국어 설계 문서](docs/ko/index.md) for architecture, implementation constraints, and the roadmap.

For sustained combat experiments, this laboratory build gives mon_dog 3,000 base maximum HP. This is temporary test configuration, not final balance.

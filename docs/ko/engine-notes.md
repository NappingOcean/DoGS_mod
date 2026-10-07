# 엔진 사실: DoGS가 기대는 BN 동작

[English](../en/engine-notes.md) · [목차](index.md)

구현이 기대는 BN의 동작을 모은다. 기준은 BN 커밋 `ef0eced`(redhot `2026-10-04-0345`)다. 표기: [소스] 소스로 확인, [실행 E#] 플레이 로그로 확인([실험 기록](experiments.md)), 미확인. Codex의 이전 감사는 [source-verification](source-verification.md)과 [combat-hooks](combat-hooks.md)에 있다(`e0e25e9` 기준).

## 모드 로딩과 Lua

- [소스] 모드를 불러오는 동안 `package.path`가 그 모드 폴더로 설정되고, 로딩이 끝나면 비워진다([catalua.cpp:491][load], [:503][unload]). 그래서 모듈은 로딩 중에 불러 지역 변수로 잡아 두고, 게임 콜백 안에서는 `require`하지 않는다.
- [소스] 모듈 탐색기는 `lib.*`와 `bn.lib.*`를 `data/lua/lib/`로 보낸다. 그 밖의 이름은 모드 폴더, 그다음 게임 폴더에서 찾는다([catalua_loader.cpp:110][loader]). `package.loaded`는 모든 모드가 공유한다. 그래서 DoGS 모듈은 `dogs.` 접두사를 쓴다.
- [소스] `game.mod_storage`의 모드별 테이블은 월드와 함께 저장되고, 불러올 때 같은 테이블에 다시 채워진다([catalua.cpp:236][storage]). 로딩 중에 잡아 둔 참조가 계속 유효하다. [실행 E4] 개체 번호 카운터가 저장·복원 뒤에도 이어졌다.
- [소스] 개체 값(`set_value`/`get_value`)은 문자열이며 Creature와 함께 저장된다([bindings_creature:309][setvalue]). 없는 키는 빈 문자열이다. [실행 E4] 훈련·상태·번호가 유지됐다.
- [실행] `--check-mods`는 Lua 로딩 오류가 나도 종료 코드 0으로 끝날 수 있다. 검사 스크립트는 출력의 `Error`도 실패로 본다.

## lua_ai 콜백

- [소스] `monster::move`는 먼저 `lua_ai` 콜백을 부른다. true를 돌려받았는데 위치와 행동력이 그대로면 행동력 100을 깎는다. false나 nil이면 일반 `plan`/`decide`/`execute`로 넘어간다([monmove.cpp:1871][move], [:124][runlua]).
- [소스] 행동마다 특수공격 예산이 하나다. Lua가 `use_special_attack`으로 쓰면 그 행동에서 스케줄러는 다시 쓰지 않는다.
- [실행 E0] 같은 ID 자기 복사(`copy-from`)로 `mon_dog`을 덮어쓰고 `lua_ai`와 `extend.special_attacks`를 붙이는 방식이 로딩·동작했다.

## 펫 AI의 표적과 목적지

- [소스] 우호 몬스터의 `plan`은 매 행동 적대 몬스터 중 평가가 가장 좋은 것을 표적으로 다시 고른다([monmove.cpp:626][plan]).
- [소스] `docile`인 우호 몬스터는 `plan`에서 표적을 고르지 않는다([monmove.cpp:516](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L516)). 기존 도그 휘슬이 이 효과를 켜고 끈다.
- [소스] `set_move_target(pos)`는 목적지만 정한다. `set_target(creature)`는 대상의 현재 위치를 목적지로 복사할 뿐이다([bindings_creature:526][setmove], [:533][settarget]).
- [실행 E3] 목적지를 정하고 false를 돌려주면, 엔진은 표적이 없을 때만 그 목적지를 유지한다(37/37). 표적이 있으면 표적 쪽으로 바꾼다.
- [실행 E5] 엔진은 DoGS의 8타일 인식보다 먼 표적도 잡는다. "엔진에 표적이 없다"는 DoGS 쪽에서 직접 알 수 없다. 8e8aa90부터 `attack_target()`으로 개가 보는 표적은 알 수 있지만, 냄새·소리로 쫓는 표적은 알 수 없다(다음 절).

## 8e8aa90에서 추가된 몬스터 바인딩

기준은 BN `8e8aa90`(redhot `2026-10-05-2327`)이며 BN #10504로 들어왔다. DoGS는 앞의 네 가지를 쓴다. 앞의 세 가지 중 하나라도 없으면 `finalize.lua`가 로딩을 실패시킨다.

- [소스] `attack_target()`은 몬스터가 배회 중이 아니고, `move_target` 위의 생물이 그 몬스터에게 우호적이지 않으며, 몬스터가 그 생물을 볼 때 그 생물을 돌려준다. 아니면 nil이다([monster.cpp:1776](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monster.cpp#L1776), [bindings_creature:513](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_creature.cpp#L513)). 엔진의 붙잡기 공격도 이것으로 표적을 고른다([monattack.cpp:2936](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monattack.cpp#L2936)). `lua_ai`는 `plan`보다 먼저 돌므로, 개의 콜백에서 읽으면 각 몬스터의 직전 계획이 나온다. `track`(`chases`)과 `probe_result`(`engine_target`)에 쓴다.
- [소스] `movement_impaired()`는 하드코딩된 효과 집합으로 채운 캐시를 읽는다: beartrap, crushed, downed, grabbed, heavysnare, in_pit, lightsnare, tied, webbed. JSON으로는 늘릴 수 없다([effect.cpp:1355](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/effect.cpp#L1355), [:1477](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/effect.cpp#L1477)). DoGS는 이것을 구속 검사에 더해, JSON ID가 없어 목록에 넣지 못한 두 덫을 잡는다.
- [소스] `is_dead_or_dying()`은 `monster::is_dead`를 묶은 것이다. 이미 죽었거나 HP가 0 이하이면 true다. 기존 `is_dead`는 HP만 본다([monster.cpp:4341](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monster.cpp#L4341), [bindings_creature:524](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_creature.cpp#L524)). 넘어뜨리기는 일격에 죽은 표적에 넘어짐을 걸지 않는 데 쓴다.
- [소스] `can_act()`: 행동력이 남았고 기절·넘어짐·거미줄 상태가 아니다([monster.cpp:1563](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monster.cpp#L1563)). 아직 쓰지 않는다.
- [소스] 읽기 전용이며 아직 쓰지 않는 것: `is_fleeing(character)`, `get_grab_strength()`, 멤버 `training_level`과 `pet_bond_level`(BN 자체의 펫 훈련과 유대), 몬스터 종류의 `melee_dice`, `melee_sides`, `melee_damage`, `grab_strength`([bindings_type_defs:48](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_type_defs.cpp#L48)). 정식 훈련과 적 위협도 평가의 후보다.
- [소스] BN #10506은 플레이어와 인접하지 않은 몬스터에서 `grabbed`를 지운다([monster.cpp:3426](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monster.cpp#L3426)). 개에는 영향이 없다. 몬스터의 붙잡기 공격은 Character만 표적으로 삼는다([monattack.cpp:2936](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monattack.cpp#L2936)).

## 특수공격

- [소스] 바인딩 문서([bindings_creature:456][special]): `special_attack_ready`는 활성 상태와 쿨다운만 본다. `use_special_attack`의 true는 actor가 시도를 처리했다는 뜻이지 명중이 아니다. true일 때 쿨다운이 초기화된다. 비활성화된 공격은 엔진의 스케줄러가 건너뛴다. 활성 상태는 저장된다.
- [소스] generic melee actor(`melee_actor::call`)는 `hit_spread < 0`이면 빗나감으로 일찍 반환한다. 명중하면 피해를 주고, 실제 피해가 양수일 때만 JSON 효과를 적용한다([mattack_actors.cpp:394][actor]).
- [소스] `Creature::deal_melee_attack`은 `hit_spread <= 0`이면 대상의 `on_dodge`를 부르고, 이것이 `on_creature_dodged` 훅을 부른다([creature.cpp:694][dealmelee], [:1407][ondodge]). 몬스터는 `on_dodge`를 덮어쓰지 않는다.
- [실행 E6] 타격 2는 뚱뚱한 좀비의 타격 방어 5에 모두 막혀 JSON의 넘어짐이 적용되지 않았다.

## 훅

| 훅 | 호출 위치와 내용 | DoGS의 사용 |
| --- | --- | --- |
| `on_creature_melee_attacked` | 몬스터의 일반 근접공격([monster.cpp:2596][monmelee])과 캐릭터의 근접공격([melee.cpp:1778][charmelee]). 명중·피해 처리 뒤. `char`, `target`, `success`. generic actor는 부르지 않는다 | `melee`, `player_melee`, `player_attacked` 로그 |
| `on_creature_dodged` | `Creature::on_dodge`. `char`(회피한 쪽), `source` | Takedown의 빗나감 감지 |
| `on_mon_death` | 몬스터 사망([monster.cpp:3813][death]). `mon`, `killer` | `death` 로그 |
| `on_shoot` | 사격 처리 뒤([ranged.cpp:1579][shoot]). `shooter`, `target_pos`, `shots`, `gun`, `ammo` | 사선 회피(계획) |

- [실행 E2, E5] 출혈 사망과 디버그 처치는 모두 `killer`가 없다(`none`). 둘은 로그로 구분할 수 없다.

## 인식과 좌표

- [소스] 몬스터가 다른 몬스터를 보는 태도는 `monster::attitude_to`가 정한다([monster.cpp](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp)). 진영표의 미움(hate)이면 적대, 사기가 0 미만이거나 분노가 10 미만이면 중립이다. 그래서 겁 많은 동물(예: 스피디어, 사기 -5·공격성 -99)은 개를 중립으로 보고, DoGS의 적 인식(개와 플레이어 모두에게 적대)에 들지 않는다.
- [소스] `sees`는 거리, 조명, 지형 투명도로 판정한다. 확인한 경로에는 다른 생물이 시야를 막는 처리가 없다([creature.cpp:455][sees]).
- [실행 E1] `get_pos_ms`는 리얼리티 버블 좌표라 맵이 이동하면 값이 바뀐다. 한 번의 판단 안에서는 문제가 없지만, 턴을 넘어 저장할 위치는 `abs_pos()`나 `gapi.bub_to_abs`로 절대 좌표를 쓴다([bindings_creature:240][abspos], [bindings_game:497][bub2abs]).

## 전투 관련 사실

- [소스] 넘어진 몬스터의 회피는 0이다([monster.cpp:3086][dodge]). [실행 E6] 플레이어는 넘어진 좀비를 5/5 맞혔다.
- [소스] 투사체는 쏘는 사람 1타일 안의 아군만 건너뛴다. 그보다 먼 사선 위의 아군은 의도치 않은 명중 판정을 받는다([ballistics.cpp:546][ballistics]).
- [소스] 조준과 발사는 플레이어의 한 행동 안에서 끝나며 그 사이 몬스터는 행동하지 않는다. `Character::last_target`은 Lua에 노출되어 있지 않다.
- [소스] 살 재질 몬스터의 자연 회복은 시간당 HP 0.25, 배부르면 두 배다([monster.cpp:3607][regen]).
- [소스] `add_effect(효과, 지속, [부위], [강도])`, `is_immune_effect`, `get_size()`(`MonsterSize`: TINY~HUGE)가 Lua에 있다([bindings_creature:289][addeffect], [:365][getsize]).

## 펫 가방과 몬스터 소지품

기준 `8e8aa90`. 회수 설계([행동 설계](design.md) 7절)가 기댄다.

- [소스] 기계 탈것을 뺀 펫에는 저장 공간이 있는 방어구를 가방으로 달 수 있다. 일반 배낭도 된다([monexamine.cpp:1171](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monexamine.cpp#L1171)). 가방은 `storage_item`에 들고 `has_bag` 효과가 붙는다([monster.cpp:1727](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monster.cpp#L1727)).
- [소스] 가방에 넣은 아이템은 가방 아이템 안이 아니라 몬스터 소지품 `inv`에 들어간다. "Take items from bag" 메뉴는 `has_bag`이고 `inv`가 비어 있지 않을 때만 나온다([monexamine.cpp:489](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monexamine.cpp#L489), [:1261](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monexamine.cpp#L1261)).
- [소스] 바닐라의 넣기 메뉴는 `weight_capacity − 지닌 무게`와 `가방 storage − 지닌 부피`로 용량을 검사한다([monexamine.cpp:1220](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monexamine.cpp#L1220)). `monster::add_item`은 검사하지 않는다([monster.cpp:4686](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monster.cpp#L4686)).
- [소스] `inv`는 저장 파일에 남고, 몬스터가 죽으면 그 자리에 떨어진다. 가방을 떼면 내용물이 플레이어 칸에 쏟아진다([monster.cpp:3736](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monster.cpp#L3736), [monexamine.cpp:1195](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/monexamine.cpp#L1195)).
- [소스] Lua 바인딩: 몬스터 `get_items`, `add_detached_item`, `remove_item`, `drop_items`, `get_storage_item`([bindings_creature:638](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_creature.cpp#L638), [:536](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_creature.cpp#L536)), `get_weight_capacity`([:423](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_creature.cpp#L423)). 맵 `get_items_at`, `get_items_in_radius`, `detach_item_at`, `add_item`([bindings_map:441](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_map.cpp#L441)). 아이템 `weight`, `volume`.
- [소스] 몬스터 플래그 `CAN_FETCH`는 enum과 문자열 변환만 있고 쓰는 곳이 없다([mtype.h:180](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/mtype.h#L180); 사용처는 `8e8aa90`의 `src`, `data`, `docs`, `tests` 전체 검색).
- 미확인: 가방 아이템의 부피(`storage`)를 Lua에서 읽는 경로, 플레이어 소지품에서 아이템을 고르는 Lua UI.

## 데이터

- [소스] 몬스터 JSON에는 크기 필드가 없다. 크기는 로딩 때 `volume`(부피)에서 계산된다: 7.5L 이하 TINY, 46.25L 이하 SMALL, 77.5L 이하 MEDIUM, 483.75L 이하 LARGE, 그 이상 HUGE([monstergenerator.cpp:321](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monstergenerator.cpp#L321), [:412](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monstergenerator.cpp#L412)). 효과의 크기 보너스가 더해질 수 있다([monster.cpp:4256](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L4256)).
- [소스] `heavysnare`, `lightsnare`는 C++에서 참조되지만([monster.cpp:145][snare]) JSON 효과 정의가 없다. 효과 ID 검사에 넣으면 실패한다.
- 몬스터 수치([mammal.json:918][mondog], [zed-classic.json:52][zombie], [:312][fat]):

| ID | HP | 속도 | 비고 |
| --- | --- | --- | --- |
| `mon_dog` | 30 | 150 | `HIT_AND_RUN` 등. Labrador mutt |
| `mon_zombie` | 80 | 70 | 부피 62.5L(MEDIUM), 무게 81.5kg |
| `mon_zombie_fat` | 95 | 55 | 타격 방어 5. 부피·무게는 `mon_zombie`와 같다(MEDIUM) |

[load]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua.cpp#L491
[unload]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua.cpp#L503
[loader]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_loader.cpp#L110
[storage]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua.cpp#L236
[setvalue]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L309
[move]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L1871
[runlua]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L124
[plan]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monmove.cpp#L626
[setmove]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L526
[settarget]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L533
[special]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L456
[actor]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/mattack_actors.cpp#L394
[dealmelee]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/creature.cpp#L694
[ondodge]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/creature.cpp#L1407
[monmelee]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L2596
[charmelee]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/melee.cpp#L1778
[death]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L3813
[shoot]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/ranged.cpp#L1579
[sees]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/creature.cpp#L455
[abspos]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L240
[bub2abs]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_game.cpp#L497
[dodge]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L3086
[ballistics]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/ballistics.cpp#L546
[regen]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L3607
[addeffect]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L289
[getsize]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/catalua_bindings_creature.cpp#L365
[snare]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L145
[mondog]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/data/json/monsters/mammal.json#L918
[zombie]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/data/json/monsters/zed-classic.json#L52
[fat]: https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/data/json/monsters/zed-classic.json#L312

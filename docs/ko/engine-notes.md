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
- [소스] 읽기 전용이며 아직 쓰지 않는 것: `is_fleeing(character)`, `get_grab_strength()`, 멤버 `training_level`과 `pet_bond_level`(BN 자체의 펫 훈련과 유대), 몬스터 종류의 `melee_dice`, `melee_sides`, `melee_damage`, `grab_strength`([bindings_type_defs:48](https://github.com/cataclysmbn/Cataclysm-BN/blob/8e8aa90498fcc04176ee26ddd5bd56d68218b6a9/src/catalua_bindings_type_defs.cpp#L48)). `training_level`은 획득과 훈련 설계([행동 설계](design.md) 7절)가 쓴다. 나머지는 적 위협도 평가의 후보다.
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

- [소스] 몬스터가 다른 몬스터를 보는 태도는 `monster::attitude_to`가 정한다([monster.cpp](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp)). 진영표의 미움(hate)이면 적대, 사기가 0 미만이거나 분노가 10 미만이면 중립이다. 그래서 겁 많은 동물(예: 스피디어, 사기 -5·공격성 -99)은 개를 중립으로 보고, DoGS의 적 인식(개나 플레이어에게 적대)에 들지 않는다.
- [소스] 본편 개는 `aggro_character: false`다(`mon_dog`, [mammal.json:935](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/data/json/monsters/mammal.json#L935)). 견종은 모두 이를 복사한다. 다른 몬스터에게 물리면 `HURT` 트리거로 분노가 오르지만, `aggro_character`는 몬스터가 아닌 것에게 피해를 입었을 때만 켜진다([monster.cpp:2740](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monster.cpp#L2740)). 이것이 꺼져 있으면 `monster::attitude`는 분노와 관계없이 캐릭터를 무시한다([monster.cpp:2096](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monster.cpp#L2096)). 그래서 펫에게 물린 야생 개는 펫에게는 적대하면서 플레이어에게는 중립으로 남는다. 몬스터가 다른 몬스터를 무는 것은 `attitude_to`가 적대일 때(또는 `ATTACKMON`)뿐이다([monmove.cpp:2390](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monmove.cpp#L2390)). 기준 `f9586ef`.
- [실행 E10-A] 야생 핏불 믹스가 Labrador를 계속 물었다. 1단계·엄호인 Labrador는 반격하지 않은 채 HP를 잃고 그중 한 마리에게 죽었다. 그동안 로그는 `enemies=0`이었다. 당시 적 인식은 개와 플레이어 모두에게 적대일 것을 요구했다. 지금은 둘 중 하나면 된다.
- [소스] 본편 개에는 `HIT_AND_RUN`이 있다(`mon_dog` 플래그, [mammal.json:968](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/data/json/monsters/mammal.json#L968)). 일반 근접 공격을 할 때마다 4턴짜리 `run` 효과가 붙고([monster.cpp:2482](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monster.cpp#L2482)), 이 효과는 도망 상태를 켠다([monster.cpp:4048](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monster.cpp#L4048)). 기준 `f9586ef`.
- [소스] 효과 종류의 `blocks_effects`는 그 효과가 있는 동안 나열된 효과가 새로 붙지 않게 한다([effect.cpp:1436](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/effect.cpp#L1436), [creature.cpp:1522](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/creature.cpp#L1522)). 이미 붙어 있는 효과를 지우지는 않는다. `permanent`는 지속 시간이 줄지 않게 하고([effect.cpp:1465](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/effect.cpp#L1465)), `show_in_info`는 몬스터 상태 표시에 효과를 넣는다([monster.cpp:2946](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monster.cpp#L2946)). 기준 `f9586ef`.
- [실행 E10-A, E10-B] 엄호 개가 물고 나서 같은 칸으로 되돌아오기를 반복했다. DoGS가 개를 적에게 붙이면, 도망 상태인 엔진은 물지 않고 다시 물러났고, 이 순환이 되풀이됐다.
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

## 펫 훈련과 견종

기준 `a27f19d`. 획득과 훈련 설계([행동 설계](design.md) 7절)가 기댄다.

- [소스] 훈련할 수 있는 몬스터는 JSON에 `pet_training`이 있다. 최대 단계와 단계별 배율이 여기서 정해진다([monstergenerator.cpp:880](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/monstergenerator.cpp#L880)).
- [소스] 펫 메뉴의 Train은 생존 기술이 `min_skill` 이상이고 개가 `well_fed`일 때 열리는 60분 활동이다([monexamine.cpp:511](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/monexamine.cpp#L511)). 끝나면 생존 기술 × 10%(유대 완성 시 2배) 확률로 단계가 하나 오른다([activity_handlers.cpp:4441](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/activity_handlers.cpp#L4441)).
- [소스] 유대 `pet_bond_level`은 0~10이다. 먹이기, 놀아 주기, 훈련으로 오르며, 한 번 오른 뒤 8시간은 잘 오르지 않는다. 10이면 유대가 완성된다([monster.cpp:4227](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/monster.cpp#L4227)).
- [소스] 배율은 단계마다 HP 최대치, 명중 기술, 회피 기술에 곱해진다([monster.cpp:3026](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/monster.cpp#L3026), [:4514](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/monster.cpp#L4514)). 근접 피해와 속도는 바뀌지 않는다. `melee_mult`도 명중 기술에만 곱해진다.
- [소스] 강아지가 자라도 훈련 단계와 유대는 유지된다([monster.cpp:545](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/monster.cpp#L545)). 실행 미확인.

견종별 훈련 단계와 최대 단계에서의 스탯이다(`data/json/monsters/mammal.json`, `mutant_animal.json`, 상속을 풀어 계산). 화살표는 기본 → 최대 단계다. 명중·회피 기술은 엔진이 쓰는 실수 값이고, HP 최대치는 정수로 내린다.

| ID | 이름 | 최대 단계 | HP 최대치 | 명중 기술 | 회피 기술 | 근접 피해 | 속도 | 생존 기술 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `mon_dog_beagle` | 비글 | 2 | 13 → 15 | 2 → 2.42 | 3 → 3.97 | 1d1+cut 2 | 135 | 3 |
| `mon_dog_chihuahua` | 치와와 | 2 | 6 → 6 | 3 → 3.63 | 3 → 3.97 | 2d2+cut 2 | 135 | 3 |
| `mon_dog_dachshund` | 닥스훈트 | 2 | 10 → 12 | 3 → 3.63 | 3 → 3.97 | 2d2+cut 3 | 135 | 3 |
| `mon_dog` | Labrador mutt | 3 | 30 → 51 | 6 → 9.13 | 3 → 4.56 | 2d3+cut 3 | 150 | 3 |
| `mon_dog_pup` | Labrador 강아지 | 3 | 8 → 13 | 2 → 3.04 | 1 → 1.52 | 1d1+cut 1 | 98 | 3 |
| `mon_dog_bcollie` | 보더 콜리 | 3 | 19 → 25 | 6 → 7.99 | 4 → 7.81 | 2d3+cut 4 | 200 | 3 |
| `mon_dog_auscattle` | 캐틀 독 | 3 | 20 → 30 | 4 → 6.08 | 4 → 6.91 | 2d2+cut 6 | 200 | 3 |
| `mon_dog_bull` | 불독 | 3 | 47 → 91 | 4 → 6.91 | 3 → 3.99 | 2d2+cut 6 | 135 | 3 |
| `mon_dog_gpyrenees` | 그레이트 피레니즈 | 3 | 40 → 78 | 6 → 9.13 | 2 → 2.66 | 1d1+cut 5 | 100 | 3 |
| `mon_dog_mutant_mongrel` | 잡종견(변이) | 3 | 30 → 51 | 6 → 9.13 | 3 → 4.56 | 2d3+cut 3 | 150 | 3 |
| `mon_coyote` | 코요테 | 3 | 22 → 33 | 6 → 9.13 | 3 → 5.18 | 2d3+cut 2 | 155 | 3 |
| `mon_dog_boxer` | 복서 마스티프 | 4 | 29 → 60 | 4 → 9.77 | 3 → 5.25 | 2d2+cut 4 | 150 | 3 |
| `mon_dog_pitbullmix` | 핏불 믹스 | 4 | 27 → 55 | 4 → 9.77 | 3 → 5.25 | 2d2+cut 5 | 135 | 3 |
| `mon_dog_rottweiler` | 로트와일러 | 4 | 42 → 102 | 4 → 8.29 | 3 → 5.25 | 2d2+cut 6 | 135 | 3 |
| `mon_dog_gshepherd` | 저먼 셰퍼드 | 5 | 36 → 89 | 6 → 14.93 | 3 → 7.46 | 2d3+cut 6 | 150 | 3 |
| `mon_wolf` | 늑대 | 5 | 40 → 99 | 7 → 17.42 | 4 → 9.95 | 2d3+cut 4 | 165 | 5 |

- [소스] 훈련할 수 없는 것: Labrador를 뺀 모든 강아지(자란 뒤에는 훈련할 수 있다), `mon_coyote_wolf`, 여우, 좀비 개, 네더 개.
- [소스] `mon_dog`와 `mon_dog_boxer`를 뺀 견종은 `flags`를 새로 정의하는데(물려받지 않고 대체된다, [monstergenerator.cpp:1080](https://github.com/cataclysmbn/Cataclysm-BN/blob/a27f19d399be26836b45462f4784079f54eca704/src/monstergenerator.cpp#L1080)) 그 안에 `DOG_WHISTLE`이 없다. 본편 휘슬에 반응하지 않을 것으로 보인다. 실행 미확인.

## 데이터

- [소스] 몬스터 JSON에는 크기 필드가 없다. 크기는 로딩 때 `volume`(부피)에서 계산된다: 7.5L 이하 TINY, 46.25L 이하 SMALL, 77.5L 이하 MEDIUM, 483.75L 이하 LARGE, 그 이상 HUGE([monstergenerator.cpp:321](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monstergenerator.cpp#L321), [:412](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monstergenerator.cpp#L412)). 효과의 크기 보너스가 더해질 수 있다([monster.cpp:4256](https://github.com/cataclysmbn/Cataclysm-BN/blob/ef0eceda391d4d291b366e3bf2833b04c7342d72/src/monster.cpp#L4256)).
- [소스] `get_weight()`가 Lua에 있고 `Mass`를 돌려준다. `to_gram()`으로 그램을 읽는다([bindings_creature:328](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/catalua_bindings_creature.cpp#L328), [catalua_bindings.cpp:115](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/catalua_bindings.cpp#L115)). 몬스터의 무게는 종류의 `weight`이고, 효과로 크기가 바뀌면 크기 단계 비율로 곱해진다([monster.cpp:4274](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monster.cpp#L4274)). 훈련 단계는 읽기 전용 `training_level`이다([bindings_creature:447](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/catalua_bindings_creature.cpp#L447)). 기준 `f9586ef`. Takedown의 체중비가 기댄다.
- [소스] `f9586ef`의 `data/json/monsters`에서 `copy-from` 없이 정의된 몬스터 429종 중 428종에 `weight`가 있다(없으면 0). 무게와 부피가 둘 다 있는 425종 중 375종(88%)은 체중/부피 비율이 중앙값 1.3kg/L의 0.6~1.7배 안이다. 벗어나는 것은 부피 875L에 무게 200kg으로 일괄 입력된 거대 몬스터와 로봇류다. 견종 다수(비글, 닥스훈트, 콜리, 핏불 믹스, 복서, 오스트레일리안 캐틀 독)는 부피를 정하지 않아 `mon_dog`의 30L를 물려받고, 무게는 견종마다 정한다.
- [소스] `gapi.register_action_menu_entry`는 `category`와 `hotkey`(그 하위 메뉴 안의 키)를 받는다. 내장 분류에 `debug`가 있고, Lua 항목이 있으면 Debug 하위 메뉴가 열린다. Lua에서 게임 전역 키를 바인딩하는 함수는 찾지 못했다([catalua_bindings_game.cpp:682](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/catalua_bindings_game.cpp#L682), [action.cpp:1099](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/action.cpp#L1099), [lua_action_menu.cpp:27](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/lua_action_menu.cpp#L27)). 기준 `f9586ef`.
- [소스] 아이템 사용 함수는 `game.iuse_functions[ID]`에 Lua 함수를 넣고, 같은 ID의 `item_action` JSON과 아이템의 `use_action`으로 잇는다. 본편 예시 모드 `change_hairstyle`가 이 방식이다. 반환값은 소모한 충전 수다. 기준 `f9586ef`.
- [소스] `copy-from`은 불러오는 순간 그때의 원본을 복사한다. 원본이 아직 없을 때만 미룬다([generic_factory.h:226](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/generic_factory.h#L226)). 본편 견종은 DoGS보다 먼저 불러와지므로, DoGS가 덮어쓴 `mon_dog`가 아니라 본편 `mon_dog`를 복사한다. 그래서 견종마다 DoGS 항목이 따로 필요하다. 기준 `f9586ef`.
- [소스] 펫은 매 턴 성장을 검사한다([monster.cpp:3544](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/monster.cpp#L3544)). 시간을 넘기면 다음 턴에 자란다. 기준 `f9586ef`.
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

# BN 소스 검사 결과


> **역사 기록.** Codex가 리비전 `e0e25e9` 기준으로 작성한 소스 감사다. 내용은 당시 그대로 둔다. 현재 구현이 기대는 사실은 [엔진 사실](engine-notes.md)(`ef0eced` 기준)을 참조한다.
기준: 공식 Cataclysm-BN main의 `e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800` (2026-10-04). 소스·JSON 로더·바인딩·예제·기존 테스트 정의를 검사했다. BN 빌드, 테스트 실행, DoGS 게임 실행은 하지 않았다. 소스 확인과 실제 플레이 검증을 구분한다.

## 적용과 저장

- **확인:** same-ID self copy-from은 이미 로드된 정의를 복사한 뒤 같은 ID를 교체한다. 로드 순서에 영향을 받는다. [src/generic_factory.h:223](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/generic_factory.h#L223), [src/generic_factory.h:351](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/generic_factory.h#L351).
- **확인:** lua_ai는 MONSTER 타입 설정이다. extend.special_attacks는 기존 목록에 추가하지만 special_attacks 전체 필드는 기존 목록을 지운다. 같은 공격 ID는 교체된다. [src/monstergenerator.cpp:868](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monstergenerator.cpp#L868), [src/monstergenerator.cpp:1013](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monstergenerator.cpp#L1013), [src/monstergenerator.cpp:1455](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monstergenerator.cpp#L1455).
- **확인:** 개체별 값은 문자열이며 Creature 저장·복원 경로를 따른다. 없는 키는 빈 문자열이다. [src/creature.cpp:1902](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/creature.cpp#L1902), [src/savegame_json.cpp:3735](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/savegame_json.cpp#L3735), [src/savegame_json.cpp:3795](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/savegame_json.cpp#L3795).
- **확인:** 공격은 기본 활성 상태이며 초기 쿨다운은 무작위다. enabled와 cooldown은 저장·복원된다. 공격 actor JSON 로더에는 초기 enabled 설정이 없다. callback에서 DoGS ID만 비활성화한 뒤 fallback한다. [src/monster.h:63](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.h#L63), [src/monster.cpp:420](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L420), [src/savegame_json.cpp:2075](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/savegame_json.cpp#L2075), [src/savegame_json.cpp:2275](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/savegame_json.cpp#L2275), [src/monstergenerator.cpp:1427](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monstergenerator.cpp#L1427).
- **호환성 제약:** 다른 모드가 같은 개의 lua_ai를 교체하거나 공격 ID를 덮어쓰거나 공격 목록을 초기화할 수 있다. DoGS가 다른 공격을 보존하는 것만으로 모든 모드 순서의 호환성을 보장하지 못한다. 실제 DoGS 정의가 생긴 뒤 조합별로 검사해야 한다.

## callback과 행동 비용

- game.monster_ai_functions에 등록하며 몬스터를 인자로 받는다. false/nil은 일반 plan/decide/execute로 이어진다. true는 이번 행동을 처리했다는 뜻이다. 위치·moves가 그대로면 최대 100 moves를 차감한다. [src/monmove.cpp:124](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monmove.cpp#L124), [src/monmove.cpp:1865](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monmove.cpp#L1865).
- 미훈련 개는 DoGS 공격을 끄고 false를 반환한다. run_normal_ai_turn()을 직접 호출했다면 true를 반환해 일반 행동이 두 번 실행되지 않게 한다. 해당 함수는 plan부터 실행한다. [src/catalua_bindings_creature.cpp:544](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L544).
- set_move_target(pos)는 목적지만 설정한다. set_target(creature)는 대상의 현재 위치를 복사하며 nil은 목적지를 지운다. 대상 개체를 지속 추적하거나 이동을 실행하지 않는다. move_to(pos, force, step_on_critter, stagger_adjustment)는 bool을 반환하는 실제 한 걸음 이동이며 이동 비용을 처리하지만 임의 waypoint까지 경로를 실행하는 API는 아니다. [src/catalua_bindings_creature.cpp:526](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L526), [src/catalua_bindings_creature.cpp:549](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L549), [src/monmove.cpp:2425](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monmove.cpp#L2425).
- waypoint만 설정하고 true를 반환하면 이동하지 않는다. 일반 AI 호출은 다시 계획해 목적지를 바꿀 수 있다. waypoint 이동 실행 방식은 구현·플레이 검증 과제다.

## 인식과 추격

- **정정:** 타일 스캔만 가능한 것이 아니다. gapi.get_all_monsters(), get_all_creatures(), get_monsters_if(filters)가 있다. sees, within_range_of={range=..., monsters={...}}, hostile_to 필터를 지원한다. 내부적으로 활성 몬스터를 순회하므로 결과 반경 제한이 곧 공간 인덱스 검색을 뜻하지는 않는다. [src/catalua_bindings_game_creatures.cpp:19](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_game_creatures.cpp#L19), [src/catalua_creature_filters.cpp:141](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_creature_filters.cpp#L141).
- sees={dog}는 개가 후보를 보는 판정이다. LURE에서는 적이 개를 보는지 별도 판정한다. hostile_to는 후보가 전달된 몬스터를 적대하는지 평가한다. [src/catalua_creature_filters.cpp:55](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_creature_filters.cpp#L55), [src/catalua_creature_filters.cpp:79](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_creature_filters.cpp#L79).
- 위치·시야·태도·효과·면역·HP·속도·moves를 사용할 수 있다. 타일 조회는 gapi.get_creature_at(pos[, allow_hallucination]) / get_monster_at이다. [src/catalua_bindings_creature.cpp:199](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L199), [src/catalua_bindings_creature.cpp:236](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L236), [src/catalua_bindings_creature.cpp:338](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L338), [src/catalua_bindings_game.cpp:706](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_game.cpp#L706).
- **부분 확인:** move_target()은 노출되지만 검사한 바인딩에는 attack_target()이 없다. C++ attack_target도 목적지의 보이는 비우호 개체를 찾을 뿐 지속적인 대상 ID가 아니다. 적의 목적지·이동 변화는 추격의 근거로 쓰되 확정된 대상 식별로 취급하지 않는다. 여러 행동과 저장·복원 사이에 대상을 재확인해야 한다. [src/monster.cpp:1776](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L1776), [src/catalua_bindings_creature.cpp:506](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L506).

## 특수공격

- has_special_attack, get_special_attack_ids, special_attack_enabled, set_special_attack_enabled, special_attack_ready, get_special_attack_cooldown, set_special_attack_cooldown, use_special_attack이 존재한다. [src/catalua_bindings_creature.cpp:456](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L456).
- ready는 활성 상태와 쿨다운 0만 검사한다. 사거리·시야는 보장하지 않는다. use의 true는 명중이 아니라 actor가 시도를 처리했다는 뜻이다. true이면 쿨다운을 초기화하고 행동당 특수공격 예산을 사용한다. 빗나가도 true일 수 있고 false의 부수효과도 자동 취소되지 않는다. Lua 호출은 일반 스케줄러의 pacified/환각 제한이나 대상 계획을 자동 적용하지 않는다. DoGS가 실행 조건과 목적지를 관리해야 한다. [src/monster.cpp:3183](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L3183), [src/mattack_actors.cpp:380](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/mattack_actors.cpp#L380), [src/catalua_bindings_creature.cpp:458](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/catalua_bindings_creature.cpp#L458).
- 실제 객체를 쓰는 공격·활성화 테스트 정의는 확인했으나 실행하지 않았다. [tests/catalua_test.cpp:77](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/tests/catalua_test.cpp#L77).

## 제압과 상처 효과

- **확인:** generic melee는 실제 피해가 양수일 때만 on_damage/effects를 실행한다. 효과 확률 100이어도 방어구가 모든 피해를 막으면 적용되지 않는다. 무피해 Takedown은 별도 적용 경로나 엔진 수정이 필요하다. [src/mattack_actors.cpp:428](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/mattack_actors.cpp#L428).
- LUNGE는 떨어진 거리에서 직접 이동 대신 200 moves를 줄 수 있다. 인접 공격은 bash 3~7, downed는 1/6 확률로 3턴이다. 신뢰성 있는 Takedown에는 맞지 않는다. [src/monattack.cpp:4914](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monattack.cpp#L4914).
- downed의 몬스터 dodge는 0이다. 일반 execute_action에서 기립 시도는 move_effects의 false로 남은 moves를 종료한다. 회복 확률은 melee dice/sides에 좌우된다. 직접 Lua 이동도 이동 방해 효과를 준수해야 한다. [src/monster.cpp:2828](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L2828), [src/monster.cpp:3086](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L3086), [src/monmove.cpp:1601](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monmove.cpp#L1601).
- bite_actor에는 grabbed 상태의 감염 효과와 toxic flesh에 의한 공격자 중독 로직이 있다. 물리적 상처의 기반은 generic melee가 적합하다. [src/mattack_actors.cpp:483](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/mattack_actors.cpp#L483).
- speed_mod는 SPEED로 로드되어 몬스터 speed bonus에 적용된다. 기본적으로 비율 배수가 아닌 보너스 값이다. [src/effect.cpp:291](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/effect.cpp#L291), [src/monster.cpp:3990](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L3990).
- **JSON과 함께 확인:** `iflesh`는 Insect Flesh(곤충의 살)이며 좀비 재질이 아니다. `mon_zombie`는 `flesh`와 `WARM`을 가져 일반 bleed 면역 조건에 걸리지 않는다. 출혈 피해와 혈흔 처리가 가능하다. 다른 좀비 타입은 개별 정의를 확인한다. WARM이 없거나 flesh가 아닌 몬스터는 일반 출혈에 면역이다. Ankle Tear의 출혈 후보를 유지하고 ID 철자만으로 재질 의미를 추측하지 않는다. [data/json/materials.json:713](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/data/json/materials.json#L713), [data/json/monsters/zed-classic.json:52](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/data/json/monsters/zed-classic.json#L52), [src/monster.cpp:2315](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L2315), [src/monster.cpp:4032](https://github.com/cataclysmbn/Cataclysm-BN/blob/e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800/src/monster.cpp#L4032).

## 남은 실제 실행 검사

DoGS 구현 후 JSON 로드·개 타입 적용, 첫 행동의 공격 비활성화와 fallback, 훈련·임무 상태 저장/복원, 방어구·면역별 효과, LURE의 분리·추격 해제·복귀, waypoint 이동, 쿨다운·moves 예산과 구체적인 타 모드 조합을 시험한다. 이는 실행 검증 과제이며 미완료된 소스 조사와 구별한다. 수치와 훈련/UI는 여전히 설계 결정 사항이다.

## ID 정의 확인 근거

materials.json의 flesh/iflesh, effects.json의 downed·bleed·grabbed·bite·infected·pacified, mutations/mutations.json의 TOXICFLESH를 확인했다. WARM은 몬스터 플래그 로더로 연결되며 mon_zombie JSON에 존재한다.

작업 원칙: [조사와 검증 지침](../../AGENT/research-rules.md).

## MVP 후속 검증

훅 선언·실제 호출 위치·공통 피해 함수의 관계는 [전투 호출 경로와 훅 조사](combat-hooks.md)에 별도로 기록했다. 특히 `on_creature_attacked_by_character`의 투사체 처리 경로를 확인했다.

현재 구현과 플레이 실험은 실행 파일 리비전 `ef0eced` 기준으로 [실험 기록](experiments.md)에 기록했다. 위 소스 조사 결과는 원래 고정 리비전 기준을 유지한다.

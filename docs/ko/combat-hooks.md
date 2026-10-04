# 전투 호출 경로와 Lua 훅 조사

[English](../en/combat-hooks.md)

2026-10-04 소스 조사. 기준 리비전은 `e0e25e9d8b3cf0d3b663882a7faf5a44d8ace800`이다. 설치 실행 파일은 `ef0eced`이므로 동일 바이너리의 실행 추적이라고 주장하지 않는다. 훅 선언뿐 아니라 실제 호출 위치와 공통 피호출 함수를 확인했다. 이 조사에서 전투 실험은 실행하지 않았다. 고정 리비전의 개별 근거 링크는 대응하는 영문 문서에 있다.

## melee_actor와 monster::melee_attack의 관계

서로를 호출하는 래퍼가 아니라 별도의 공격 경로다. JSON의 `attack_type=melee`는 `melee_actor`를 생성하며 `bite_actor`는 이를 상속한다. `monster::melee_attack(target)`은 정확도를 받는 자신의 overload로 넘긴다.

```text
melee_actor::call
  → find_target / actor 이동력 비용
  → target.deal_melee_attack: 명중·회피
  → 신체 부위 선택 → target.deal_damage
  → 양의 피해일 때 actor.on_damage → JSON effects
  → target.on_hit

monster::melee_attack
  → 일반 공격 비용 / 몬스터 플래그 / 일반 근접 피해
  → target.deal_melee_attack: 명중·회피
  → target.deal_melee_hit
       → block_hit / 탑승자 대상 전환
       → deal_damage → on_hit
  → check_dead_state
  → on_creature_melee_attacked
```

두 경로는 `deal_melee_attack`, `deal_damage`, `on_hit`을 공유한다. 그러나 **공유 함수에서 on_creature_melee_attacked를 호출하는 것은 아니다.** 이 훅은 일반 공격의 상위 함수에 있으므로 generic melee actor에 전파되지 않는다. DoGS의 두 JSON 공격은 이 actor 경로다.

현재 `melee_actor::find_target` 자체도 인접 대상을 요구한다(`src/mattack_actors.cpp:380`). 비인접 공격을 조사할 때 generic melee actor가 원거리 공격을 한다고 가정하면 안 된다.

`Creature::deal_damage`는 방어구·피해 계산 후 virtual `apply_damage`로 넘긴다. 이 함수와 `monster::apply_damage`에는 범용 Lua 피해 훅이 없다. `monster::on_hit`은 엔진의 방어·반격 처리를 하며 범용 Lua 공격자 이벤트가 아니다. 공격 비용·명중·피해·HIT_AND_RUN·막기와 탑승자 처리·추가 효과도 두 경로가 같지 않다.

주요 위치: `src/mattack_actors.cpp:394`, `src/monster.cpp:2451`, `src/creature.cpp:694`, `src/creature.cpp:715`, `src/creature.cpp:1267`, `src/monster.cpp:4420`, `src/monstergenerator.cpp:1409`.

## 훅의 실제 범위

| 훅 | 실제 경로와 정보 | 제약 |
| --- | --- | --- |
| on_creature_melee_attacked | 일반 몬스터·Character 근접공격. char는 공격자, target은 대상, success는 명중 판정 | generic melee actor는 호출하지 않는다. 양의 HP 피해를 뜻하지 않으며 일반 공격의 조기 반환도 제외된다 |
| on_creature_dodged | Creature·Character의 on_dodge. char는 회피자, source는 공격자 | generic actor의 회피도 관측 가능하다. 모든 공격 시도·피해를 포괄하지 않는다 |
| on_creature_attacked_by_character | Character 근접공격 및 source가 플레이어/NPC인 투사체 처리. 실제 target과 source, success | 투사체의 완전 빗나감·회피 조기 반환은 제외된다. 투사체 success=true도 양의 피해 보장이 아니다. source가 몬스터인 원시 투사체는 조건을 통과하지 않는다 |
| on_shoot | ranged::fire_gun의 발사 처리 후. shooter·조준 위치·발사 수·무기·탄약 | 실제 피격 대상·피해·명중 목록은 없다. 발사 수가 0일 수 있다 |
| on_throw | 투척 처리 후. thrower·조준 위치·투척 출발 위치·아이템 | 조준 위치는 실제 피격 대상이 아니다 |
| on_mon_effect_added / on_mon_effect | 몬스터 효과 처리. mon·effect | EFFECT_LUA_ON_ADDED / EFFECT_LUA_ON_TICK 플래그가 필요하다. 공격자를 전달하지 않는다 |
| on_mon_death | 몬스터 사망 처리. mon·killer | 매 피격 기록이 아니다. fake 공격자를 원래 몬스터라고 단정할 수 없다 |

`src/catalua_hooks.cpp`의 등록 목록과 바인딩 문서는 호출 위치와 구별한다. 효과 플래그 ID는 `data/json/flags.json`에서 확인했고, 실제 조건은 `monster::process_one_effect`에서 확인했다.

경계값에도 주의한다. `deal_melee_attack`은 hitspread가 0 이하일 때 회피 이벤트를 호출하지만 generic/일반 몬스터 공격은 0 이상을 명중으로 취급한다. 따라서 회피 훅 하나만으로 최종 빗나감·피해 여부를 확정하면 안 된다.

## 몬스터 총기와 다른 특수공격

gun actor는 몬스터 위치에 임시 `standard_npc`를 만들고 fake 표시 후 `ranged::fire_gun`을 호출한다. 투사체의 source도 이 임시 Character다. 따라서 **이 경로의 on_creature_attacked_by_character는 실제 피격 대상과 임시 공격자를 알려 줄 수 있다.** 콜백 안에서 source 위치의 원래 몬스터를 확인해 연결해야 하며 임시 NPC userdata를 콜백 이후까지 보관하면 안 된다. `on_shoot`는 별도로 총기 사용과 조준 위치를 알려 준다.

앞선 조사에서 `on_creature_attacked_by_character`의 투사체 호출을 빠뜨렸다. 몬스터 총기 피격을 추적하는 방법이 `on_shoot`와 HP 변화의 상관관계만 있는 것은 아니다.

추출한 Lua API에는 `is_npc`·`as_monster`가 있지만 `is_fake`는 없다. 위치 일치는 원래 공격자 후보를 연결하는 근거이지 proxy 신원을 독립적으로 증명하지 않는다. Lua 구현에서도 이 불확실성을 남겨야 한다.

다른 특수공격도 실제 경로별로 조사해야 한다. 예를 들어 grab 경로는 `z->melee_attack(*target)`을 호출하므로 일반 근접 훅으로 연결된다(`src/monattack.cpp:2998`). 반면 직접 `deal_damage` 또는 `projectile_attack`을 호출하는 특수공격도 있다. ‘특수공격’이나 ‘근접’이라는 분류만으로 훅 범위를 판단하면 안 된다. 몬스터 source의 원시 투사체는 Character source 조건을 통과하지 않는다. 주문·효과·환경 피해도 각각의 호출 경로가 필요하다.

## DoGS에 적용할 결론

1. 일반 근접 훅을 유지하되 명중 판정과 실제 HP 감소를 구별한다.
2. Character·투사체의 실제 대상 훅을 먼저 활용하고 fake 총기 사수를 즉시 원래 몬스터와 연결한다.
3. on_shoot·on_throw는 공격 시도 맥락으로 사용하며 피격 증거로 단정하지 않는다.
4. generic actor 회피 훅을 필요한 범위에서 활용한다. DoGS 자신의 특수공격은 명시적 호출·결과 로그가 이미 있다.
5. 직접 피해·몬스터 source 투사체 등 남은 경로는 불확실성을 기록하고 임의의 주변 적에게 피해를 귀속하지 않는다.

2~4번은 후속 구현 사항이다. 이번 조사는 문서와 조사 원칙을 갱신하며 게임 콜백 구현을 변경하지 않는다.

# Lua API와 이동 구현

아래 기능과 제약은 원문 대화에서 보고된 내용이며, 대상 BN 버전에서 재확인해야 한다.

## 대화에서 활용 가능하다고 보고된 기능

| 영역 | 기능 |
|---|---|
| Creature 정보 | 위치, 시야, effect, HP, 속도 |
| 이동·타겟 | `set_move_target`, `set_target`, `clear_move_target`, `move_to` |
| 일반 AI fallback | `run_normal_ai_turn` |
| 특수공격 | 조회, enable / disable, cooldown, use |
| 개체별 상태 | `set_value`, `get_value` |
| 주변 인식 | 맵 타일 스캔과 creature lookup |

실제 노출 타입, 인자, 반환값과 턴·행동 비용 처리를 확인한다.

## 보고된 제약

- 편리한 `get_visible_enemies()` 같은 API는 확인되지 않았다. 주변 타일을 스캔해 적을 찾는 방식을 고려한다.
- 몬스터가 현재 누구를 추적하는지 알려주는 정확한 getter는 확인되지 않았다.
- 여러 턴 동안 추격 대상을 안정적으로 식별하기 어려우면 최소한의 Lua binding 추가를 검토한다.

## 이동과 경로 탐색

복잡한 우회 경로를 Lua에서 직접 pathfinding하는 방향은 피한다. 기존 monster movement / pathfinding을 가능한 한 활용하고, Lua는 목표와 waypoint를 결정한다.

특히 LURE 복귀는 추격 해제와 우회가 필요하다. 기존 이동 기능만으로 안전하게 구현할 수 있는지는 실제 동작을 보고 판단한다.

실제 플레이에서 부족한 기능을 확인한 후 필요한 binding만 최소 추가한다.

관련: [03 위험 평가와 위치 선정](risk-and-positioning.md), [04 LURE 유인 임무](lure.md), [07 기존 개 적용과 훈련 상태](training-and-integration.md)

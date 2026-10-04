# Lua API와 이동 구현

## 확인된 API

Creature의 위치·시야·태도·효과/면역·HP·속도·moves와 문자열 개체별 값을 사용할 수 있다. 이동 API는 set_move_target(pos), set_target(creature), clear_move_target(), move_target(), run_normal_ai_turn(), move_to(pos, force, step_on_critter, stagger_adjustment)다. move_to는 bool을 반환하고 실제 한 걸음 이동 비용을 처리한다.

공격 API는 has_special_attack, get_special_attack_ids, special_attack_ready, use_special_attack, special_attack_enabled, set_special_attack_enabled, get/set_special_attack_cooldown이다. ready는 사거리·명중 보장이 아니며 use의 true는 시도를 처리했다는 뜻이다. 면역·진정 상태·행동 비용을 DoGS에서 준수해야 한다.

## 주변 인식

gapi.get_all_monsters(), get_all_creatures(), get_monsters_if(filters) 또는 타일 조회를 사용할 수 있다. 필터는 sees, hostile_to, within_range_of를 지원하지만 활성 몬스터를 순회한다. local scan과 비용을 비교한다. sees={dog}는 개가 후보를 보는 판정이며 LURE에는 적이 개를 보는 판정도 필요하다.

## 추격과 이동 제약

set_target은 위치를 복사하며 개체 ID를 유지하지 않는다. move_target은 목적지이지 추격의 증명이 아니다. attack_target 바인딩은 발견하지 못했다. 여러 행동과 저장/복원 사이에 대상을 재확인한다.

waypoint 설정만으로 이동하지 않는다. 위치·moves 변화 없이 true를 반환하면 대기 비용을 차감한다. run_normal_ai_turn은 재계획해 목적지를 바꿀 수 있다. 기존 이동을 활용하되 LURE 전에 waypoint 실행 방식을 검증한다. 직접 Lua 이동도 이동 방해 효과를 준수해야 한다.

## callback 계약

false/nil은 일반 AI를 실행하고 true는 행동 처리를 의미한다. 미훈련 개는 DoGS 공격을 끈 뒤 false를 반환한다. run_normal_ai_turn을 직접 실행한 경우 일반 행동이 두 번 실행되지 않게 true를 반환한다.

실제 플레이에서 이 기능으로 부족함을 확인한 경우에만 최소 binding 추가를 검토한다.

근거와 남은 실행 검사는 [BN 소스 검사 결과](source-verification.md)를 참조한다.

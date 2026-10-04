# 구현 순서와 확인 과제

## 현재 상태

설계 단계이며 구현은 검증되지 않았다. 기술 사항은 대상 BN 버전에서 확인한다.

## 구현 우선순위

1. vanilla dog type override와 lua_ai 연결
2. 개체별 DoGS 훈련 여부 처리
3. 주변 적 탐색과 위험 평가
4. NORMAL의 ASSIST / INTERCEPT / SKIRMISH / RETREAT / REGROUP
5. custom Takedown
6. Ankle Tear와 전용 leg wound effect
7. LURE multi-turn mission
8. 실제 플레이에서 필요한 Lua binding만 최소 추가

## 구현 전 확인할 사항

- 대상 BN 버전에서 same-ID override, lua_ai, extend.special_attacks가 지원되는지
- 특수공격 enable 상태와 개체별 값의 저장·불러오기 동작
- 미훈련 개의 fallback과 DoGS 공격 비활성화 시점
- Lua의 이동·타겟·공격 함수 서명과 턴 처리
- 추격 대상 식별 가능 여부
- melee effects의 피해 조건, downed·bleed·SPEED modifier의 몬스터 적용
- 다른 모드의 개 override와 함께 쓰는 경우의 동작

## 아직 정하지 않은 설계

훈련 방식과 UI, 적용할 개 타입 목록, 위험 점수·전환 임계치, 공격 수치·저항 판정·쿨다운, leg wound의 ID·중첩 정책, LURE의 세부 단계와 추격 해제 조건은 미정이다.

## 플레이 검증의 핵심

개가 무리 중심으로 들어가지 않는지, 포위 전에 빠지는지, 플레이어를 보조하고 안전하게 복귀하는지 확인한다. LURE는 외곽 적을 실제로 분리하고 추격을 해제한 뒤 복귀해야 한다. 공격은 피해량보다 제압과 이동 방해의 플레이 가치로 평가한다.

관련: [00 DoGS 목차](index.md)

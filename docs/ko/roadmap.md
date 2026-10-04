# 구현 순서와 확인 과제

## 현재 상태

모듈별 실험용 MVP를 구현했다. redhot 2026-10-04에서 데이터·스크립트 로딩과 Lua fixture 검사는 통과했다. 실제 플레이 검사는 남아 있다. [MVP 범위와 검사](mvp.md)를 참조한다.

## 구현 우선순위

1. vanilla dog type override와 lua_ai 연결
2. 개체별 DoGS 훈련 여부 처리
3. 주변 적 탐색과 위험 평가
4. NORMAL의 ASSIST / INTERCEPT / SKIRMISH / RETREAT / REGROUP
5. custom Takedown
6. Ankle Tear와 전용 leg wound effect
7. LURE multi-turn mission
8. 실제 플레이에서 필요한 Lua binding만 최소 추가

## 검사 상태

소스로 확인할 항목은 모두 조사했다. [검사 결과](source-verification.md)에 적용·저장·callback·공격·효과의 근거와 추격 식별·waypoint 이동의 제약을 기록했다. 다른 모드의 같은 정의 덮어쓰기로 호환성은 조건부다.

실행 검사는 남아 있다: 미훈련 fallback과 첫 행동 비활성화, 임무 저장/복원, 방어구·면역별 효과, waypoint 이동, LURE와 구체적 타 모드 조합. MVP에 진단 도구와 로그 이벤트를 마련했으며 실제 플레이 검사는 아직 수행하지 않았다.

## 아직 정하지 않은 설계

훈련 방식과 UI, 적용할 개 타입 목록, 위험 점수·전환 임계치, 공격 수치·저항 판정·쿨다운, leg wound의 ID·중첩 정책, LURE의 세부 단계와 추격 해제 조건은 미정이다.

## 플레이 검증의 핵심

개가 무리 중심으로 들어가지 않는지, 포위 전에 빠지는지, 플레이어를 보조하고 안전하게 복귀하는지 확인한다. LURE는 외곽 적을 실제로 분리하고 추격을 해제한 뒤 복귀해야 한다. 공격은 피해량보다 제압과 이동 방해의 플레이 가치로 평가한다.

관련: [00 DoGS 목차](index.md)

근거와 남은 실행 검사는 [BN 소스 검사 결과](source-verification.md)를 참조한다.

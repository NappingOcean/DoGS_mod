# DoGS — Dogs of Good Sense

Cataclysm: Bright Nights에서 개의 판단력과 전술 행동을 개선하는 모드의 설계 문서다.

## 주제별 문서

- [01 목표와 설계 철학](philosophy.md) — 역할, 세계관, 범위
- [02 AI 계층과 기본 전술](ai-architecture.md) — 임무·전술·원자 행동
- [03 위험 평가와 위치 선정](risk-and-positioning.md) — 생존 우선 판단과 성능
- [04 LURE 유인 임무](lure.md) — 시각 유인, 추격 해제, 안전 복귀
- [05 Takedown 제압 공격](takedown.md) — 넘어뜨리기와 공격 actor 선택
- [06 Ankle Tear와 이동 저하](ankle-tear.md) — 물리적 상처, 출혈, 전용 효과
- [07 기존 개 적용과 훈련 상태](training-and-integration.md) — 타입 override와 개체별 상태
- [08 Lua API와 이동 구현](lua-and-movement.md) — 대화에서 보고된 기능과 제약
- [09 구현 순서와 확인 과제](roadmap.md) — 구현 우선순위와 미결 사항

## 문서의 기준

출처는 「사냥개 AI 설계」 대화의 최종 설계 요약이다. 설계 결정과 미확인 기술 사항을 구분한다. 구현은 아직 검증하지 않았으며, API·JSON·효과 동작은 대상 BN 버전에서 확인한다.

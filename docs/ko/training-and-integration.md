# 기존 개 적용과 훈련 상태

## 구현 방향

기존 vanilla dog type을 **same-ID self copy-from**으로 override하고 동일한 `lua_ai` callback을 부여하는 방향을 선호한다. 별도 smart dog monster type으로 변환하는 방식은 우선하지 않는다.

필요한 특수공격은 `extend.special_attacks`로 추가한다. 훈련 여부와 AI 상태는 개체별 값으로 관리한다.

## callback의 책임

- 훈련되지 않은 개: DoGS 전용 공격을 비활성화하고 일반 AI로 fallback한다.
- 훈련된 개: DoGS AI를 실행한다.
- 모드가 추가한 attack ID만 enable / disable한다.
- vanilla와 다른 모드의 special attack은 건드리지 않는다.

## 대화에서 보고된 기술 사항 — 재확인 필요

- `lua_ai`는 JSON 타입 수준의 설정이며 개체별 runtime value만으로 callback 자체를 부여할 수 없다.
- special attack의 enabled 상태는 개체별이며 save / load된다.
- 공격 JSON의 초기 `enabled=false` 필드는 확인되지 않았다.

callback에서 DoGS 공격의 활성 상태를 관리하고, 미훈련 개와 저장·불러오기 동작을 확인한다.

관련: [08 Lua API와 이동 구현](lua-and-movement.md), [09 구현 순서와 확인 과제](roadmap.md)

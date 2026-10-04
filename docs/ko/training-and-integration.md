# 기존 개 적용과 훈련 상태

## 구현 방향

기존 vanilla dog type을 **same-ID self copy-from**으로 override하고 동일한 `lua_ai` callback을 부여하는 방향을 선호한다. 별도 smart dog monster type으로 변환하는 방식은 우선하지 않는다.

필요한 특수공격은 `extend.special_attacks`로 추가한다. 훈련 여부와 AI 상태는 개체별 값으로 관리한다.

## callback의 책임

- 훈련되지 않은 개: DoGS 전용 공격을 비활성화하고 일반 AI로 fallback한다.
- 훈련된 개: DoGS AI를 실행한다.
- 모드가 추가한 attack ID만 enable / disable한다.
- vanilla와 다른 모드의 special attack은 건드리지 않는다.

## 확인된 적용 제약

lua_ai는 타입 수준 설정이다. 개체별 값은 문자열이며 저장/복원된다. 공격은 기본 활성 상태와 무작위 초기 쿨다운을 갖고, actor 로더에는 초기 enabled 필드가 없다. 활성 상태와 쿨다운은 저장된다.

callback에서 DoGS ID만 끄고 미훈련 개는 false로 fallback한다. 일반 AI를 직접 실행했으면 이후 true를 반환한다. 타 모드가 lua_ai나 공격 정의·목록을 교체할 수 있으므로 구체적인 조합과 순서를 실행 검사해야 한다.

관련: [08 Lua API와 이동 구현](lua-and-movement.md), [09 구현 순서와 확인 과제](roadmap.md)

근거와 남은 실행 검사는 [BN 소스 검사 결과](source-verification.md)를 참조한다.

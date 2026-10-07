# DoGS 문서

[English](../en/index.md)

**DoGS — Dogs of Good Sense**는 Cataclysm: Bright Nights(BN)의 개를 상황을 판단하는 전술 동료로 만드는 모드다. 개를 더 강하게 만들지 않고, 위치·위험·개입 시점에 대한 판단을 더한다.

## 현재 상태 (2026-10-07)

- 구현: [`DoGS_mod/`](../../DoGS_mod/). 대상은 Labrador mutt(`mon_dog`) 한 종류다. BN의 기본 펫 AI 위에 얹는 판단층으로 동작한다.
- 동작: 안전 veto(포위 회피, 저체력이면 플레이어 뒤로 후퇴), Takedown·Ankle Tear 제압 공격, 역할(엄호가 기본, 자유·견제 선택 가능. 견제는 v0). 훈련과 역할은 action_menu에서 개체별로 정한다.
- 검증: 실험 E0~E7 완료. Takedown의 새 판정(Lua 적용, 크기 저항)은 E7에서 대체로 확인했다(빗나감 감지는 미확인). 견제 v0는 아직 플레이로 확인하지 않았다(E8 재실험 예정).
- 다음 단계: [로드맵](roadmap.md).

## 새 세션에서 읽는 순서

1. 이 문서
2. [설계 철학](philosophy.md): 사용자가 정한 원칙. 모든 결정의 기준이다.
3. [행동 설계](design.md): 지금 개가 어떻게 판단하는가
4. [로드맵](roadmap.md): 무엇이 끝났고 무엇이 다음인가
5. 작업 주제에 따라: [제압 공격](attacks.md), [엔진 사실](engine-notes.md), [개발 안내](development.md), [실험 기록](experiments.md), [견제 역할](harass.md)
6. 조사·구현 규칙: [AGENT/research-rules.md](../../AGENT/research-rules.md)

## 문서 지도

| 문서 | 내용 |
| --- | --- |
| [philosophy.md](philosophy.md) | 목표, 설계 원칙, 훈련된 개다운 행동 |
| [design.md](design.md) | 판단 순서, 상태와 전환, 안전 veto, 역할, 계획된 행동, 알려진 한계 |
| [attacks.md](attacks.md) | Takedown과 Ankle Tear의 의도·수치·판정 |
| [harass.md](harass.md) | 견제 역할: 다음 적의 도착 늦추기(v0 구현, 플레이 미확인). 엄호와의 차이, 미결 사항, 보류한 안 |
| [engine-notes.md](engine-notes.md) | 구현이 기대는 BN 동작. 소스 위치와 실행 확인 여부 |
| [development.md](development.md) | 코드 구조, 코드 규칙, 개체 값, 설정값, 로그, 설치·검사, 실험 절차 |
| [experiments.md](experiments.md) | 실험 목록, 절차, 결과 |
| [roadmap.md](roadmap.md) | 현재 상태, 다음 단계, 미결 질문, 결정 기록 |
| [source-verification.md](source-verification.md), [combat-hooks.md](combat-hooks.md) | Codex의 이전 소스 감사(리비전 `e0e25e9`). 역사 기록으로 보존한다 |

## 표기 규칙

AGENTS.md에 따라 근거의 종류를 구분해 적는다.

- **[설계]** 사용자와 정한 결정이다. 실험 결과로 바뀔 수 있다.
- **[소스]** BN 소스로 확인한 동작이다. 기준 리비전은 아래에 있다.
- **[실행 E#]** 플레이 로그로 확인한 동작이다. 실험 번호는 [실험 기록](experiments.md)을 가리킨다.
- **미확인** 아직 소스나 플레이로 확인하지 않은 것이다.

## 기준

- 게임: redhot 빌드 `2026-10-07-0423`, BN 커밋 `31a958998ac2bb53aca592e06eb4010d9dc1746a`(AGENTS.md의 기준 리비전).
- `8e8aa90`(redhot `2026-10-05-2327`)에서 기록한 소스 확인은 그 커밋에 고정된 링크를 유지한다. `31a9589`까지 `src` 변경이 없어 내용은 그대로 맞다.
- 앞서 기록한 소스 확인은 `ef0eced`(redhot `2026-10-04-0345`) 기준이며, 그 링크는 해당 커밋에 고정된 채 유지한다.
- 이전 감사 문서는 당시 리비전 `e0e25e9`를 유지한다.

## 문서 이력

2026-10-05 Claude Code가 문서 전체를 개정했다. Codex가 작성했던 설계 문서(ai-architecture, risk-and-positioning, takedown, ankle-tear, training-and-integration, lua-and-movement, mvp)와 `docs/claude/experiment-plan`은 이 문서들로 통합되었다. 이전 내용은 커밋 `ebd2650`까지의 git 기록에 남아 있다.

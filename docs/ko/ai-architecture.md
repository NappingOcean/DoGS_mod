# AI 계층과 기본 전술

AI는 임무, 전술 행동, 원자 행동의 3계층으로 나눈다. 여러 턴에 걸친 목표와 현재 턴의 행동을 구분한다.

## Mission layer

| 임무 | 의미 |
|---|---|
| NORMAL | 일반적인 전술 지원 |
| LURE | 외곽 적의 시각 유인과 분리 |

## Tactical action layer

NORMAL에서는 상황에 따라 다음 행동을 선택한다.

| 행동 | 목적 |
|---|---|
| ASSIST | 플레이어가 상대 중인 적을 보조한다. |
| INTERCEPT | 플레이어에게 접근하는 적을 끊어낸다. |
| SKIRMISH | 무리 외곽의 노출된 적을 공격하고 이탈한다. |
| RETREAT | 위험한 상황에서 후퇴한다. |
| REGROUP | 플레이어 근처로 복귀한다. |

## Atomic action layer

MOVE, Takedown, Ankle Tear, 일반 이동·후퇴와 필요한 짧은 공격 행동을 실제 실행한다. 전술 행동을 공격 하나와 동일시하지 않는다. 예를 들어 SKIRMISH는 진입과 공격, 이탈을 포함하는 전술 판단이다.

## 선택 구조

위험한 선택을 먼저 차단하는 **hard safety veto**, 단순한 행동 점수, 잦은 행동 전환을 줄이는 **hysteresis**의 조합을 선호한다. utility score를 무한정 복잡하게 만들지 않는다.

관련: [03 위험 평가와 위치 선정](risk-and-positioning.md), [04 LURE 유인 임무](lure.md)

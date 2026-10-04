# Ankle Tear와 이동 저하

## 설계 의도

발목이나 종아리를 물고 찢어 이동 능력을 낮춘다. 감염용 bite 대신 물리적 상처를 유발하는 공격으로 설계한다.

## 검토 중인 구성

- generic melee actor
- cut damage
- bleed effect
- 전용 leg wound / mobility penalty effect

## 효과의 의미

상처로 인한 이동 저하를 나타내는 전용 효과를 사용한다. 다른 의미의 감속 효과를 재사용하지 않는다.

짧은 지속시간과 `speed_mod` 감소, 필요 시 중첩 제한을 고려한다.

## 확인된 효과

speed_mod는 SPEED로 로드되어 몬스터 speed bonus에 적용된다. 출혈 피해·혈흔 처리가 있지만 면역 조건은 WARM과 flesh를 요구한다. JSON의 iflesh는 곤충의 살이며 mon_zombie는 flesh와 WARM을 가져 면역이 아니다. 변종은 개별 정의를 확인한다. 전용 감속과 출혈의 후보 구성을 유지한다. generic melee는 두 효과 모두 실제 피해가 양수일 때 적용한다.

## Takedown과 역할 분담

| 공격 | 전술적 역할 |
|---|---|
| Takedown | 즉시 넘어뜨리는 짧은 제압 |
| Ankle Tear | 추격·복귀·이탈을 방해하는 지속적 이동 저하 |

관련: [05 Takedown 제압 공격](takedown.md), [01 목표와 설계 철학](philosophy.md)

근거와 남은 실행 검사는 [BN 소스 검사 결과](source-verification.md)를 참조한다.

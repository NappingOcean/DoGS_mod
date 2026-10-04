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

## 대화에서 보고된 기술 사항 — 재확인 필요

몬스터에도 SPEED modifier가 적용되고, bleed가 주기적으로 피해를 주며 혈흔을 남긴다고 설명됐다. 실제 BN 버전에서 확인한다.

## Takedown과 역할 분담

| 공격 | 전술적 역할 |
|---|---|
| Takedown | 즉시 넘어뜨리는 짧은 제압 |
| Ankle Tear | 추격·복귀·이탈을 방해하는 지속적 이동 저하 |

관련: [05 Takedown 제압 공격](takedown.md), [01 목표와 설계 철학](philosophy.md)

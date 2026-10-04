# Takedown 제압 공격

## 설계 의도

피해보다 **downed를 통한 즉시 제압**이 목적이다. 발목 사이로 파고들거나 몸통을 들이받아 균형을 무너뜨리는 행동으로 설명한다.

공격이 성공하면 신뢰성 있게 자세를 무너뜨리는 것을 목표로 한다. 모든 적을 무조건 넘어뜨린다는 뜻은 아니다. 큰 적이나 안정성이 높은 적의 성공 조건·저항 판정은 검토 대상이다.

## actor 선택 방향

기존 hardcoded **LUNGE는 사용하지 않는다.** 별도 custom attack을 만드는 방향이다. 사역견 공격에는 generic melee actor 또는 필요한 custom actor를 사용한다.

기존 generic bite actor는 가급적 피한다. 감염 관련 로직이 DoGS의 물리적 제압 목적과 맞지 않기 때문이다.

## 대화에서 보고된 기술 사항 — 재확인 필요

- 기존 LUNGE의 확률적 downed와 거리 처리는 신뢰성 있는 제압 목적에 맞지 않는다고 보고됐다.
- generic melee actor는 실제 피해가 1 이상 들어가야 effects를 적용한다고 보고됐다. 따라서 0 damage + downed가 그대로 구현되지 않을 수 있다.
- downed 몬스터는 이동 전에 일어나기 위해 행동을 소모하고, 강한 몬스터는 더 잘 일어나며, downed 상태에서 dodge가 0이 된다고 보고됐다.

## 남은 결정

custom actor 또는 generic melee actor 확장이 필요한지 조사한다. 성공·저항 기준, 피해량, 지속시간, 쿨다운은 미정이다.

관련: [06 Ankle Tear와 이동 저하](ankle-tear.md), [09 구현 순서와 확인 과제](roadmap.md)

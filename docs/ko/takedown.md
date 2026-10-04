# Takedown 제압 공격

## 설계 의도

피해보다 **downed를 통한 즉시 제압**이 목적이다. 발목 사이로 파고들거나 몸통을 들이받아 균형을 무너뜨리는 행동으로 설명한다.

공격이 성공하면 신뢰성 있게 자세를 무너뜨리는 것을 목표로 한다. 모든 적을 무조건 넘어뜨린다는 뜻은 아니다. 큰 적이나 안정성이 높은 적의 성공 조건·저항 판정은 검토 대상이다.

## actor 선택 방향

기존 hardcoded **LUNGE는 사용하지 않는다.** 별도 custom attack을 만드는 방향이다. 사역견 공격에는 generic melee actor 또는 필요한 custom actor를 사용한다.

기존 generic bite actor는 가급적 피한다. 감염 관련 로직이 DoGS의 물리적 제압 목적과 맞지 않기 때문이다.

## 확인된 기술 사항

- generic melee는 실제 피해가 양수일 때만 effects를 적용한다. 효과 확률 100이어도 방어구가 피해를 모두 막으면 효과가 없으므로 무피해 downed는 별도 적용 경로가 필요하다.
- LUNGE는 확률적 downed를 사용하며 떨어진 거리에서는 직접 이동 대신 moves를 더할 수 있어 신뢰성 있는 제압 목적에 맞지 않는다.
- downed 몬스터의 dodge는 0이며 일반 AI의 기립 시도는 남은 moves를 종료한다. 회복은 melee dice/sides에 좌우된다.
- bite_actor에는 grabbed 상처 감염과 toxic flesh에 의한 공격자 중독 로직이 있다.

## 남은 결정

custom actor 또는 generic melee actor 확장이 필요한지 조사한다. 성공·저항 기준, 피해량, 지속시간, 쿨다운은 미정이다.

관련: [06 Ankle Tear와 이동 저하](ankle-tear.md), [09 구현 순서와 확인 과제](roadmap.md)

근거와 남은 실행 검사는 [BN 소스 검사 결과](source-verification.md)를 참조한다.

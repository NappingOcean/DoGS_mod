# DoGS — Dogs of Good Sense

[English](README.md)

**Cataclysm: Bright Nights**용 실험적인 개 AI 모드입니다. 위치 선정, 위험 판단, 적 분리와 이탈 시점을 개선해 훈련된 개를 전술 동료로 만듭니다.

## 계획한 행동

- 플레이어 보조, 접근하는 적 차단, 무리 외곽 교전, 후퇴와 재집결
- **Takedown**을 통한 즉시 제압과 **Ankle Tear**를 통한 이동 방해
- 외곽 적의 시각 유인, 추격 해제 후 안전한 복귀
- 개체별 훈련 여부에 따른 DoGS AI 적용과 미훈련 개의 일반 AI 유지

**현재 상태:** redhot BN(Lua API 2)용 모듈별 실험용 MVP입니다. 성견 한 종류, 임시 NORMAL 전술, 제압 공격, action_menu 진단과 자동 로그를 제공합니다. 2026-10-04 빌드에서 데이터 로딩과 Lua fixture 검사를 통과했습니다. 실제 전투·저장 복원 검사는 남아 있으며 LURE와 정식 훈련은 후속 작업입니다.

구조·구현 제약·개발 순서는 [한국어 설계 문서](docs/ko/index.md)와 [English documentation](docs/en/index.md)를 참조하세요.

설치·검사: [MVP 실험실](docs/ko/mvp.md).

지속 전투 실험을 위해 현재 실험용 빌드는 mon_dog의 기본 최대 HP를 3,000으로 설정합니다. 정식 밸런스가 아닌 임시 시험 설정입니다.

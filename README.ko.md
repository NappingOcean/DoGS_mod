# DoGS — Dogs of Good Sense

[English](README.md)

**Cataclysm: Bright Nights**용 실험적인 개 AI 모드입니다. 위치 선정, 위험 판단, 적 분리와 이탈 시점을 개선해 훈련된 개를 전술 동료로 만듭니다.

## 계획한 행동

- 플레이어 보조, 접근하는 적 차단, 무리 외곽 교전, 후퇴와 재집결
- **Takedown**을 통한 즉시 제압과 **Ankle Tear**를 통한 이동 방해
- 외곽 적의 시각 유인, 추격 해제 후 안전한 복귀
- 개체별 훈련 여부에 따른 DoGS AI 적용과 미훈련 개의 일반 AI 유지

**현재 상태:** redhot BN(Lua API 2)용 실험 빌드이며 [`DoGS_mod/`](DoGS_mod/)에 있습니다. Labrador mutt의 기본 펫 AI 위에 얹는 판단층입니다. 안전 veto(플레이어 뒤로 물러나는 저체력 후퇴 포함), Takedown·Ankle Tear 제압 공격, 복귀 거리 제한, 엄호 역할(기본값)에서만 개입하고 나머지는 엔진에 맡깁니다. 훈련과 역할은 action_menu에서 개체별로 정합니다. 실험 E0~E6을 기록했으며 LURE, 견제 역할, 정식 훈련은 후속 작업입니다.

설치·검사·실험 결과: [실험 계획서](docs/claude/experiment-plan.ko.md).

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
.\scripts\Test-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
```

구조·구현 제약·개발 순서는 [한국어 설계 문서](docs/ko/index.md)와 [English documentation](docs/en/index.md)를 참조하세요.

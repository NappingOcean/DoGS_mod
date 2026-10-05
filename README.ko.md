# DoGS — Dogs of Good Sense

[English](README.md)

**Cataclysm: Bright Nights**용 실험적인 개 AI 모드입니다. DoGS는 개를 더 강하게 만들지 않습니다. 훈련된 개에게 위치, 위험, 개입 시점에 대한 판단을 더해 전술 동료로 만듭니다.

## 하는 일

- Labrador mutt의 기본 펫 AI 위에 얹는 판단층으로 동작합니다. 미훈련 개는 일반 AI를 그대로 씁니다.
- **역할**을 개마다 정합니다. **엄호**(기본)는 플레이어 3타일 안을 지키며 다가오는 적을 상대합니다. **자유**는 일반 펫처럼 싸우면서 제압 공격을 섞습니다.
- **Takedown**으로 적을 넘어뜨려 플레이어와 개가 쉽게 치게 하고, **Ankle Tear**로 다리에 상처를 내 느리게 만듭니다.
- **안전 veto:** 포위를 피하고, 저체력이면 계속 싸우지 않고 플레이어 뒤로 물러납니다.

계획: 사선 회피, 견제 역할(무리의 최외곽 적부터 유인해 낙오시키기).

**현재 상태:** redhot BN(Lua API 2)용 실험 빌드이며 [`DoGS_mod/`](DoGS_mod/)에 있습니다. 실험 E0~E6을 기록했습니다.

## 설치

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
.\scripts\Test-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
```

시험 월드에서 **DoGS — Dogs of Good Sense (rebuild)**를 켜고, Labrador mutt를 길들인 뒤 action_menu → 기타 → **DoGS laboratory**에서 훈련과 역할을 정합니다.

## 문서

[문서 목차](docs/ko/index.md)([English](docs/en/index.md))부터 읽으세요. 설계 철학, 행동 설계, 로드맵, 개발 안내, 실험 결과가 있습니다.

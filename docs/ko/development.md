# 개발 안내

[English](../en/development.md) · [목차](index.md)

코드를 고치거나 실험을 진행할 때 필요한 정보를 모은다. 경로는 저장소 루트 기준이다.

## 저장소 구조

| 경로 | 내용 |
| --- | --- |
| [`DoGS_mod/`](../../DoGS_mod/) | 모드 본체(모드 ID `DoGS`). 게임의 `mods/DoGS`가 이 폴더를 가리킨다 |
| [`docs/`](../) | 문서(영어 `en`, 한국어 `ko`). 두 언어를 같이 고친다 |
| [`scripts/`](../../scripts/) | 설치·검사 스크립트 |
| [`AGENTS.md`](../../AGENTS.md), [`AGENT/research-rules.md`](../../AGENT/research-rules.md) | 에이전트 작업 규칙, 커밋 표기 |

## 설치와 검사

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
.\scripts\Test-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
```

- `Install-Mod.ps1`은 게임의 `mods/DoGS`를 `DoGS_mod/`에 정션으로 연결한다. 예전 `mod/`를 가리키는 정션만 교체하고, 다른 대상이 있으면 멈춘다.
- `Test-Mod.ps1`은 임시 사용자 디렉터리에서 `--check-mods DoGS`를 실행한다. 출력에 `Error`가 있거나 로딩 표식(`selftest scope=policy result=pass`, `load build=claude-rebuild`, `finalize result=pass`)이 없으면 실패한다. BN은 Lua 로딩 오류가 나도 종료 코드 0으로 끝날 수 있다.
- 통과는 데이터 로딩, ID 검사, 순수 정책 함수 검사가 통과했다는 뜻이다. 플레이 검증이 아니다.
- 코드를 바꾼 뒤에는 게임에서 월드를 다시 불러와야 적용된다.

## 모듈

| 파일 | 역할 |
| --- | --- |
| [`preload.lua`](../../DoGS_mod/preload.lua) | 모듈 로딩, AI 콜백·훅·메뉴·주기 기록 등록, 정책 검사 실행 |
| [`finalize.lua`](../../DoGS_mod/finalize.lua) | 개 타입과 효과 ID 유효성 검사 |
| [`json/dogs.json`](../../DoGS_mod/json/dogs.json) | `mon_dog` 덮어쓰기: `lua_ai`, 공격 두 개. HP는 바닐라 그대로 |
| [`json/effects.json`](../../DoGS_mod/json/effects.json) | `dogs_ankle_wound` 효과 |
| [`dogs/ai.lua`](../../DoGS_mod/dogs/ai.lua) | 판단 순서([행동 설계](design.md) 2절), 엄호, 복귀 위임 |
| [`dogs/policy.lua`](../../DoGS_mod/dogs/policy.lua) | 순수 함수: 상태 전환, 제압 조건, 공격 선택, Takedown 확률, 엄호 표적, 이동 후보 순위 |
| [`dogs/perception.lua`](../../DoGS_mod/dogs/perception.lua) | 적 탐색과 관측값 |
| [`dogs/movement.lua`](../../DoGS_mod/dogs/movement.lua) | 한 칸 이동: retreat, flee, disengage, regroup, intercept |
| [`dogs/attacks.lua`](../../DoGS_mod/dogs/attacks.lua) | 공격 선택·실행, 개체 값 쿨다운, Takedown 판정, 회피 훅 |
| [`dogs/role.lua`](../../DoGS_mod/dogs/role.lua) | 역할 읽기·전환. 값이 없으면 엄호 |
| [`dogs/events.lua`](../../DoGS_mod/dogs/events.lua) | 10턴 요약, 근접공격 기록(개·플레이어), 사망 기록 |
| [`dogs/menu.lua`](../../DoGS_mod/dogs/menu.lua) | action_menu |
| [`dogs/log.lua`](../../DoGS_mod/dogs/log.lua) | 로그 줄 작성, 개체 번호 |
| [`dogs/config.lua`](../../DoGS_mod/dogs/config.lua) | 모든 수치. 바꾼 이유가 된 실험을 주석으로 단다 |
| [`dogs/tests.lua`](../../DoGS_mod/dogs/tests.lua) | 로딩 중 정책 함수 검사. 엔진 동작의 증거가 아니다 |

## 코드 규칙

- 모듈은 `dogs.` 접두사로 로딩 중에만 `require`한다. 게임 콜백 안에서 `require`하지 않는다. `lib.`은 BN 공용 라이브러리용이다([엔진 사실](engine-notes.md)).
- 판단 규칙은 엔진 객체 없이 검사할 수 있도록 `policy.lua`의 순수 함수로 둔다. 바꾸면 `tests.lua`에 검사를 추가하고, 기대값은 손으로 다시 계산한다.
- 엔진에 넘기기(false 반환) 전에는 반드시 DoGS 공격을 비활성화한다.
- 턴을 넘어 저장하는 위치는 절대 좌표를 쓴다.
- 새 효과·몬스터 ID는 `finalize.lua`에서 유효성을 검사한다.
- 로그는 `log.write`로 남긴다. 매 턴 상태를 덤프하지 않고 판단 이벤트만 남긴다.

## 개체 값

모두 문자열이며 저장·복원된다. 없으면 빈 문자열이다.

| 키 | 뜻 |
| --- | --- |
| `dogs_id` | 로그용 개체 번호. 개와, 기록에 등장한 몬스터에 붙는다 |
| `dogs_trained` | `"1"`이면 DoGS 훈련 |
| `dogs_role` | `"free"`면 자유, 그 밖에는 엄호 |
| `dogs_attack_mode` | `auto`(빈 값 포함), `takedown`, `ankle` |
| `dogs_messages` | `"0"`이면 상태 메시지 끔. 기본은 켜짐 |
| `dogs_state`, `dogs_state_turn` | 현재 상태와 진입한 게임 턴 |
| `dogs_threat_turn` | 적을 인식한 마지막 게임 턴(존재 영속성) |
| `dogs_holding` | 저체력 후퇴 중 대기 기록을 한 번만 남기기 위한 표식 |
| `dogs_disengage` | 제압 공격 뒤 후속 단계 표식 |
| `dogs_next_<공격 ID>` | 다음 사용 가능 게임 턴 |
| `dogs_delegate_block` | 이 게임 턴까지 복귀를 엔진에 맡기지 않음 |
| `dogs_probe_dest`, `dogs_probe_player` | 엔진에 맡긴 복귀 목적지(절대 좌표)와 그때의 플레이어 거리 |

모드 저장소(`game.mod_storage`)의 `next_id`는 다음 개체 번호다.

## 설정값

[`config.lua`](../../DoGS_mod/dogs/config.lua)의 값이다. 실험으로만 바꾼다.

| 키 | 값 | 뜻 |
| --- | --- | --- |
| `radius` | 8 | 적 인식 반경 |
| `retreat.adjacent` / `nearby` | 2 / 4 | 포위 판단: 인접 적 수 / 3타일 안 적 수 |
| `retreat.hp` / `flee` | 0.4 / 5 | 저체력 기준 / 후퇴를 시작하는 적과의 거리 |
| `retreat.exit_nearby` / `hold` | 2 / 2 | 해제 조건 / 최소 유지 턴 |
| `retreat.memory` | 5 | 존재 영속성(턴) |
| `regroup.enter` / `exit` / `hold` / `block` | 8 / 4 / 3 / 5 | 복귀 진입·해제 거리, 최소 유지, 위임 중지 턴 |
| `guard.radius` / `engage` | 3 / 2 | 엄호 거리 / 상대할 적의 거리 |
| `control_nearby` | 2 | 제압 공격 시 3타일 안 적 수 상한 |
| `attacks.*.cooldown` | 8 | 공격 쿨다운(턴) |
| `takedown.duration` / `chance` | 2 / 크기별 | 넘어짐 턴 / 크기별 확률 |
| `summary_interval` | 10 | 요약 기록 주기(턴) |

## 로그

게임 사용자 디렉터리의 `config/debug.log`에서 `[DoGS]`가 붙은 줄이다. 플레이 중 기록되는 줄에는 모두 `turn=`(게임 턴)이 붙는다.

| 이벤트 | 내용 |
| --- | --- |
| `load`, `finalize`, `selftest` | 로딩 표식 |
| `decide` | 상태 전환과 근거: HP 비율, 인접 수, 3타일 수, 가장 가까운 적, 플레이어 거리 |
| `step` / `step_failed` | 한 칸 이동(종류: retreat, flee, disengage, regroup, intercept)과 위험 점수 전후 |
| `hold` | 저체력 후퇴 중 대기 시작(대기마다 한 번) |
| `disengage` | 제압 후속의 이탈 시도 |
| `special` | 공격 ID, 표적, 결과(`outcome`), 실제 피해, 넘어짐·출혈·발목 상처 |
| `melee` | 개의 일반 공격: 표적 타입, 명중, 공격 뒤 표적 HP |
| `player_melee` | 플레이어의 근접 공격: 대상(번호), 명중, 대상이 넘어져 있었는지, 대상 HP |
| `player_attacked` | 플레이어가 받은 근접 공격: 공격자, 명중, 공격 뒤 플레이어 HP(신체 부위 합) |
| `summary` | 10턴마다 우호적인 Labrador mutt 전부: 훈련, 역할, 상태, 위치, HP, 플레이어 거리, 주변 적 수·HP 합, 플레이어 HP |
| `probe_result` | 엔진에 맡긴 복귀 목적지를 엔진이 바꾼 경우에만 |
| `death` | 개, 개가 처치한 몬스터, 번호가 붙은 몬스터의 사망. 처치자는 몬스터, `avatar`, `none`(출혈이나 디버그 처치) |
| `menu` | 메뉴 변경 |

## 메뉴

action_menu → 기타 → **DoGS laboratory**. 보이는 Labrador mutt가 여럿이면 거리순 목록에서 고른다. 제목에 번호, 역할, HP, 상태, 쿨다운이 표시된다.

| 번호 | 항목 |
| --- | --- |
| 1 | 훈련 켜기·끄기(길들인 개만) |
| 2 | 공격 모드 순환: auto → takedown → ankle |
| 3 | 상태 메시지 켜기·끄기 |
| 4 | HP 회복(실험용) |
| 5 | 역할 전환: 엄호 ↔ 자유 |

## 실험 진행

- 절차와 결과는 [실험 기록](experiments.md)에 있다. 새 실험은 배치, 측정, 성공 기준을 먼저 적고 시작한다.
- 매 수정은 직전 플레이 로그 분석으로 시작한다. 로그를 읽지 않고 기능을 더하지 않는다.
- 로그는 마지막 `event=load build=claude-rebuild` 이후를 본다. 회차는 `menu`(HP 회복, 훈련 전환) 이벤트로 나눈다.
- 실험자가 회차를 어떻게 정리했는지(직접 처치, 디버그 처치)를 함께 기록한다. 로그의 `killer=none`만으로는 출혈 사망과 디버그 처치를 구분할 수 없다.
- 로딩 성공이나 정책 검사 통과를 플레이 검증으로 적지 않는다.

## 작업 원칙

- 커밋 표기는 [research-rules](../../AGENT/research-rules.md)를 따른다. 작업은 `main`에 커밋하고, 커밋할 때마다 바로 푸시한다.
- 문서를 고치면 영어·한국어판을 같이 고친다. 실험 결과는 [실험 기록](experiments.md), 결정은 [로드맵](roadmap.md)의 결정 기록과 해당 설계 문서에 반영한다.

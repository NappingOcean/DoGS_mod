# 개발 안내

[English](../en/development.md) · [목차](index.md)

코드를 고치거나 실험을 진행할 때 필요한 정보를 모은다. 경로는 저장소 루트 기준이다.

## 저장소 구조

| 경로 | 내용 |
| --- | --- |
| [`DoGS_mod/`](../../DoGS_mod/) | 모드 본체(모드 ID `DoGS`). 게임의 `mods/DoGS`가 이 폴더를 가리킨다 |
| [`docs/`](../) | 문서(영어 `en`, 한국어 `ko`). 두 언어를 같이 고친다 |
| [`scripts/`](../../scripts/) | 설치·검사·릴리스 스크립트 |
| [`release/`](../../release/) | 릴리스 zip에 들어가는 플레이어용 README |
| [`AGENTS.md`](../../AGENTS.md), [`AGENT/research-rules.md`](../../AGENT/research-rules.md) | 에이전트 작업 규칙, 커밋 표기 |

## 설치와 검사

```powershell
.\scripts\Install-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
.\scripts\Test-Mod.ps1 -GameDirectory <BN 게임 디렉터리>
```

- `Install-Mod.ps1`은 게임의 `mods/DoGS`를 `DoGS_mod/`에 정션으로 연결한다. 예전 `mod/`를 가리키는 정션만 교체하고, 다른 대상이 있으면 멈춘다.
- `Test-Mod.ps1`은 임시 사용자 디렉터리에서 복사본의 개발자 도구를 켜고 `--check-mods DoGS`를 실행한다. 출력에 `Error`가 있거나 로딩 표식(`selftest scope=policy result=pass`, `load build=<버전> dev_tools=true`, `finalize result=pass`)이 없으면 실패한다. BN은 Lua 로딩 오류가 나도 종료 코드 0으로 끝날 수 있다. `-Release`를 주면 배포 상태 그대로 검사한다. `dev_tools=false`이고 `selftest` 줄이 없어야 한다.
- 통과는 데이터 로딩, ID 검사, 순수 정책 함수 검사가 통과했다는 뜻이다. 플레이 검증이 아니다.
- 코드를 바꾼 뒤에는 게임에서 월드를 다시 불러와야 적용된다.

## 개발자 도구

[`dogs/config.lua`](../../DoGS_mod/dogs/config.lua)의 `dev_tools`는 저장소와 릴리스에서 `false`다. 꺼져 있으면 DoGS는 디버그 메뉴 항목과 기록용 훅(`on_creature_melee_attacked`, `on_mon_death`, 요약 타이머)을 등록하지 않고 자체 검사도 돌리지 않는다. 디버그 모드를 켠 채 저장된 월드에서도 디버그 모드는 꺼진 것으로 다루므로 로그, 상태 메시지, 단계 덮어쓰기, 견제에 닿을 수 없다.

- [source] action menu의 `debug` 분류에 Lua 항목이 하나라도 있으면 디버그 키가 해제되어 있어도 BN이 Debug 분류를 보여 준다([action.cpp:1100](https://github.com/cataclysmbn/Cataclysm-BN/blob/f9586ef033948451f9c5a136d1ce6214198f1a67/src/action.cpp#L1100)). 그래서 항목을 등록한 뒤 숨기지 않고 아예 등록하지 않는다.
- 개발할 때는 로컬에서 `dev_tools = true`로 바꾸고 커밋하지 않는다. `Build-Release.ps1`과 `Test-Mod.ps1 -Release`는 `dev_tools = false,`가 없는 설정을 거부한다.

## 릴리스

```powershell
.\scripts\Build-Release.ps1 -GameDirectory <BN 게임 디렉터리>
```

작업 트리가 깨끗해야 한다. `DoGS_mod/`를 개발자 전용 파일(`dogs/tests.lua`)을 뺀 채 `dist/stage-<버전>/DoGS/`로 복사하고, `LICENSE`와 `release/`의 플레이어용 README를 넣은 뒤, 그 폴더를 `Test-Mod.ps1 -Release`로 검사하고, `DoGS/` 폴더 하나만 든 `dist/DoGS-<버전>.zip`을 만든다. 버전은 `modinfo.json`에서 읽는다. `preload.lua`의 `build=` 로딩 표식도 같게 맞춘다.

## 모듈

| 파일 | 역할 |
| --- | --- |
| [`preload.lua`](../../DoGS_mod/preload.lua) | 모듈 로딩, AI 콜백·훅·휘슬 사용 함수 등록. 개발자 도구가 켜져 있으면 디버그 메뉴·기록용 훅·주기 기록도 등록하고 정책 검사를 실행 |
| [`finalize.lua`](../../DoGS_mod/finalize.lua) | 개 타입, 휘슬, 효과 ID 유효성 검사 |
| [`json/dogs.json`](../../DoGS_mod/json/dogs.json) | 성견 12종 덮어쓰기: `lua_ai`, 공격 두 개. 견종마다 따로 둔다(본편 견종은 DoGS보다 먼저 `mon_dog`를 복사한다, [엔진 사실](engine-notes.md)). HP는 바닐라 그대로 |
| [`json/whistle.json`](../../DoGS_mod/json/whistle.json) | 명령용 휘슬 아이템, 사용 동작, 제작법 |
| [`json/effects.json`](../../DoGS_mod/json/effects.json) | 효과 `dogs_ankle_wound`, `dogs_trained_dog`(영구, `run`을 막음) |
| [`dogs/ai.lua`](../../DoGS_mod/dogs/ai.lua) | 판단 순서([행동 설계](design.md) 2절), 엄호, 복귀 위임 |
| [`dogs/policy.lua`](../../DoGS_mod/dogs/policy.lua) | 순수 함수: 상태 전환, 제압 조건, 공격 선택, Takedown 확률, 엄호 표적, 이동 후보 순위 |
| [`dogs/perception.lua`](../../DoGS_mod/dogs/perception.lua) | 적 탐색과 관측값 |
| [`dogs/movement.lua`](../../DoGS_mod/dogs/movement.lua) | 한 칸 이동: retreat, flee, disengage, regroup, intercept, kite |
| [`dogs/attacks.lua`](../../DoGS_mod/dogs/attacks.lua) | 공격 선택·실행, 개체 값 쿨다운, Takedown 판정, 회피 훅 |
| [`dogs/role.lua`](../../DoGS_mod/dogs/role.lua) | 역할 읽기·설정. 값이 없으면 엄호. 견제는 허용될 때만(v0.1은 디버그 모드) |
| [`dogs/breed.lua`](../../DoGS_mod/dogs/breed.lua) | DoGS 개 판별(견종 목록), 훈련 단계(디버그 덮어쓰기 포함), 능력별 단계 검사 |
| [`dogs/debug.lua`](../../DoGS_mod/dogs/debug.lua) | 디버그 모드 상태(모드 저장소). 개발자 도구가 꺼져 있으면 항상 꺼짐 |
| [`dogs/events.lua`](../../DoGS_mod/dogs/events.lua) | 10턴 요약, 근접공격 기록(개·플레이어), 사망 기록 |
| [`dogs/menu.lua`](../../DoGS_mod/dogs/menu.lua) | 휘슬(역할 지시)과 디버그 메뉴 |
| [`dogs/log.lua`](../../DoGS_mod/dogs/log.lua) | 로그 줄 작성(디버그 모드에서만), 개체 번호 |
| [`dogs/config.lua`](../../DoGS_mod/dogs/config.lua) | 모든 수치. 바꾼 이유가 된 실험을 주석으로 단다 |
| [`dogs/tests.lua`](../../DoGS_mod/dogs/tests.lua) | 로딩 중 정책 함수 검사(개발자 도구 전용, 릴리스 zip에서 제외). 엔진 동작의 증거가 아니다 |

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
| `dogs_role` | `"harass"`면 견제, `"free"`면 자유, 그 밖에는 엄호 |
| `dogs_attack_mode` | `auto`(빈 값 포함), `takedown`, `ankle` |
| `dogs_debug_level` | 디버그 모드의 훈련 단계 덮어쓰기(`"0"`~`"5"`). 비어 있거나 디버그 모드가 꺼져 있으면 본편 단계 |
| `dogs_state`, `dogs_state_turn` | 현재 상태와 진입한 게임 턴 |
| `dogs_threat_turn` | 적을 인식한 마지막 게임 턴(존재 영속성) |
| `dogs_holding` | 저체력 후퇴 중 대기 기록을 한 번만 남기기 위한 표식 |
| `dogs_disengage` | 제압 공격 뒤 후속 단계 표식 |
| `dogs_docile` | 마지막으로 기록한 docile 상태(변화를 한 번만 기록하기 위함) |
| `dogs_next_<공격 ID>` | 다음 사용 가능 게임 턴 |
| `dogs_delegate_block` | 이 게임 턴까지 복귀를 엔진에 맡기지 않음 |
| `dogs_harass_target` | 견제 중인 표적의 개체 번호 |
| `dogs_engaged_turn` | 플레이어에게 적이 붙어 있던 마지막 게임 턴(견제 자동 종료) |
| `dogs_recall_until` | 이 게임 턴까지 견제를 멈춘다(디버그 메뉴의 호출) |
| `dogs_track_turn` | `track`을 턴마다 한 번만 남기기 위한 표식 |
| `dogs_probe_dest`, `dogs_probe_player` | 엔진에 맡긴 복귀 목적지(절대 좌표)와 그때의 플레이어 거리 |

모드 저장소(`game.mod_storage`)의 `next_id`는 다음 개체 번호, `debug`는 디버그 모드(true면 켜짐)다. 월드와 함께 저장된다.

## 설정값

[`config.lua`](../../DoGS_mod/dogs/config.lua)의 값이다. 실험으로만 바꾼다.

| 키 | 값 | 뜻 |
| --- | --- | --- |
| `dog_ids` | 성견 12종 | DoGS 개로 다루는 몬스터 종류. `json/dogs.json`에 같은 목록이 있어야 한다 |
| `training.judgment` / `attacks` / `harass` | 1 / 2 / 3 | 판단층과 엄호·자유, 제압 공격, 견제가 열리는 본편 훈련 단계 |
| `dev_tools` | false | 개발자 도구(위 참고). 릴리스에서는 false |
| `harass_enabled` | false | 디버그 모드 밖에서 견제를 허용하는가(v0.1은 숨김) |
| `radius` | 8 | 적 인식 반경 |
| `retreat.adjacent` / `nearby` | 2 / 4 | 포위 판단: 인접 적 수 / 3타일 안 적 수 |
| `retreat.hp` / `flee` | 0.4 / 5 | 저체력 기준 / 후퇴를 시작하는 적과의 거리 |
| `retreat.exit_nearby` / `hold` | 2 / 2 | 해제 조건 / 최소 유지 턴 |
| `retreat.memory` | 5 | 존재 영속성(턴) |
| `regroup.enter` / `exit` / `hold` / `block` | 8 / 4 / 3 / 5 | 복귀 진입·해제 거리, 최소 유지, 위임 중지 턴 |
| `guard.radius` / `engage` | 3 / 2 | 엄호 거리 / 상대할 적의 거리 |
| `harass.range` / `hold_min` / `hold_max` | 8 / 2 / 3 | 견제 범위 / 표적과 유지할 거리 |
| `harass.crowd` / `finish` / `recall` | 1 / 3 / 10 | 노출 기준(주변 다른 적 수) / 자동 종료 턴 / 호출 지속 턴 |
| `control_nearby` | 2 | 제압 공격 시 3타일 안 적 수 상한 |
| `attacks.*.cooldown` | 8 | 공격 쿨다운(턴) |
| `takedown.min_ratio` / `full_ratio` | 0.3 / 0.6 | 시도하는 체중비 / 확률이 100%가 되는 체중비 |
| `takedown.min_chance` / `train_bonus` | 50 / 5 | `min_ratio`에서의 확률 / 훈련 단계당 확률 보정 |
| `takedown.duration` / `train_turn` | 2 / 4 | 기본 넘어짐 턴 / 넘어짐 +1턴이 붙는 훈련 단계 |
| `summary_interval` | 10 | 요약 기록 주기(턴) |

## 로그

게임 사용자 디렉터리의 `config/debug.log`에서 `[DoGS]`가 붙은 줄이다. 플레이 중 기록은 **디버그 모드에서만** 남는다(로딩 표식은 항상, `selftest` 표식과 `debug` 이벤트는 개발자 도구가 켜져 있을 때만). 플레이 중 기록되는 줄에는 모두 `turn=`(게임 턴)이 붙는다.

| 이벤트 | 내용 |
| --- | --- |
| `load`, `finalize`, `selftest` | 로딩 표식 |
| `debug` | 디버그 모드 전환(`on=true/false`). 턴 표시 없음 |
| `decide` | 상태 전환과 근거: HP 비율, 인접 수, 3타일 수, 가장 가까운 적, 플레이어 거리 |
| `step` / `step_failed` | 한 칸 이동(종류: retreat, flee, disengage, regroup, intercept, kite)과 위험 점수 전후 |
| `hold` | 저체력 후퇴 중 대기 시작(대기마다 한 번) |
| `disengage` | 제압 후속의 이탈 시도 |
| `docile` | docile 상태가 바뀜(`on=true/false`) |
| `docile_disengage` | docile인 동안 붙은 적에게서 물러난 시도(`moved`) |
| `trained` | 훈련된 개 효과를 붙이거나 뗌(`on=true/false`) |
| `special` | 공격 ID, 표적, 결과(`outcome`), 실제 피해, 넘어짐·출혈·발목 상처 |
| `melee` | 개의 일반 공격: 표적 타입, 명중, 공격 뒤 표적 HP |
| `player_melee` | 플레이어의 근접 공격: 대상(번호), 명중, 대상이 넘어져 있었는지, 대상 HP |
| `player_attacked` | 플레이어가 받은 근접 공격: 공격자, 명중, 공격 뒤 플레이어 HP(신체 부위 합) |
| `summary` | 10턴마다 우호적인 DoGS 견종 개 전부: 종류(`type`), 훈련 단계(`level`), 역할, 상태, 위치, HP, 플레이어 거리, 주변 적 수·HP 합, 플레이어 HP, 플레이어에게 붙은 적 수(`on_player`) |
| `probe_result` | 엔진에 맡긴 복귀 목적지를 엔진이 바꾼 경우에만. `engine_target`은 개의 직전 계획에 보이는 표적이 있었는지(`attack_target`) |
| `death` | 개, 개가 처치한 몬스터, 번호가 붙은 몬스터의 사망. 처치자는 몬스터, `avatar`, `none`(출혈이나 디버그 처치) |
| `harass_target`, `harass_end` | 견제 표적 선택과 종료 |
| `track` | 견제 중 턴마다: 표적과 개·플레이어 거리, 표적 목적지가 누구 쪽인지(`toward`), 표적이 공격하려는 대상(`chases`: player, dog, other, none), 플레이어에게 붙은 적 수 |
| `menu` | 휘슬(`source=whistle`, 역할)과 디버그 메뉴 변경(`choice`, 단계, 공격 모드, 역할, HP) |

## 메뉴

**명령용 휘슬**(플레이어용): 소지품에서 사용한다. 보이는 길들인 DoGS 개가 여럿이면 거리순 목록에서 고르고, 역할(엄호·자유, 디버그 모드에서는 견제도)을 고른다. 제작: 기타 → 도구, 나무 휘슬과 같은 재료(각목 또는 막대기)와 기술(제작 2, 생존 2).

**디버그 메뉴**(개발자 도구 전용): action_menu → Debug → **DoGS debug**(그 안의 단축키 `D`). 첫 항목이 디버그 모드 켜기·끄기다. 켜면 로그, 상태 메시지(`DoGS #번호: 상태`), 개 도구가 열린다. 개 도구의 제목에 번호, 종류, 역할, HP, 상태, 쿨다운이 표시된다.

| 번호 | 개 도구 항목 |
| --- | --- |
| 1 | HP 회복 |
| 2 | 공격 모드 순환: auto → takedown → ankle |
| 3 | 훈련 단계 덮어쓰기 순환: 없음 → 0 → … → 5 → 없음 |
| 4 | 역할 순환: 엄호 → 자유 → 견제 |
| 5 | 호출: 10턴 동안 견제를 멈추고 엄호로 |

## 실험 진행

- 절차와 결과는 [실험 기록](experiments.md)에 있다. 새 실험은 배치, 측정, 성공 기준을 먼저 적고 시작한다.
- 매 수정은 직전 플레이 로그 분석으로 시작한다. 로그를 읽지 않고 기능을 더하지 않는다.
- 로그는 마지막 `event=load` 이후를 본다. 회차는 `menu`(HP 회복, 단계 덮어쓰기) 이벤트로 나눈다. 실험 전에 개발자 도구와 디버그 모드를 켠다.
- 실험자가 회차를 어떻게 정리했는지(직접 처치, 디버그 처치)를 함께 기록한다. 로그의 `killer=none`만으로는 출혈 사망과 디버그 처치를 구분할 수 없다.
- 로딩 성공이나 정책 검사 통과를 플레이 검증으로 적지 않는다.

## 작업 원칙

- 커밋 표기는 [research-rules](../../AGENT/research-rules.md)를 따른다. 작업은 `main`에 커밋하고, 커밋할 때마다 바로 푸시한다.
- 문서를 고치면 영어·한국어판을 같이 고친다. 실험 결과는 [실험 기록](experiments.md), 결정은 [로드맵](roadmap.md)의 결정 기록과 해당 설계 문서에 반영한다.

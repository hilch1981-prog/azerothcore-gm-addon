# 런타임 다국어 구조

## 대상

- WoW WotLK 3.3.5a Build 12340
- Interface 30300
- Lua 5.1
- AzerothCore
- 지원 언어: `enUS`, `koKR`, `zhCN`, `zhTW`

## 기본 원칙

AzerothAdmin의 기존 한국어 소스를 강제로 전부 번역하지 않는다. 한국어 문자열에는 사용자에게 표시되는 UI 문구뿐 아니라 검색·파싱·분류에 직접 사용되는 동작 데이터가 포함되어 있기 때문이다.

### 번역 대상

- 창 제목
- 버튼/탭 이름
- 상태 문구
- 오류/안내 문구
- 툴팁
- AzerothAdmin 전용 StaticPopup
- 애드온 채팅 출력
- 명령의 사용자 표시용 `label`, `hint`, `example`

### 번역하지 않는 데이터

- AzerothCore GM 명령 문자열 (`.npc`, `.quest`, `.account` 등)
- `permissionCommand`
- GM 권한/명령 메타데이터
- `KoKRSearchData.lua`의 한국어 검색 색인
- QuestHelper의 `처치`, `획득`, `수집`, `찾기` 등 koKR 목표 파싱어
- ItemBrowser의 한국어 분류/검색 판별 키워드
- 좌표, Entry ID, Spawn GUID, Map ID
- 검증되지 않은 한국어 고유 지명

이 데이터를 임의 번역하면 검색 결과 누락, 목표 유형 오판정, 명령 실행 실패 또는 잘못된 좌표 선택이 발생할 수 있다.

## 로드 구조

```text
Framework/Localization.lua
Framework/UILocalization.lua
Locales/enUS.lua
Locales/koKR.lua
Locales/zhCN.lua
Locales/zhTW.lua
Locales/UI/...
Locale.lua
Framework/FeatureLocalization.lua
...
Modules/Shell/Core.lua
Modules/Language/Output.lua
...
```

`Locale.lua`가 SavedVariables의 언어 override를 적용한 뒤 `FeatureLocalization.lua`의 `ADDON_LOADED` 처리에서 기능 정의의 표시 문자열을 변환한다.

## 언어 선택

기본 동작은 클라이언트 Locale 자동 감지다. 사용자는 다음 두 방법으로 override할 수 있다.

- 미니바 버튼: `AUTO → KO → EN → 简 → 繁`
- 채팅 명령: `/aalang auto|enUS|koKR|zhCN|zhTW`

선택값은 `AzerothAdminEasyDB.localeOverride`에 저장되며 변경 후 `ReloadUI()`로 전체 UI에 적용한다.

## 런타임 UI 현지화

`Framework/UILocalization.lua`는 기존 기능 파일을 대규모 재작성하지 않고 사용자 표시 계층만 변환한다.

- 정확한 문자열 매핑
- 제한된 패턴 매핑
- FontString 재귀 스캔
- `aaeHint`, `aaeTitle`, `tooltipText`, `tooltipTitle` 변환
- `koKR`에서는 변환하지 않고 기존 원문 사용
- `zhCN`/`zhTW`에 개별 번역이 없으면 `enUS` 표시문구로 fallback

`Framework/FeatureLocalization.lua`는 다음 기능을 담당한다.

- Commands 표시문구 overlay
- Teleports/Favorites 표시명 overlay
- AzerothAdmin 전용 StaticPopup
- 지연 생성되는 창의 OnShow/OnUpdate 현지화
- AzerothAdmin 소유 프레임에서 열린 GameTooltip 현지화

## Commands 안전장치

명령 데이터에서 다음 값은 절대 번역하지 않는다.

```text
command
permissionCommand
commandName
requiredSecurity
```

비한국어 모드에서 번역 사전에 없는 명령 label이 남으면 실제 AzerothCore 명령 문자열을 표시한다. hint가 남으면 언어별 `AzerothCore GM command` 안내로 대체한다. 따라서 UI 번역 누락 때문에 서버 명령이 변경되지 않는다.

## Teleports 안전장치

주요 도시/레이드처럼 확인된 이름만 표시명을 현지화한다. 출처가 불명확하거나 번역을 검증하지 않은 고유 지명은 기존 이름을 유지한다.

다음 값은 번역하지 않는다.

- `command`
- `map`
- `x`, `y`, `z`, `o`
- 메뉴/옵션 ID

## 채팅/상태 출력

`Modules/Language/Output.lua`는 기존 `addon:Print()`를 얇게 감싸 표시 문자열만 `TranslateUI()`에 통과시킨다. 서버 명령 전송 함수인 `SendNow()` 및 실행 정의는 변경하지 않는다.

## 테스트 원칙

정적 검사에서 다음을 확인한다.

- Lua 5.1 문법
- Interface 30300 TOC 경로/순서
- Retail 전용 API 미사용
- `.command`와 `permissionCommand`를 번역 계층이 수정하지 않음
- 런타임 UI 사전이 기능 모듈보다 먼저 로드됨
- 지연 생성 창과 AzerothAdmin 소유 Tooltip 후킹 경로 존재
- 채팅 출력 wrapper가 명령 전송을 건드리지 않음

정적 검사는 게임 내 UI 폭, 글꼴 렌더링, 실제 클릭, SavedVariables 적용, 서버 응답을 대체하지 않는다.

## 게임 테스트 필수 항목

- 미니바 언어 버튼 위치와 클릭 순환
- 언어 변경 후 ReloadUI 및 재접속 시 설정 유지
- Shell / Commands / Search / QuestHelper / Creatures / ItemBrowser / ProfessionInfo / Teleports / Favorites
- StaticPopup / Tooltip / 상태 출력
- koKR 검색과 QuestHelper 목표 판별
- 크리처 모델 전환과 인스턴스 안전 이동
- 은행/부활/퀵슬롯 등 기존 기능 회귀

게임 내 확인 전에는 다국어 작업을 최종 완료로 표시하지 않는다.

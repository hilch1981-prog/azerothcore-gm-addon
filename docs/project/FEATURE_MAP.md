# 기능 구현 위치

이 문서는 기능의 실제 진입점과 구현 파일을 기록한다. UI 이름만 보고 기능을 추정하지 않고 아래 위치에서 동작을 확인한다.

| 기능 | 사용자 진입점 | 핵심 구현 | 서버 명령/API | 검증 |
|---|---|---|---|---|
| 메인 GM 창 | `/aa`, 미니맵 버튼 | `AzerothAdmin/UI.lua`, `AzerothAdmin/Core.lua` | 애드온 슬래시 명령 | Lua/TOC 정적 검사 |
| 퀘스트 도우미 | 도구 모음 `퀘스트` | `AzerothAdmin/QuestHelper.lua` | 퀘스트 로그 API, `.quest complete`, `.go creature`, `.go object` | 선택·상세·하이라이트 수명주기 자동검사 |
| 파티·봇 퀘스트 동기화 | 퀘스트 도우미 상단 선택 항목 | `AzerothAdmin/QuestHelper.lua` | `QuestLogPushQuest`, Playerbots `quest complete [quest]` | 큐·상태 전환·파티 합류 자동검사; 게임 검사 대기 |
| 한글 아이템/퀘스트 검색 | 검색 UI와 명령 인수 창 | `AzerothAdmin/KoKRSearch.lua`, `KoKRSearchData.lua` | `.additem`, `.quest add` | 팝업·수량 처리 자동검사 |
| 주요 크리처 정보 | 명령 메뉴 `주요 크리처 / 한글·ID 검색` | `AzerothAdmin/FeaturedCreatures.lua`, `CreatureBrowser.lua`, `KoKRSearch.lua` | 3.3.5a `PlayerModel:SetCreature`, `.go creature id`, `.list creature`, `.npc add temp`, `.npc add` | 187개 선별 데이터·koKR 일치·스크롤·3D 외형·소환 분리 자동검사; 게임 검사 대기 |
| 기능 퀵슬롯 | 메인 명령/기능 버튼 우클릭, 하단 퀵슬롯 | `AzerothAdmin/Core.lua`, `UI.lua`, `Commands.lua` | 공통 `ExecuteDefinition` | command/action 키·기존 저장값 호환·권한 명령 자동검사; 게임 검사 대기 |
| 아이템 정보 | 도구 모음 `아이템 정보` | `Embedded/BlueItemInfo3/Integrated.lua` | `.additem` | `BlueItemInfo3` 독립 프레임 자동검사 |
| 전문기술 정보 | 도구 모음 `전문기술` | `Embedded/InvenCraftInfoUI/Rebuilt.lua`, `Embedded/InvenCraftInfo*` | `.learn`, `.setskill` | `AzerothAdminCraftInfoFrame` 독립 프레임·초기화 자동검사 |
| 퀘스트 보상 분류 | 아이템 정보의 퀘스트 보상 분류 | `Embedded/BlueItemInfo3/QuestRewards335.lua` | 공식 `quest_template` 생성 데이터 | 생성기 회귀 검사 |
| 원격 은행 | 도구 모음 `은행` | `AzerothAdmin/Integrations.lua` | `.character check bank`, `BANKFRAME_OPENED` | 자동검사 + 사용자 실사용 확인 |
| 자기 부활 | 도구 모음 부활 명령 | `AzerothAdmin/Core.lua` | 자기 귓속말 `.revive` | 자동검사 + 사용자 실사용 확인 |
| Questie 드랍처 이동 | 퀘스트 목표 `드랍처 이동` | `AzerothAdmin/QuestHelper.lua` | Questie `QueryItem`, `.go creature`, `.go object` | 순환 순서 자동검사 |
| 티켓/그룹 관리 | 명령 메뉴 | `AzerothAdmin/Commands.lua`, `CommandMeta.lua` | AzerothCore 티켓·그룹 GM 명령 | 명령 메타데이터 감사; 게임 검사 대기 |
| 창 전환/ESC/팝업 | 모든 관리 창 | `AzerothAdmin/Core.lua` | 3.3.5a Frame/StaticPopup API | 관리 프레임 및 팝업 수명주기 자동검사 |

## 로드 순서 핵심

- 공통 로컬라이징과 명령 데이터가 `Core.lua`보다 먼저 로드된다.
- 전체 koKR 검색 데이터와 주요 크리처 선별 데이터가 크리처 브라우저보다 먼저 로드되고, 브라우저는 `Core.lua`의 실행 시점에 공통 명령 함수를 사용한다.
- `Core.lua`가 관리 창 공통 함수를 만든 뒤 `QuestHelper.lua`와 `UI.lua`가 로드된다.
- InvenCraftInfo 라이브러리와 데이터가 전문기술 재구성 UI보다 먼저 로드된다.
- BlueItemInfo3 데이터·분류·퀘스트 보상이 통합 아이템 창보다 먼저 로드된다.
- 두 독립 창이 생성된 뒤 `Integrations.lua`가 전환 함수를 연결한다.

이 순서는 `tools/validate_addon_structure.py`와 GitHub Actions가 회귀를 차단한다.

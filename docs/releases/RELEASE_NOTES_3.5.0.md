# AzerothAdmin 3.5.0-335a 릴리즈 노트

## 대상 환경

- World of Warcraft WotLK 3.3.5a Build 12340
- Interface 30300
- AzerothCore WotLK
- Lua 5.1

## 주요 변경 사항

### 모듈 구조 정리

- Shell, Commands, Search, Teleports, QuestHelper, Creatures, ItemBrowser, ProfessionInfo, Integrations 기능을 모듈 단위로 정리했습니다.
- 기존 SavedVariables와 주요 UI/UX 흐름은 유지하면서 기능별 등록·로드 경로를 분리했습니다.
- 기능 간 의존성과 실제 구현 위치를 `MODULE_MANIFEST.json` 및 프로젝트 문서에서 추적할 수 있도록 정리했습니다.

### 다국어 UI 확장

- 지원 언어를 `enUS`, `koKR`, `zhCN`, `zhTW`, `ruRU`로 확장했습니다.
- 하단 언어 미니바에서 `AUTO → KO → EN → 简 → 繁 → RU` 순환을 지원합니다.
- 비한국어 모드에서 팝업, 전문기술, 검색, 퀘스트 도우미 등에 남던 한글 UI 문구를 추가 정리했습니다.
- 런타임에 늦게 등록되는 `AZEROTHADMIN_` StaticPopup도 현재 언어에 맞게 보정합니다.
- CJK 및 키릴 문자 표시를 위해 검증된 `AzerothAdminUnicode.ttf`와 OFL/NOTICE를 포함합니다.

### 아이템 정보 및 로케일 출처 표시

- ItemBrowser의 비한국어 UI fallback을 보강했습니다.
- 아이템명/설명은 애드온 자체 번역이 아니라 WoW 클라이언트 로케일 및 AzerothCore 서버 DB 로케일 데이터의 영향을 받는다는 점을 게임 내 UI와 문서에 명시했습니다.

### 크리처 브라우저 안정화

- 실제 게임 테스트에서 정상 동작하지 않았던 `PlayerModel` 3D 미리보기, 카메라 회전 및 관련 처리 코드를 제거했습니다.
- 크리처 목록, 검색, 위치 이동, 임시/영구 소환 등 검증 가능한 핵심 기능은 유지합니다.
- 로케일 변경이 크리처 텔레포트 경로를 깨뜨리지 않도록 canonical label 기반 라우팅을 보강했습니다.

### 기존 핵심 기능 유지

- 원격 은행 세션 및 기본 BankFrame 연동 경로 유지
- 자기 캐릭터 부활 처리 유지
- 퀘스트 아이템 드랍처 NPC/오브젝트 순환 이동 유지
- InvenCraftInfo와 ItemBrowser를 별도 기능으로 유지
- 퀘스트 보상 4대륙 분류, 강화 분류, 낚시/요리/응급치료 데이터 보강 유지
- 퀵슬롯 action/command 호환 및 NPC 진단 명령 보강 유지

## 정적 검증

최근 다국어 보강 PR 기준으로 다음 검사가 통과했습니다.

- Python 회귀 테스트 90개 PASS
- TOC 등록 경로 81개 PASS
- XML 2개 PASS
- Retail 전용 API(`C_Container`, `C_Item`, `C_QuestLog`, `ScrollBox`, `C_Map`, `C_Timer`) 검출 없음
- `AzerothAdmin/Fonts/AzerothAdminUnicode.ttf` 포함 및 검증 ZIP과 SHA-256 일치 확인
- GitHub Actions Addon static checks PASS
- Claude Code Review PASS

## 게임 테스트 관련 주의

- 3D 크리처 미리보기는 실제 게임 테스트 결과 실패하여 이번 버전에서 제거되었습니다.
- ruRU 및 비한국어 UI 보강은 사용자 테스트 피드백을 반영한 상태입니다.
- 저장소의 `TASKS.md`와 `docs/project/GAME_TEST_MATRIX.md`에 아직 게임 내 회귀 테스트 대기로 기록된 세부 항목은 정적 검증 완료와 구분해서 관리합니다.
- 따라서 이 릴리즈는 정적 검사 통과를 게임 내 모든 기능의 완전 검증으로 표현하지 않습니다.

## 업그레이드

기존 `Interface/AddOns/AzerothAdmin` 폴더를 백업한 뒤 새 버전의 `AzerothAdmin` 폴더로 교체하는 것을 권장합니다. 기존 SavedVariables 호환 경로는 유지합니다.

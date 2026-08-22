# Codex 작업 지침

이 저장소는 WoW WotLK 3.3.5a Build 12340 + AzerothCore용 `AzerothAdmin` GM 애드온이다.

## 작업 전 확인

1. `PROJECT_STATUS.md`, `TASKS.md`, `DEVELOPMENT_RULES.md`를 읽는다.
2. 변경 대상 Lua/XML/TOC의 실제 구현과 로드 순서를 먼저 확인한다.
3. 서버 명령과 관련된 변경은 AzerothCore 공개 소스의 실제 구현을 확인한다.

## 필수 호환성

- Lua 5.1 문법만 사용한다.
- WotLK 3.3.5a Interface 30300 API만 사용한다.
- `C_Container`, `C_Item`, `ScrollBox`, 최신 `C_QuestLog` 등 Retail 전용 API를 사용하지 않는다.
- `InvenCraftInfo`와 아이템 정보창은 별도 기능으로 유지한다.
- 기존 파일, 기능 및 UI/UX를 가능한 한 보존한다.
- 불가능하거나 확인되지 않은 기능을 가짜 UI로 대체하지 않는다.

## 변경 및 Git 규칙

- 기능별로 작은 변경 단위를 유지한다.
- C++/서버 변경과 애드온 Lua/XML 변경을 분리한다.
- Codex 작업 브랜치는 `codex/<기능명>`, Claude 작업 브랜치는 `claude/<기능명>` 형식을 사용한다.
- `main`에 직접 푸시하지 않고 Pull Request로 병합한다.
- 무관한 파일을 함께 스테이징하거나 기존 사용자 변경을 덮어쓰지 않는다.
- API 키, 토큰, 계정 정보, DB 접속 정보 및 개인 경로를 커밋하지 않는다.

## 검증

- Lua 5.1 구문 검사를 실행한다.
- TOC에 등록된 파일의 존재 여부와 대소문자를 확인한다.
- Retail 전용 API를 검색한다.
- 기능별 게임 내 테스트 절차와 기대 결과를 PR에 기록한다.
- 게임 내 검증을 하지 않았다면 완료했다고 표현하지 않는다.

## Code Review Rules

- WotLK 3.3.5a에서 존재하지 않는 API 사용을 차단한다.
- AzerothCore 명령 이름, 인수, 권한을 근거 없이 추정한 변경을 차단한다.
- SavedVariables 호환성을 깨뜨리는 무단 구조 변경을 차단한다.
- TOC 누락, 잘못된 경로, 로드 순서 회귀를 차단한다.
- 아이템 정보창과 InvenCraftInfo를 합치는 변경을 차단한다.

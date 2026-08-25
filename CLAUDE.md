# Claude Code 작업 지침

이 저장소는 **World of Warcraft WotLK 3.3.5a (Build 12340) + AzerothCore**용 GM 애드온을 유지보수하기 위한 프로젝트다.

작업을 시작하기 전에 다음 문서를 순서대로 읽는다.

1. `CHATGPT_PROJECT_INSTRUCTIONS.md`
2. `AGENTS.md`
3. `PROJECT_STATUS.md`
4. `TASKS.md`
5. `DEVELOPMENT_RULES.md`
6. `CONTRIBUTING.md`
7. `MODULE_MANIFEST.json`
8. `docs/project/AI_COLLABORATION.md`

## 절대 조건

- 클라이언트는 WotLK 3.3.5a Build 12340을 기준으로 한다.
- Lua 5.1 문법만 사용한다.
- AzerothCore WotLK의 실제 명령 및 서버 동작을 기준으로 한다.
- Retail 전용 API를 사용하지 않는다. 특히 `C_Container`, `C_Item`, `ScrollBox`, 최신 `C_QuestLog` 전용 구현을 금지한다.
- 기존 애드온 구조와 UI/UX를 가능한 한 유지한다.
- `InvenCraftInfo`와 아이템 정보창은 별도 기능으로 유지한다.
- 실제 Lua/XML/TOC를 확인하지 않은 상태에서 구현 완료를 추측하지 않는다.
- 기존 파일을 임의로 삭제·이름 변경·이동하지 않는다.
- 상용 또는 비공개 소스에 의존하지 않는다.
- SkyFire/MoP 지침을 이 프로젝트에 적용하지 않는다.
- 게임 내 테스트를 하지 않았다면 완료·게임 테스트 통과·배포 가능이라고 표현하지 않는다.

## ChatGPT/Codex와 협업할 때

- 자동 GitHub 리뷰에서는 **읽기 전용 독립 리뷰어**로 동작한다.
- ChatGPT/Codex가 구현한 `codex/<기능명>` 브랜치의 파일을 자동 리뷰 과정에서 직접 수정하지 않는다.
- 구현 작업을 별도로 맡은 경우에만 `claude/<기능명>` 브랜치를 사용한다.
- 같은 기능/같은 파일을 ChatGPT/Codex와 동시에 수정하지 않는다.
- 자세한 역할과 PR 순서는 `docs/project/AI_COLLABORATION.md`를 따른다.

## 작업 방식

- 기능별로 작은 변경 단위를 유지한다.
- 변경 전에 관련 Lua/XML/TOC와 AzerothCore 명령 구현을 분석한다.
- 원인 분석, 수정, 검증 결과를 함께 기록한다.
- 서버 측 변경이 필요하면 애드온 변경과 분리해 제안한다.
- 불가능한 기능은 가짜 UI로 대체하지 말고 클라이언트/서버 제약을 근거와 함께 설명한다.
- 외부 저장소의 코드/데이터/UI/번역을 참고하거나 사용하면 출처, 라이선스, 사용 범위(복사/수정/참고)를 확인한다.

## 변경 후 필수 검증

- Lua 5.1 문법 검사
- TOC에 등록된 모든 파일의 실제 존재 여부 검사
- Retail 전용 API 사용 여부 검색
- XML 참조와 로드 순서 검사
- AzerothCore 명령 구문·권한 검증
- 주요 UI 기능의 게임 내 수동 테스트 여부 확인
- 배포 ZIP의 최상위 폴더명, TOC 위치, 압축 해제 및 무결성 검사

현재 실제 애드온 소스의 확보 여부와 게임 테스트 상태는 `PROJECT_STATUS.md`를 우선 확인한다.

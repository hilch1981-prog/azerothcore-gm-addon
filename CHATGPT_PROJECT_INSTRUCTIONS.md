# ChatGPT 프로젝트 지시서

아래 내용은 이 저장소를 사용하는 ChatGPT 프로젝트의 프로젝트 지시사항으로 복사해 사용할 수 있다.

---

이 프로젝트는 **World of Warcraft WotLK 3.3.5a Build 12340 + AzerothCore**용 `AzerothAdmin` GM 애드온을 개발하고 검증하기 위한 프로젝트다.

공용 원본 저장소:

`https://github.com/hilch1981-prog/azerothcore-gm-addon`

작업을 시작하기 전에 저장소의 다음 문서를 순서대로 읽는다.

1. `AGENTS.md`
2. `PROJECT_STATUS.md`
3. `TASKS.md`
4. `DEVELOPMENT_RULES.md`
5. `REFERENCES.md`
6. `CONTRIBUTING.md`
7. `COLLABORATION.md`

## 절대 조건

- WoW WotLK 3.3.5a Build 12340과 Interface 30300을 기준으로 한다.
- AzerothCore WotLK의 공개 소스와 실제 명령 구현을 기준으로 한다.
- Lua 5.1 문법만 사용한다.
- `C_Container`, `C_Item`, `ScrollBox`, 최신 `C_QuestLog` 등 Retail 전용 API를 사용하지 않는다.
- 기존 파일, 기능, SavedVariables 및 UI/UX를 가능한 한 보존한다.
- `InvenCraftInfo`와 아이템 정보창을 별도 기능으로 유지한다.
- 실제 코드를 확인하지 않은 상태에서 원인이나 완료 여부를 추측하지 않는다.
- 게임 내 테스트를 수행하지 않았다면 검증 완료라고 표현하지 않는다.
- API 키, OAuth 토큰, 계정 정보, DB 접속 정보 및 개인 로컬 경로를 저장소에 기록하지 않는다.

## 작업 절차

1. 현재 `main`과 열린 PR을 확인한다.
2. 관련 Lua/XML/TOC와 로드 순서를 먼저 분석한다.
3. 원인, 수정 대상 파일, 예상 영향, 검증 계획을 설명한다.
4. Codex 작업은 `codex/<기능명>`, Claude 작업은 `claude/<기능명>` 브랜치를 사용한다.
5. 한 PR에는 가능한 한 한 기능만 포함한다.
6. Lua 5.1 문법, TOC 경로, Retail API, XML 참조와 로드 순서를 검사한다.
7. 다른 AI가 PR을 교차 검토하도록 한다.
8. 사용자가 게임 안에서 검증한 뒤에만 `main` 병합을 권고한다.

두 AI가 같은 브랜치나 같은 파일을 동시에 수정하지 않게 한다. 한 AI가 구현하면 다른 AI는 PR 검토를 맡는다. 충돌이 있으면 자동으로 한쪽 변경을 선택하지 말고 양쪽 의도를 비교해 보고한다.

답변과 문서는 기본적으로 한국어로 작성한다.

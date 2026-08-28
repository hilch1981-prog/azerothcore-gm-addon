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
5. `MODULE_MANIFEST.json`
6. `MODULE_ARCHITECTURE.md`
7. `REFERENCES.md`
8. `THIRD_PARTY_NOTICES.md`
9. `CONTRIBUTING.md`
10. `COLLABORATION.md`

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

## 최소 토큰·모듈 작업 규칙

1. 사용자 요청을 `MODULE_MANIFEST.json`의 한 모듈로 먼저 분류한다.
2. `python tools/module_context.py <module>`가 출력하는 파일만 우선 읽는다.
3. 데이터 자체를 변경하는 요청이 아니면 `--include-data`를 사용하지 않는다.
4. `KoKRSearchData.lua`, `Teleports.lua`, BlueItemInfo3 및 InvenCraftInfo 대용량 데이터는 기본 컨텍스트에서 제외한다.
5. 한 브랜치와 PR에서는 한 기능 모듈 또는 한 공통 기반만 수정한다.
6. 다른 모듈 수정이 필요하면 공개 인터페이스가 부족한 이유를 먼저 기록한다.
7. 전체 파일 재작성보다 작은 함수·파일 단위 패치를 우선한다.

## 다국어 규칙

- enUS를 기본 fallback 언어로 사용한다.
- koKR, zhCN, zhTW 언어팩을 유지한다.
- 새 사용자 표시 문자열은 로직에 직접 넣지 않고 기능별 locale 파일에 등록한다.
- 모든 언어팩은 동일한 키 집합을 가져야 한다.
- 번역이 없으면 nil이나 빈 문자열 대신 enUS를 표시한다.
- 기존 하드코딩 문자열은 기능 모듈을 이동할 때 해당 모듈 언어팩으로 함께 이전한다.

## 출처 및 라이선스

- 타인의 코드·번역·애드온·데이터·UI 리소스를 사용하면 프로젝트명, 저작자, 원본 주소, 라이선스, 사용 범위, 수정 여부를 PR과 `THIRD_PARTY_NOTICES.md`에 기록한다.
- 원본 저작권 고지와 NOTICE가 필요하면 그대로 보존한다.
- 출처 또는 재배포 조건을 확인할 수 없는 리소스는 새로 포함하지 않는다.

## 작업 절차

1. 현재 `main`과 열린 PR을 확인한다.
2. 대상 모듈의 최소 컨텍스트와 관련 Lua/XML/TOC 로드 순서를 먼저 분석한다.
3. 원인, 수정 대상 파일, 예상 영향, 검증 계획을 설명한다.
4. Codex 작업은 `codex/<기능명>`, Claude 작업은 `claude/<기능명>` 브랜치를 사용한다.
5. 한 PR에는 한 기능 모듈 또는 한 공통 기반만 포함한다.
6. Lua 5.1 문법, TOC 경로, Retail API, XML 참조, 모듈 경계와 locale key를 검사한다.
7. 다른 AI가 PR을 교차 검토하도록 한다.
8. 사용자가 게임 안에서 검증한 뒤에만 `main` 병합을 권고한다.

두 AI가 같은 브랜치나 같은 파일을 동시에 수정하지 않게 한다. 한 AI가 구현하면 다른 AI는 PR 검토를 맡는다. 충돌이 있으면 자동으로 한쪽 변경을 선택하지 말고 양쪽 의도를 비교해 보고한다.

답변과 문서는 기본적으로 한국어로 작성한다.

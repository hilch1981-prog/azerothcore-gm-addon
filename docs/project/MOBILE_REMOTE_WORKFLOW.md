# Mobile Remote Workflow

이 문서는 휴대폰의 ChatGPT Remote에서 PC Codex 세션에 짧은 지시만 내려도 AzerothAdmin 작업을 안전하게 이어갈 수 있도록 하는 운영 규칙이다.

## 목적

모바일에서는 긴 개발 프롬프트를 반복 입력하지 않는다. Codex가 저장소 상태를 먼저 확인하고, 사용자는 `PR #50 계속`, `다음`, `게임 테스트 ZIP 만들어`, `Claude 지적 확인`처럼 짧게 지시한다.

## 시작 시 자동 확인

모바일 Remote 지시를 받으면 Codex는 다음을 먼저 확인한다.

1. 현재 checkout 브랜치
2. HEAD commit SHA
3. `origin/main`과의 ahead/behind 상태
4. 관련 PR의 head/base 및 Draft 상태
5. 관련 Issue의 요구사항과 최신 댓글
6. 현재 release/tag와 테스트 대상 branch의 관계
7. `PROJECT_STATUS.md`, `TASKS.md`, `DEVELOPMENT_RULES.md`, `MODULE_MANIFEST.json`
8. `docs/project/AI_COLLABORATION.md`

릴리즈, main, Draft PR이 서로 다른 코드를 가리키면 어떤 아티팩트를 테스트해야 하는지 먼저 구분한다.

## 모바일 기본 지시어

다음과 같은 짧은 명령은 별도 설명 없이 현재 작업 문맥을 이어간다.

- `계속` 또는 `다음`: 현재 PR/Issue의 다음 안전한 작업을 진행한다.
- `상태 확인`: 브랜치, SHA, PR, Issue, CI, Claude 리뷰, 게임 테스트 상태를 요약한다.
- `Claude 확인`: 최신 Claude review와 unresolved thread를 확인하고 실제 코드와 대조한다.
- `유효한 것만 수정`: Claude 지적 중 재현 가능하거나 코드상 근거가 있는 항목만 수정한다.
- `정적 테스트`: Lua 5.1, TOC, 경로, Retail API, 로드 순서, 기존 회귀 테스트를 실행한다.
- `게임 테스트 준비`: 현재 PR head 기준 검증 ZIP과 최소 PASS/FAIL 체크리스트를 준비한다.
- `ZIP 만들어`: 현재 PR head SHA가 파일명에 포함된 게임 검증 ZIP을 만든다.
- `GitHub 반영`: 현재 변경을 기능 브랜치에 commit/push하고 PR 상태를 갱신한다. merge는 하지 않는다.
- `릴리즈 준비`: release 후보를 만들기 위한 검증까지만 수행한다. tag/release 생성은 별도 승인 전 금지한다.

## 작업 순서

1. 증상 또는 요구사항 재확인
2. 관련 Lua/XML/TOC 및 서버 명령 경로 분석
3. 원인과 영향 범위 판단
4. 최소 수정
5. Lua 5.1 검사
6. TOC 파일 존재/대소문자/로드 순서 검사
7. Retail 전용 API 검색
8. 기능별 정적 테스트
9. 전체 회귀 테스트
10. diff 자체 리뷰
11. Claude Code Review 확인
12. Claude 지적을 실제 코드와 대조
13. 유효한 항목만 후속 수정
14. 게임 테스트 ZIP 생성
15. 게임 내 수동 테스트
16. PASS 후 병합/릴리스 판단

## Claude 활용

Claude의 기본 역할은 읽기 전용 독립 리뷰어다.

Codex 구현 PR에서는 Claude가 파일을 직접 수정하지 않는다. 구현을 별도로 맡길 때만 `claude/<기능명>` 브랜치를 사용한다.

Claude에게 특히 맡길 항목:

- PR diff 독립 코드 리뷰
- WotLK 3.3.5a / Lua 5.1 호환성 감사
- enUS/koKR/zhCN/zhTW/ruRU 언어 누출 감사
- Issue 요구사항 누락 검사
- 릴리즈 후보 회귀 감사
- 게임 테스트 체크리스트의 누락 검사

Codex와 Claude가 같은 기능의 같은 파일을 동시에 수정하지 않는다.

## 게임 테스트 아티팩트 규칙

공개 Release ZIP과 PR 검증 ZIP을 분리한다.

게임 검증 ZIP 이름에는 최소 다음을 포함한다.

- PR 번호
- 짧은 commit SHA
- `GAMETEST` 표시

예:

`AzerothAdmin_PR50_5258eb0_GAMETEST.zip`

게임 테스트 기록에는 다음을 남긴다.

- PR 번호
- commit SHA
- ZIP 파일명
- 표시 언어
- 테스트 항목
- PASS / FAIL
- 테스트 차수 또는 날짜

게임 내 검증이 없으면 `완료`, `배포 가능`, `게임 테스트 PASS`라고 표현하지 않는다.

## GitHub 안전 규칙

Codex는 기능 브랜치와 PR을 사용한다. `main`에 직접 push하지 않는다.

다음 작업은 사용자 명시적 승인 전 실행하지 않는다.

- PR merge
- tag 생성
- GitHub Release 생성/업로드
- Issue 종료
- 기존 release 교체

분석, 정적 테스트, Claude 리뷰 검증, PR용 후속 commit은 작업 문맥상 안전하면 계속 진행한다.

## 모바일 응답 형식

휴대폰에서는 긴 로그 대신 다음 순서로 먼저 요약한다.

- 현재 상태
- 작업 대상
- 발견 문제
- 수정 여부
- 자동 테스트
- Claude 리뷰
- 게임 테스트 필요
- GitHub 반영 상태

치명적인 문제나 잘못된 테스트 아티팩트를 발견하면 가장 먼저 알린다.

## 권장 운영 구조

- 모바일 ChatGPT Remote: 지시, 판단, 승인
- PC Codex: 실제 코드 수정, 테스트, ZIP 생성
- GitHub: Issue, PR, CI, commit, release의 기준 기록
- Claude: 독립 리뷰 및 누락/회귀 감사

기본 흐름은 `Codex 구현 -> Claude 독립 리뷰 -> Codex 재검증/수정 -> 사용자 게임 테스트 -> 병합/릴리스 판단`이다.

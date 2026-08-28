# ChatGPT/Codex + Claude 협업 규칙

이 문서는 AzerothAdmin 저장소에서 ChatGPT/Codex와 Claude가 같은 변경을 중복 수정하지 않도록 역할을 분리한다.

## 역할

### ChatGPT/Codex
- 실제 Lua/XML/TOC 및 프로젝트 문서를 먼저 분석한다.
- `codex/<기능명>` 브랜치에서 구현한다.
- 정적 테스트, 회귀 테스트, TOC/ZIP 검증을 추가·수정한다.
- Pull Request를 만들고 CI 결과와 Claude 리뷰를 확인한다.
- Claude의 유효한 지적을 후속 커밋으로 수정한다.
- `main`에 직접 푸시하지 않는다.

### Claude
- 기본 역할은 독립적인 읽기 전용 코드 리뷰어다.
- 자동 리뷰에서는 저장소 파일을 수정하지 않는다.
- 변경 diff와 실제 저장소 파일을 근거로 문제를 지적한다.
- 구현이 필요해 별도 작업자로 사용할 경우 반드시 `claude/<기능명>` 브랜치를 사용하고 ChatGPT/Codex 브랜치와 같은 파일을 동시에 수정하지 않는다.

## 공통 검토 기준

모든 변경은 다음을 확인한다.

1. WoW WotLK 3.3.5a Build 12340 기준인가.
2. `## Interface: 30300`과 호환되는가.
3. Lua 5.1 문법만 사용하는가.
4. `C_Container`, `C_Item`, `ScrollBox`, 최신 `C_QuestLog` 같은 Retail 전용 API가 없는가.
5. 기존 UI/UX·기능·파일을 근거 없이 삭제하거나 바꾸지 않았는가.
6. 실제 AzerothCore WotLK 명령 구문과 권한 모델을 지키는가.
7. TOC 로드 순서와 파일 경로가 맞는가.
8. koKR 검색/파싱/분류 데이터와 사용자 표시 번역 문자열을 구분하는가.
9. 외부 프로젝트를 참고하거나 코드/데이터를 사용했다면 출처·라이선스·사용 범위를 기록했는가.
10. 게임 내 테스트를 하지 않았다면 `완료`, `게임 테스트 통과`, `배포 가능`이라고 단정하지 않는가.
11. SkyFire/MoP 규칙을 이 WotLK/AzerothCore 프로젝트에 적용하지 않는가.

## PR 협업 순서

1. ChatGPT/Codex가 기능 브랜치에서 구현한다.
2. Addon static checks를 실행한다.
3. Claude Code Review가 같은 PR을 독립적으로 검토한다.
4. Claude inline review가 있으면 ChatGPT/Codex가 실제 코드와 프로젝트 지침을 대조한다.
5. 유효한 문제만 후속 커밋으로 수정하고 CI/Claude 리뷰를 다시 실행한다.
6. 미해결 review thread가 0인지 확인한다.
7. PC가 필요한 기능은 Draft 상태로 두고 `GAME_TEST_MATRIX.md`에 테스트 대기로 기록한다.
8. 실제 게임 검증 후에만 최종 병합/릴리스 판단을 한다.

## 충돌 방지

- 같은 기능을 ChatGPT/Codex와 Claude가 동시에 구현하지 않는다.
- Claude에게 구현을 맡길 때는 `claude/<기능명>`에서만 작업한다.
- ChatGPT/Codex 구현 브랜치에서 Claude는 자동 코드리뷰만 수행한다.
- 두 AI의 변경을 합쳐야 한다면 먼저 PR 단위로 diff를 비교하고, 어느 구현을 기준으로 할지 결정한 뒤 별도 통합 브랜치에서 처리한다.
- `main` 직접 푸시는 금지한다.

## 현재 권장 운용

현재 모듈화/다국어 스택은 ChatGPT/Codex가 구현 책임을 유지하고 Claude는 GitHub Actions의 `Claude Code Review`로 독립 검증한다. 게임 내 검증 전까지 PR은 Draft로 유지한다.

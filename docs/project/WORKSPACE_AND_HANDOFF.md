# 작업공간 및 AI 인수인계

## 단일 기준 원본

- GitHub 저장소가 ChatGPT/Codex와 Claude가 공유하는 공용 원본이다.
- 각 컴퓨터의 로컬 복제본은 작업 공간일 뿐 공용 원본이 아니다.
- 로컬 변경은 브랜치와 Pull Request를 통해서만 다른 AI에게 전달한다.
- ZIP은 배포 또는 보관 산출물이며 개발 기준 원본으로 사용하지 않는다.

공용 원본:

`https://github.com/hilch1981-prog/azerothcore-gm-addon`

## 지시서 연결

| 대상 | 자동으로 읽을 지시서 | 용도 |
| --- | --- | --- |
| ChatGPT/Codex | `AGENTS.md` | Codex 구현 및 검토 규칙 |
| Claude Code | `CLAUDE.md` | Claude 구현 및 검토 규칙 |
| ChatGPT 프로젝트 | `CHATGPT_PROJECT_INSTRUCTIONS.md` | 프로젝트 설정에 복사할 공통 지시사항 |
| 모든 참여자 | `CONTRIBUTING.md`, `COLLABORATION.md` | 브랜치, PR, 충돌 방지 규칙 |

## 세션 시작 확인

1. 올바른 저장소인지 확인한다.
2. 작업 트리가 깨끗한지 확인한다.
3. 원격 `main`의 최신 변경을 가져온다.
4. 열린 Issue와 PR에서 같은 파일을 수정 중인지 확인한다.
5. 담당 AI와 작업 브랜치를 정한다.

## 권장 역할 분담

### Codex 구현, Claude 검토

1. Codex가 `codex/<기능명>` 브랜치에서 분석, 수정, 정적 검사를 수행한다.
2. Codex가 PR에 원인, 변경 내용, 검사 결과, 게임 내 테스트 절차를 기록한다.
3. PR 댓글에서 `@claude`에게 WotLK 3.3.5a와 Lua 5.1 호환성 검토를 요청한다.
4. Codex가 검토 의견을 반영한다.
5. 사용자가 게임 내 테스트 후 병합한다.

### Claude 구현, Codex 검토

1. Claude가 `claude/<기능명>` 브랜치에서 작업하고 PR을 만든다.
2. Codex가 전체 diff와 자동 검사 결과를 검토한다.
3. Claude가 검토 의견을 반영한다.
4. 사용자가 게임 내 테스트 후 병합한다.

## 금지 사항

- 두 AI가 같은 로컬 작업 폴더에서 동시에 파일을 수정하지 않는다.
- `main`에 직접 푸시하지 않는다.
- 다른 AI의 브랜치를 강제 푸시하거나 이력을 재작성하지 않는다.
- 검사 통과만으로 게임 내 검증까지 완료됐다고 표시하지 않는다.
- 비밀값과 개인 로컬 경로를 Issue, PR, 문서 또는 로그에 기록하지 않는다.

동시 구현이 꼭 필요하면 동일 폴더를 공유하지 말고 별도 Git worktree를 만든 뒤 서로 다른 기능과 파일 범위를 배정한다.

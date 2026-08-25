# ChatGPT/Codex + Claude 공동 작업 설정

## 공용 원본과 로컬 작업공간

- 공용 원본은 `https://github.com/hilch1981-prog/azerothcore-gm-addon`이다.
- ChatGPT 프로젝트에 업로드되거나 동기화된 파일은 참고 자료로만 취급한다.
- 실제 개발은 최신 Git 저장소 복제본에서 수행하고, 변경은 브랜치와 PR로 공유한다.
- 로컬 절대 경로는 컴퓨터마다 다르므로 저장소 문서에 기록하지 않는다.
- 자세한 작업공간 연결과 인수인계 절차는 `WORKSPACE_AND_HANDOFF.md`를 따른다.

## 현재 저장소 구성

- Codex 지침: `AGENTS.md`
- Claude 지침: `CLAUDE.md`
- 공동 규칙: `CONTRIBUTING.md`
- PR 템플릿과 Issue 템플릿
- Lua 5.1, TOC 경로, Retail API 자동 정적 검사
- Claude Code GitHub Action 워크플로
- ChatGPT 프로젝트용 지시서: `CHATGPT_PROJECT_INSTRUCTIONS.md`

## Claude GitHub Action 현재 상태

- Claude GitHub App이 이 저장소에 설치되어 있다.
- 워크플로는 GitHub Actions Secret `CLAUDE_CODE_OAUTH_TOKEN`을 사용한다.
- 새 PR에는 Claude 자동 코드 리뷰가 실행된다.
- Issue 또는 PR 댓글에 `@claude`를 포함하면 Claude 작업 워크플로가 실행된다.
- 토큰 값은 저장소 파일, Issue, PR 또는 댓글에 절대 붙여넣지 않는다.

예시:

```text
@claude 이 변경을 WotLK 3.3.5a, Lua 5.1, AzerothCore 호환성 기준으로 검토해 주세요.
Retail API, TOC 경로, 로드 순서, SavedVariables 회귀를 특히 확인해 주세요.
```

워크플로 인증을 다시 구성할 때만 Claude Code의 `/install-github-app` 공식 절차를 사용한다.

## 권장 작업 예

```text
Issue: [Bug] 동부 왕국 퀘스트 보상 목록이 0개
Codex branch: codex/fix-ek-quest-rewards
Claude review: PR에서 원인 분석과 3.3.5a 호환성 교차 검토
User: 게임 내 테스트 후 승인 및 병합
```

두 AI가 같은 로컬 폴더와 같은 브랜치에서 동시에 구현하지 않는다. 한 AI가 구현하고 다른 AI가 PR을 검토하는 순서를 기본으로 한다.

## 브랜치 보호 제한

현재 GitHub 계정 요금제의 비공개 저장소에서는 서버 측 브랜치 보호를 활성화할 수 없다. `CONTRIBUTING.md`의 PR 전용 규칙을 운영 규칙으로 적용하며, 요금제 변경 또는 공개 저장소 전환 후 다음을 활성화한다.

- Pull Request 필수
- 승인 1명 이상
- 오래된 승인 무효화
- 자동 정적 검사 통과 필수
- 강제 푸시 및 브랜치 삭제 금지

# ChatGPT/Codex + Claude 공동 작업 설정

## 현재 저장소 구성

- Codex 지침: `AGENTS.md`
- Claude 지침: `CLAUDE.md`
- 공동 규칙: `CONTRIBUTING.md`
- PR 템플릿과 Issue 템플릿
- Lua 5.1, TOC 경로, Retail API 자동 정적 검사
- Claude Code GitHub Action 워크플로

## Claude GitHub Action 활성화

워크플로는 인증 준비 전 오작동하지 않도록 기본 비활성 상태다.

1. 저장소 관리자 계정으로 Claude Code에서 `/install-github-app`을 실행하거나 Claude GitHub App을 저장소에 설치한다.
2. 저장소 Actions Secret에 `ANTHROPIC_API_KEY`를 추가한다.
3. 저장소 Actions Variable `CLAUDE_GITHUB_ENABLED`를 `true`로 설정한다.
4. Issue 또는 PR 댓글에서 `@claude`와 함께 요청한다.

비밀값을 파일, Issue, PR 또는 댓글에 붙여넣지 않는다.

Claude 구독 OAuth 토큰을 사용하려면 공식 설치 절차로 워크플로를 다시 생성하고 `CLAUDE_CODE_OAUTH_TOKEN` 방식으로 전환한다.

## 권장 작업 예

```text
Issue: [Bug] 동부 왕국 퀘스트 보상 목록이 0개
Codex branch: codex/fix-ek-quest-rewards
Claude review: PR에서 원인 분석과 3.3.5a 호환성 교차 검토
User: 게임 내 테스트 후 승인 및 병합
```

## 브랜치 보호 제한

현재 GitHub 계정 요금제의 비공개 저장소에서는 서버 측 브랜치 보호를 활성화할 수 없다. `CONTRIBUTING.md`의 PR 전용 규칙을 운영 규칙으로 적용하며, 요금제 변경 또는 공개 저장소 전환 후 다음을 활성화한다.

- Pull Request 필수
- 승인 1명 이상
- 오래된 승인 무효화
- 자동 정적 검사 통과 필수
- 강제 푸시 및 브랜치 삭제 금지

# 공동 작업 규칙

## 역할

- 사용자: 요구사항 확정, 게임 내 검증, 최종 병합 승인
- ChatGPT/Codex: 분석, 구현, 정적 검사, Codex 관점 코드 리뷰
- Claude Code: 독립 구현 또는 교차 리뷰, GitHub 이슈/PR 기반 작업

두 AI가 동시에 같은 브랜치나 같은 기능 파일을 수정하지 않는다.

## 브랜치

- Codex: `codex/<기능명>`
- Claude: `claude/<기능명>`
- 사람 직접 작업: `user/<기능명>`

`main`은 검증된 기준선이다. GitHub 요금제에서 강제 보호가 제공되지 않더라도 직접 푸시하지 않는다.

## 작업 순서

1. GitHub Issue에 재현 방법, 대상 환경 및 기대 결과를 기록한다.
2. 담당 AI와 브랜치를 정한다.
3. 한 PR에는 가능한 한 한 기능만 포함한다.
4. 자동 정적 검사를 통과시킨다.
5. 다른 AI 또는 사용자가 diff를 검토한다.
6. 게임 내 검증 결과를 PR 체크리스트에 기록한다.
7. 사용자 승인 후 `main`에 병합한다.

## 충돌 방지

- 작업 시작 전 `main` 최신 상태를 가져온다.
- 동일 파일을 수정하는 열린 PR이 있는지 확인한다.
- 다른 AI의 브랜치를 강제 푸시하거나 재작성하지 않는다.
- 충돌이 발생하면 자동으로 한쪽을 선택하지 말고 변경 의도를 비교한다.

## 커밋

예시:

```text
Fix Eastern Kingdoms quest reward classification
Add Lua 5.1 static validation workflow
Document remote bank server limitation
```

## 검증

- Lua 5.1 구문
- TOC 등록 경로
- Retail 전용 API 부재
- 관련 UI 회귀
- 실제 AzerothCore 명령 동작
- 최종 ZIP 구조와 무결성

API 키, OAuth 토큰 또는 기타 비밀값은 파일에 기록하지 않고 GitHub Actions Secret으로만 관리한다.
